import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../db/settings_repository.dart';
import 'database_provider.dart';

/// Notifier for managing application settings
class SettingsNotifier extends Notifier<AsyncValue<AppSettings?>> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  AsyncValue<AppSettings?> build() {
    _loadSettings();
    return const AsyncValue.loading();
  }

  /// Load settings
  Future<void> _loadSettings() async {
    try {
      final settings = await _repository.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Reload settings
  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    await _loadSettings();
  }

  /// Update settings
  Future<bool> updateSettings(AppSettings settings) async {
    try {
      final success = await _repository.updateSettings(settings);
      if (success) {
        await loadSettings();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Enable or disable GST
  Future<bool> setGstEnabled(bool enabled) async {
    try {
      final success = await _repository.setGstEnabled(enabled);
      if (success) {
        await loadSettings();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Set default GST rate
  Future<bool> setDefaultGstRate(double rate) async {
    try {
      final success = await _repository.setDefaultGstRate(rate);
      if (success) {
        await loadSettings();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Set GSTIN
  Future<bool> setGstin(String? gstin) async {
    try {
      final success = await _repository.setGstin(gstin);
      if (success) {
        await loadSettings();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Update business information
  Future<bool> updateBusinessInfo({
    required String businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
  }) async {
    try {
      final success = await _repository.updateBusinessInfo(
        businessName: businessName,
        businessAddress: businessAddress,
        businessPhone: businessPhone,
        businessEmail: businessEmail,
      );
      if (success) {
        await loadSettings();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for settings state
final settingsProvider =
    NotifierProvider<SettingsNotifier, AsyncValue<AppSettings?>>(
      SettingsNotifier.new,
    );
