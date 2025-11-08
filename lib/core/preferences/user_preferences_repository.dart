import 'package:shared_preferences/shared_preferences.dart';

abstract class UserPreferencesRepository {
  Future<bool> getShareUsageData();

  Future<void> setShareUsageData(bool enabled);
}

class SharedPreferencesUserPreferencesRepository
    implements UserPreferencesRepository {
  SharedPreferencesUserPreferencesRepository(this._preferences);

  static const _shareUsageDataKey = 'share_usage_data';
  final SharedPreferences _preferences;

  static Future<SharedPreferencesUserPreferencesRepository> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesUserPreferencesRepository(preferences);
  }

  @override
  Future<bool> getShareUsageData() async {
    return _preferences.getBool(_shareUsageDataKey) ?? false;
  }

  @override
  Future<void> setShareUsageData(bool enabled) async {
    await _preferences.setBool(_shareUsageDataKey, enabled);
  }
}
