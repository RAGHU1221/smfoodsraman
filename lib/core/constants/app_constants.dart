// ignore_for_file: constant_identifier_names
class AppConstants {
  // API
  static const String BASE_URL = 'https://smfoods.site.je';
  static const String API_URL  = '$BASE_URL/api/mobile';

  // Local DB
  static const String DB_NAME    = 'smfoods_pos.db';
  static const int    DB_VERSION = 1;

  // Tables
  static const String TABLE_BILLS      = 'bills';
  static const String TABLE_BILL_ITEMS = 'bill_items';
  static const String TABLE_ITEMS      = 'items';
  static const String TABLE_SYNC_LOG   = 'sync_log';

  // Prefs keys
  static const String PREF_TOKEN      = 'auth_token';
  static const String PREF_LANG       = 'lang';
  static const String PREF_SHOP_NAME  = 'shop_name';
  static const String PREF_CURRENCY   = 'currency';
  static const String PREF_USER_NAME  = 'user_name';
  static const String PREF_LAST_SYNC  = 'last_sync';

  // Timeouts
  static const Duration CONNECT_TIMEOUT = Duration(seconds: 30);
  static const Duration READ_TIMEOUT    = Duration(seconds: 30);

  // Sync
  static const int SYNC_INTERVAL_MINUTES = 15;
  static const String SYNC_TASK_NAME     = 'smfoods_bill_sync';
}
