import '../models/app_settings.dart';
import 'database_helper.dart';

/// Repository for managing application settings
class SettingsRepository {
  final ERPDatabase _dbHelper;

  SettingsRepository(this._dbHelper);

  /// Get settings (there should only be one row)
  Future<AppSettings?> getSettings() async {
    final db = await _dbHelper.database;
    final maps = await db.query('settings', limit: 1);

    if (maps.isEmpty) {
      return null;
    }

    return AppSettings.fromMap(maps.first);
  }

  /// Update settings
  Future<bool> updateSettings(AppSettings settings) async {
    try {
      final db = await _dbHelper.database;
      final updatedSettings = settings.copyWith(
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Always update row with id = 1 (there's only one settings row)
      final count = await db.update(
        'settings',
        updatedSettings.toMap(),
        where: 'id = ?',
        whereArgs: [settings.id ?? 1],
      );

      return count > 0;
    } catch (e) {
      return false;
    }
  }

  /// Enable or disable GST
  Future<bool> setGstEnabled(bool enabled) async {
    try {
      final settings = await getSettings();
      if (settings == null) return false;

      final updated = settings.copyWith(
        gstEnabled: enabled,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      return await updateSettings(updated);
    } catch (e) {
      return false;
    }
  }

  /// Set default GST rate
  Future<bool> setDefaultGstRate(double rate) async {
    try {
      final settings = await getSettings();
      if (settings == null) return false;

      final updated = settings.copyWith(
        defaultGstRate: rate,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      return await updateSettings(updated);
    } catch (e) {
      return false;
    }
  }

  /// Set GSTIN
  Future<bool> setGstin(String? gstin) async {
    try {
      final settings = await getSettings();
      if (settings == null) return false;

      final updated = settings.copyWith(
        gstin: gstin,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      return await updateSettings(updated);
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
      final settings = await getSettings();
      if (settings == null) return false;

      final updated = settings.copyWith(
        businessName: businessName,
        businessAddress: businessAddress,
        businessPhone: businessPhone,
        businessEmail: businessEmail,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      return await updateSettings(updated);
    } catch (e) {
      return false;
    }
  }
}
