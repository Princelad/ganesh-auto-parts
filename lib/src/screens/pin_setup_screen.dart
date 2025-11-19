import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

/// Screen for setting up a new PIN
class PinSetupScreen extends ConsumerStatefulWidget {
  final bool isChangingPin;

  const PinSetupScreen({super.key, this.isChangingPin = false});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureOldPin = true;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _setupPin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      bool success;

      if (widget.isChangingPin) {
        success = await authService.changePin(
          _oldPinController.text,
          _newPinController.text,
        );

        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Old PIN is incorrect'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      } else {
        success = await authService.setPin(_newPinController.text);
      }

      if (success && mounted) {
        ref.invalidate(isPinSetProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isChangingPin
                  ? 'PIN changed successfully'
                  : 'PIN set successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isChangingPin ? 'Change PIN' : 'Set PIN'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.isChangingPin) ...[
              const Text(
                'Old PIN',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _oldPinController,
                decoration: InputDecoration(
                  hintText: 'Enter your current PIN',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureOldPin ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscureOldPin = !_obscureOldPin);
                    },
                  ),
                ),
                obscureText: _obscureOldPin,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your old PIN';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              'New PIN',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _newPinController,
              decoration: InputDecoration(
                hintText: 'Enter 4-6 digit PIN',
                helperText: 'PIN must be 4-6 digits',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPin ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureNewPin = !_obscureNewPin);
                  },
                ),
              ),
              obscureText: _obscureNewPin,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (value) {
                final authService = ref.read(authServiceProvider);
                return authService.getPinValidationError(value ?? '');
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Confirm PIN',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPinController,
              decoration: InputDecoration(
                hintText: 'Re-enter your PIN',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_clock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPin
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmPin = !_obscureConfirmPin);
                  },
                ),
              ),
              obscureText: _obscureConfirmPin,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (value) {
                if (value != _newPinController.text) {
                  return 'PINs do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _setupPin,
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
                label: Text(
                  widget.isChangingPin ? 'Change PIN' : 'Set PIN',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                          'Security Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip('Choose a PIN that\'s easy to remember'),
                    _buildTip('Don\'t use sequential numbers (1234)'),
                    _buildTip('Don\'t share your PIN with anyone'),
                    _buildTip('Change your PIN regularly'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.blue.shade900)),
          ),
        ],
      ),
    );
  }
}
