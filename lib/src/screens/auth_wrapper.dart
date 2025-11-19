import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'pin_verify_screen.dart';
import 'home_page.dart';

/// Wrapper that checks if PIN is set and verified before showing home
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    final isPinSetAsync = ref.watch(isPinSetProvider);

    return isPinSetAsync.when(
      data: (isPinSet) {
        // If no PIN is set, go directly to home
        if (!isPinSet) {
          return const HomePage();
        }

        // If PIN is set but not authenticated, show verify screen
        if (!_isAuthenticated) {
          return PopScope(
            canPop: false, // Prevent back button
            child: PinVerifyScreen(
              onVerified: () {
                setState(() {
                  _isAuthenticated = true;
                });
              },
            ),
          );
        }

        // Authenticated, show home
        return const HomePage();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}
