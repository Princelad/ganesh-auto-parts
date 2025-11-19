import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../db/database_helper.dart';

/// Service for full database backup and restore
///
/// Provides functionality to:
/// - Export entire database to JSON
/// - Import/restore database from JSON
/// - Share backup files
class BackupService {
  final ERPDatabase _db;

  BackupService(this._db);

  /// Create a full backup of the database
  ///
  /// Returns a map containing all tables data
  Future<Map<String, dynamic>> createBackup() async {
    final database = await _db.database;

    // Fetch all data from all tables
    final items = await database.query('items');
    final customers = await database.query('customers');
    final invoices = await database.query('invoices');
    final invoiceItems = await database.query('invoice_items');
    final changeLogs = await database.query('change_logs');

    return {
      'backup_version': '1.0',
      'backup_date': DateTime.now().toIso8601String(),
      'app_name': 'Ganesh Auto Parts',
      'data': {
        'items': items,
        'customers': customers,
        'invoices': invoices,
        'invoice_items': invoiceItems,
        'change_logs': changeLogs,
      },
      'counts': {
        'items': items.length,
        'customers': customers.length,
        'invoices': invoices.length,
        'invoice_items': invoiceItems.length,
        'change_logs': changeLogs.length,
      },
    };
  }

  /// Export backup to JSON file
  ///
  /// Returns the file path of the created backup
  Future<String> exportBackupToFile() async {
    final backup = await createBackup();
    final jsonString = jsonEncode(backup);

    // Get app documents directory
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'gap_backup_$timestamp.json';
    final filePath = '${directory.path}/$fileName';

    // Write to file
    final file = File(filePath);
    await file.writeAsString(jsonString);

    return filePath;
  }

  /// Share backup file
  ///
  /// Exports backup and opens share dialog
  Future<void> shareBackup() async {
    final filePath = await exportBackupToFile();
    final file = File(filePath);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Ganesh Auto Parts Backup',
        text: 'Database backup created on ${DateTime.now()}',
      ),
    );
  }

  /// Import backup from file picker
  ///
  /// Returns true if successful, false otherwise
  Future<bool> importBackupFromPicker() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        return false;
      }

      return await restoreBackupFromFile(filePath);
    } catch (e) {
      return false;
    }
  }

  /// Restore backup from file path
  ///
  /// Validates backup and restores all data
  Future<bool> restoreBackupFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final jsonString = await file.readAsString();
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup structure
      if (!_isValidBackup(backup)) {
        return false;
      }

      await _restoreBackup(backup);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate backup structure
  bool _isValidBackup(Map<String, dynamic> backup) {
    if (!backup.containsKey('data') || !backup.containsKey('backup_version')) {
      return false;
    }

    final data = backup['data'] as Map<String, dynamic>;
    final requiredTables = ['items', 'customers', 'invoices', 'invoice_items'];

    for (final table in requiredTables) {
      if (!data.containsKey(table)) {
        return false;
      }
    }

    return true;
  }

  /// Restore backup to database
  ///
  /// Clears existing data and restores from backup
  Future<void> _restoreBackup(Map<String, dynamic> backup) async {
    final database = await _db.database;
    final data = backup['data'] as Map<String, dynamic>;

    await database.transaction((txn) async {
      // Clear all tables
      await txn.delete('invoice_items');
      await txn.delete('invoices');
      await txn.delete('items');
      await txn.delete('customers');
      await txn.delete('change_logs');

      // Restore items
      final items = data['items'] as List;
      for (final item in items) {
        await txn.insert('items', item as Map<String, dynamic>);
      }

      // Restore customers
      final customers = data['customers'] as List;
      for (final customer in customers) {
        await txn.insert('customers', customer as Map<String, dynamic>);
      }

      // Restore invoices
      final invoices = data['invoices'] as List;
      for (final invoice in invoices) {
        await txn.insert('invoices', invoice as Map<String, dynamic>);
      }

      // Restore invoice items
      final invoiceItems = data['invoice_items'] as List;
      for (final invoiceItem in invoiceItems) {
        await txn.insert('invoice_items', invoiceItem as Map<String, dynamic>);
      }

      // Restore change logs (optional)
      if (data.containsKey('change_logs')) {
        final changeLogs = data['change_logs'] as List;
        for (final changeLog in changeLogs) {
          await txn.insert('change_logs', changeLog as Map<String, dynamic>);
        }
      }
    });
  }

  /// Get backup info without full restore
  ///
  /// Useful for showing backup details before restore
  Future<Map<String, dynamic>?> getBackupInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!_isValidBackup(backup)) {
        return null;
      }

      return {
        'backup_date': backup['backup_date'],
        'backup_version': backup['backup_version'],
        'counts': backup['counts'],
      };
    } catch (e) {
      return null;
    }
  }

  /// Delete old backup files (keep only last N backups)
  Future<void> cleanupOldBackups({int keepCount = 5}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);

      // Get all backup files
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('gap_backup_'))
          .toList();

      // Sort by modification time (newest first)
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      // Delete old backups
      if (files.length > keepCount) {
        for (var i = keepCount; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      // Ignore errors in cleanup
    }
  }

  /// List available backup files
  Future<List<Map<String, dynamic>>> listBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);

      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('gap_backup_'))
          .toList();

      // Sort by modification time (newest first)
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      final backupList = <Map<String, dynamic>>[];

      for (final file in files) {
        final info = await getBackupInfo(file.path);
        if (info != null) {
          backupList.add({
            'path': file.path,
            'name': file.path.split('/').last,
            'size': await file.length(),
            'modified': file.lastModifiedSync(),
            ...info,
          });
        }
      }

      return backupList;
    } catch (e) {
      return [];
    }
  }
}
