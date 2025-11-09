import 'package:shared_preferences/shared_preferences.dart';

import 'units_preference.dart';

abstract class UserPreferencesRepository {
  Future<bool> getShareUsageData();

  Future<void> setShareUsageData(bool enabled);

  Future<UnitsPreference> getUnitsPreference();

  Future<void> setUnitsPreference(UnitsPreference preference);
}

class SharedPreferencesUserPreferencesRepository
    implements UserPreferencesRepository {
  SharedPreferencesUserPreferencesRepository(this._preferences);

  static const _shareUsageDataKey = 'share_usage_data';
  static const _unitsPreferenceKey = 'units_preference';
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
}
