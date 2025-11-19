import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/backup_provider.dart';
import '../providers/item_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/invoice_provider.dart';

/// Screen for database backup and restore operations
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _backupFiles = [];

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    setState(() => _isLoading = true);
    try {
      final backupService = ref.read(backupServiceProvider);
      final files = await backupService.listBackupFiles();
      setState(() {
        _backupFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);

    try {
      final backupService = ref.read(backupServiceProvider);
      await backupService.exportBackupToFile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        await _loadBackupFiles();
        await backupService.cleanupOldBackups(keepCount: 5);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _shareBackup() async {
    setState(() => _isLoading = true);

    try {
      final backupService = ref.read(backupServiceProvider);
      await backupService.shareBackup();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup shared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
          'This will replace all current data with data from the backup file. '
          'This action cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final backupService = ref.read(backupServiceProvider);
      final success = await backupService.importBackupFromPicker();

      if (success && mounted) {
        // Invalidate all providers to refresh data
        ref.invalidate(itemProvider);
        ref.invalidate(itemCountProvider);
        ref.invalidate(customerProvider);
        ref.invalidate(customerCountProvider);
        ref.invalidate(invoiceProvider);
        ref.invalidate(invoiceCountProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully'),
            backgroundColor: Colors.green,
          ),
        );

        await _loadBackupFiles();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to restore backup'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restoreFromFile(String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore This Backup?'),
        content: const Text(
          'This will replace all current data with data from this backup. '
          'This action cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final backupService = ref.read(backupServiceProvider);
      final success = await backupService.restoreBackupFromFile(filePath);

      if (success && mounted) {
        // Invalidate all providers to refresh data
        ref.invalidate(itemProvider);
        ref.invalidate(itemCountProvider);
        ref.invalidate(customerProvider);
        ref.invalidate(customerCountProvider);
        ref.invalidate(invoiceProvider);
        ref.invalidate(invoiceCountProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to restore backup'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBackupFiles,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Action Cards
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.backup, color: Colors.white),
                          ),
                          title: const Text('Create Backup'),
                          subtitle: const Text('Save current database to file'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _createBackup,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.share, color: Colors.white),
                          ),
                          title: const Text('Create & Share'),
                          subtitle: const Text(
                            'Backup and share via other apps',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _shareBackup,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.restore, color: Colors.white),
                          ),
                          title: const Text('Restore from File'),
                          subtitle: const Text(
                            'Import backup from device storage',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _restoreBackup,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Backups
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Backups',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_backupFiles.isNotEmpty)
                        TextButton.icon(
                          onPressed: _loadBackupFiles,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Refresh'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_backupFiles.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No backups found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first backup to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._backupFiles.map((backup) {
                      final date = DateTime.parse(backup['backup_date']);
                      final modified = backup['modified'] as DateTime;
                      final counts = backup['counts'] as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.inventory),
                          ),
                          title: Text(
                            DateFormat('MMM dd, yyyy • HH:mm').format(date),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Items: ${counts['items']} • '
                                'Customers: ${counts['customers']} • '
                                'Invoices: ${counts['invoices']}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatFileSize(backup['size'])} • '
                                'Modified: ${DateFormat('MMM dd, HH:mm').format(modified)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.restore),
                            onPressed: () => _restoreFromFile(backup['path']),
                            tooltip: 'Restore this backup',
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // Info Card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'About Backups',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoItem(
                            '• Backups include all items, customers, invoices, and change logs',
                          ),
                          _buildInfoItem(
                            '• Only the 5 most recent backups are kept automatically',
                          ),
                          _buildInfoItem(
                            '• Share backups to save them externally',
                          ),
                          _buildInfoItem(
                            '• Restoring will replace all current data',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
      ),
    );
  }
}
