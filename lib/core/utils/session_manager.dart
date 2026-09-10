import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class SessionManager {
  static SessionManager? _instance;
  SessionManager._();
  static SessionManager get instance => _instance ??= SessionManager._();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String> get token async =>
      (await _prefs).getString(AppConstants.PREF_TOKEN) ?? '';

  Future<void> setToken(String t) async =>
      (await _prefs).setString(AppConstants.PREF_TOKEN, t);

  Future<String> get lang async =>
      (await _prefs).getString(AppConstants.PREF_LANG) ?? 'en';

  Future<void> setLang(String l) async =>
      (await _prefs).setString(AppConstants.PREF_LANG, l);

  Future<bool> get isTamil async => (await lang) == 'ta';

  Future<String> get shopName async =>
      (await _prefs).getString(AppConstants.PREF_SHOP_NAME) ?? 'Sri Murugan Foods';

  Future<void> setShopName(String n) async =>
      (await _prefs).setString(AppConstants.PREF_SHOP_NAME, n);

  Future<String> get currency async =>
      (await _prefs).getString(AppConstants.PREF_CURRENCY) ?? '₹';

  Future<void> setCurrency(String c) async =>
      (await _prefs).setString(AppConstants.PREF_CURRENCY, c);

  Future<String> get userName async =>
      (await _prefs).getString(AppConstants.PREF_USER_NAME) ?? 'Admin';

  Future<void> setUserName(String n) async =>
      (await _prefs).setString(AppConstants.PREF_USER_NAME, n);

  Future<bool> isLoggedIn() async => (await token).isNotEmpty;

  Future<void> logout() async {
    final p = await _prefs;
    await p.remove(AppConstants.PREF_TOKEN);
    await p.remove(AppConstants.PREF_USER_NAME);
  }

  Future<void> saveFromLoginJson(Map<String, dynamic> json) async {
    final t = json['token'] as String? ?? '';
    if (t.isNotEmpty) await setToken(t);

    final user = json['user'] as Map<String, dynamic>?;
    if (user != null) {
      final name = user['name'] as String? ?? '';
      if (name.isNotEmpty) await setUserName(name);
    }

    final settings = json['settings'] as Map<String, dynamic>?;
    if (settings != null) {
      final sn = settings['shop_name'] as String? ?? '';
      if (sn.isNotEmpty) await setShopName(sn);
      final cur = settings['currency'] as String? ?? '';
      if (cur.isNotEmpty) await setCurrency(cur);
    }
  }
}
