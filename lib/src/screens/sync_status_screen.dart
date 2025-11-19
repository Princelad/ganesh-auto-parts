import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/sync_provider.dart';

/// Screen showing sync status and manual sync controls
class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  bool _isSyncing = false;

  Future<void> _performSync() async {
    setState(() => _isSyncing = true);

    try {
      final syncService = ref.read(syncServiceProvider);
      final result = await syncService.fullSync();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );

        if (result.success) {
          ref.invalidate(syncStatusProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncStatusAsync = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(syncStatusProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: syncStatusAsync.when(
        data: (status) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(syncStatusProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Sync Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        status.isUpToDate
                            ? Icons.cloud_done
                            : Icons.cloud_upload,
                        size: 64,
                        color: status.isUpToDate ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        status.isUpToDate
                            ? 'All Synced'
                            : '${status.pendingChanges} Changes Pending',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        status.lastSyncDateTime != null
                            ? 'Last sync: ${DateFormat('MMM dd, yyyy HH:mm').format(status.lastSyncDateTime!)}'
                            : 'Never synced',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sync Actions
              const Text(
                'Sync Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.sync, color: Colors.white),
                      ),
                      title: const Text('Full Sync'),
                      subtitle: const Text(
                        'Push local changes and pull remote',
                      ),
                      trailing: _isSyncing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _isSyncing ? null : _performSync,
                    ),
                  ],
                ),
              ),
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
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'About Cloud Sync',
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
                        icon: Icons.pending_actions,
                        title: 'Placeholder Feature',
                        description:
                            'This is a foundation for future cloud sync. Server integration is pending.',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem(
                        icon: Icons.track_changes,
                        title: 'Change Tracking',
                        description:
                            'All data changes are logged locally and ready for sync.',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem(
                        icon: Icons.cloud_queue,
                        title: 'Future Features',
                        description:
                            'Multi-device sync, conflict resolution, and real-time updates coming soon.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Statistics
              if (status.pendingChanges > 0) ...[
                const Text(
                  'Pending Changes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: Text(
                        '${status.pendingChanges}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: const Text('Unsynced Operations'),
                    subtitle: const Text(
                      'These changes will be synced when server is available',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error loading sync status',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
