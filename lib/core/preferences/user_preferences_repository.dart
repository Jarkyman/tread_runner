import 'package:shared_preferences/shared_preferences.dart';

import 'units_preference.dart';

abstract class UserPreferencesRepository {
  Future<bool> getShareUsageData();

  Future<void> setShareUsageData(bool enabled);

  Future<UnitsPreference> getUnitsPreference();

  Future<void> setUnitsPreference(UnitsPreference preference);

  Future<bool> getHasRequestedHealthPermissions();

  Future<void> setHasRequestedHealthPermissions(bool value);

  Future<bool> getHealthPermissionsGranted();

  Future<void> setHealthPermissionsGranted(bool granted);
}

class SharedPreferencesUserPreferencesRepository
    implements UserPreferencesRepository {
  SharedPreferencesUserPreferencesRepository(this._preferences);

  static const _shareUsageDataKey = 'share_usage_data';
  static const _unitsPreferenceKey = 'units_preference';
  static const _healthPermissionsRequestedKey =
      'health_permissions_requested';
  static const _healthPermissionsGrantedKey =
      'health_permissions_granted';
  final SharedPreferences _preferences;

  static Future<SharedPreferencesUserPreferencesRepository> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesUserPreferencesRepository(preferences);
  }

  @override
  Future<bool> getShareUsageData() async {
    return _preferences.getBool(_shareUsageDataKey) ?? true;
  }

  @override
  Future<void> setShareUsageData(bool enabled) async {
    await _preferences.setBool(_shareUsageDataKey, enabled);
  }

  @override
  Future<UnitsPreference> getUnitsPreference() async {
    final storedValue = _preferences.getString(_unitsPreferenceKey);
    return UnitsPreference.fromStorage(storedValue);
  }

  @override
  Future<void> setUnitsPreference(UnitsPreference preference) async {
    await _preferences.setString(_unitsPreferenceKey, preference.name);
  }

  @override
  Future<bool> getHasRequestedHealthPermissions() async {
    return _preferences.getBool(_healthPermissionsRequestedKey) ?? false;
  }

  @override
  Future<void> setHasRequestedHealthPermissions(bool value) async {
    await _preferences.setBool(_healthPermissionsRequestedKey, value);
  }

  @override
  Future<bool> getHealthPermissionsGranted() async {
    return _preferences.getBool(_healthPermissionsGrantedKey) ?? false;
  }

  @override
  Future<void> setHealthPermissionsGranted(bool granted) async {
    await _preferences.setBool(_healthPermissionsGrantedKey, granted);
  }
}
