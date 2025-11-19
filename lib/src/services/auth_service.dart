import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for handling PIN-based authentication
///
/// Provides secure PIN storage, verification, and management.
/// PINs are hashed using SHA256 before storage.
class AuthService {
  static const String _pinKey = 'user_pin_hash';
  static const String _pinSetKey = 'pin_is_set';

  final FlutterSecureStorage _storage;

  AuthService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Hash a PIN using SHA256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if a PIN has been set
  Future<bool> isPinSet() async {
    final isSet = await _storage.read(key: _pinSetKey);
    return isSet == 'true';
  }

  /// Set a new PIN
  ///
  /// Returns true if successful, false otherwise.
  /// PIN must be 4-6 digits.
  Future<bool> setPin(String pin) async {
    if (!_isValidPin(pin)) {
      return false;
    }

    try {
      final hashedPin = _hashPin(pin);
      await _storage.write(key: _pinKey, value: hashedPin);
      await _storage.write(key: _pinSetKey, value: 'true');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verify a PIN
  ///
  /// Returns true if the PIN matches the stored PIN.
  Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _storage.read(key: _pinKey);
      if (storedHash == null) {
        return false;
      }

      final inputHash = _hashPin(pin);
      return storedHash == inputHash;
    } catch (e) {
      return false;
    }
  }

  /// Change the PIN
  ///
  /// Requires the old PIN for verification.
  /// Returns true if successful.
  Future<bool> changePin(String oldPin, String newPin) async {
    final isOldPinValid = await verifyPin(oldPin);
    if (!isOldPinValid) {
      return false;
    }

    return await setPin(newPin);
  }

  /// Reset/Remove the PIN
  ///
  /// Use with caution - this will remove authentication.
  Future<void> resetPin() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _pinSetKey);
  }

  /// Validate PIN format
  ///
  /// PIN must be 4-6 digits only.
  bool _isValidPin(String pin) {
    if (pin.length < 4 || pin.length > 6) {
      return false;
    }

    // Check if all characters are digits
    return RegExp(r'^\d+$').hasMatch(pin);
  }

  /// Get PIN validation error message
  String? getPinValidationError(String pin) {
    if (pin.isEmpty) {
      return 'PIN cannot be empty';
    }
    if (pin.length < 4) {
      return 'PIN must be at least 4 digits';
    }
    if (pin.length > 6) {
      return 'PIN must be at most 6 digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      return 'PIN must contain only digits';
    }
    return null;
  }
}
