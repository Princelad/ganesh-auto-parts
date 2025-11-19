import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';

/// Screen for PIN verification/login
class PinVerifyScreen extends ConsumerStatefulWidget {
  final VoidCallback? onVerified;

  const PinVerifyScreen({super.key, this.onVerified});

  @override
  ConsumerState<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends ConsumerState<PinVerifyScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;
  int _failedAttempts = 0;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your PIN'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final isValid = await authService.verifyPin(_pinController.text);

      if (isValid && mounted) {
        // Call the callback if provided (for auth wrapper)
        if (widget.onVerified != null) {
          widget.onVerified!();
        } else {
          // Otherwise pop with result (for settings/dialogs)
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _failedAttempts++;
          _pinController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Incorrect PIN (${_failedAttempts} failed attempt${_failedAttempts > 1 ? 's' : ''})',
              ),
              backgroundColor: Colors.red,
              action: _failedAttempts >= 3
                  ? SnackBarAction(
                      label: 'Reset?',
                      textColor: Colors.white,
                      onPressed: _showResetDialog,
                    )
                  : null,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset PIN?'),
        content: const Text(
          'Warning: Resetting your PIN will remove all authentication. '
          'This should only be used as a last resort.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              await authService.resetPin();
              ref.invalidate(isPinSetProvider);

              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Close verify screen

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN has been reset'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter PIN'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              SvgPicture.asset(
                'assets/images/gap_logo.svg',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 16),
              const Text(
                'Ganesh Auto Parts',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter your PIN to continue',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // PIN Input
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  controller: _pinController,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    letterSpacing: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePin ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePin = !_obscurePin);
                      },
                    ),
                  ),
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onSubmitted: (_) => _verifyPin(),
                ),
              ),
              const SizedBox(height: 24),

              // Verify Button
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _verifyPin,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Verify', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),

              // Failed attempts warning
              if (_failedAttempts >= 3) ...[
                const SizedBox(height: 24),
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Multiple failed attempts detected. '
                            'Tap the "Reset?" button in the error message to reset your PIN.',
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
