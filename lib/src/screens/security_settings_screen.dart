import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'pin_setup_screen.dart';
import 'pin_verify_screen.dart';

/// Screen for security settings and PIN management
class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPinSetAsync = ref.watch(isPinSetProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Security Settings')),
      body: isPinSetAsync.when(
        data: (isPinSet) => ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'PIN Protection',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPinSet
                          ? Colors.green.shade100
                          : Colors.grey.shade200,
                      child: Icon(
                        isPinSet ? Icons.check_circle : Icons.lock_outline,
                        color: isPinSet ? Colors.green : Colors.grey,
                      ),
                    ),
                    title: Text(isPinSet ? 'PIN Enabled' : 'PIN Disabled'),
                    subtitle: Text(
                      isPinSet
                          ? 'Your app is protected with a PIN'
                          : 'Set a PIN to secure your data',
                    ),
                    trailing: Switch(
                      value: isPinSet,
                      onChanged: (value) async {
                        if (value) {
                          // Enable PIN - go to setup screen
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PinSetupScreen(),
                            ),
                          );
                          if (result == true) {
                            ref.invalidate(isPinSetProvider);
                          }
                        } else {
                          // Disable PIN - verify first
                          final verified = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PinVerifyScreen(),
                            ),
                          );

                          if (verified == true && context.mounted) {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Disable PIN?'),
                                content: const Text(
                                  'Are you sure you want to disable PIN protection? '
                                  'This will remove security from your app.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Disable'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final authService = ref.read(authServiceProvider);
                              await authService.resetPin();
                              ref.invalidate(isPinSetProvider);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('PIN protection disabled'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      },
                    ),
                  ),
                  if (isPinSet) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Change PIN'),
                      subtitle: const Text('Update your security PIN'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PinSetupScreen(isChangingPin: true),
                          ),
                        );
                        if (result == true) {
                          ref.invalidate(isPinSetProvider);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.verified_user),
                      title: const Text('Test PIN'),
                      subtitle: const Text('Verify your current PIN'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PinVerifyScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'About PIN Security',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem(
                      icon: Icons.lock,
                      title: 'Secure Storage',
                      description:
                          'Your PIN is encrypted and stored securely on your device.',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      icon: Icons.phone_android,
                      title: 'Device Only',
                      description:
                          'PIN is stored locally and never leaves your device.',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      icon: Icons.password,
                      title: '4-6 Digits',
                      description:
                          'Choose a PIN between 4 and 6 digits for security.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
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
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.blue.shade800, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
