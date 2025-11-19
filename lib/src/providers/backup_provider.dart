import 'package:riverpod/riverpod.dart';
import '../db/database_helper.dart';
import '../services/backup_service.dart';

/// Provider for BackupService
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ERPDatabase());
});
