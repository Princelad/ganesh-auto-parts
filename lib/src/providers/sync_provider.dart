import 'package:riverpod/riverpod.dart';
import '../db/database_helper.dart';
import '../services/sync_service.dart';

/// Provider for SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ERPDatabase());
});

/// Provider for sync status
final syncStatusProvider = FutureProvider<SyncStatus>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  return await syncService.getSyncStatus();
});
