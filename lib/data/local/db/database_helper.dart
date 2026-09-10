import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/bill.dart';
import '../../../core/constants/app_constants.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _db;

  DatabaseHelper._();
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  Future<Database> get db async => _db ??= await _initDb();

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, AppConstants.DB_NAME);

    return openDatabase(
      path,
      version: AppConstants.DB_VERSION,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Bills table
    await db.execute('''
      CREATE TABLE ${AppConstants.TABLE_BILLS} (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        offline_id      TEXT    NOT NULL UNIQUE,
        server_bill_no  TEXT    DEFAULT '',
        bill_type       TEXT    DEFAULT 'retail',
        customer_name   TEXT    DEFAULT '',
        customer_mobile TEXT    DEFAULT '',
        gst_mode        TEXT    DEFAULT 'no_gst',
        payment_method  TEXT    DEFAULT 'cash',
        subtotal        REAL    DEFAULT 0,
        gst_amount      REAL    DEFAULT 0,
        discount        REAL    DEFAULT 0,
        total           REAL    NOT NULL,
        received_amount REAL    DEFAULT 0,
        balance_amount  REAL    DEFAULT 0,
        payment_status  TEXT    DEFAULT 'paid',
        lang            TEXT    DEFAULT 'en',
        created_at      INTEGER NOT NULL,
        synced          INTEGER DEFAULT 0,
        sync_attempts   INTEGER DEFAULT 0
      )
    ''');

    // Bill items table
    await db.execute('''
      CREATE TABLE ${AppConstants.TABLE_BILL_ITEMS} (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_id      INTEGER NOT NULL REFERENCES ${AppConstants.TABLE_BILLS}(id) ON DELETE CASCADE,
        item_id      INTEGER DEFAULT 0,
        item_name    TEXT    NOT NULL,
        item_name_ta TEXT    DEFAULT '',
        item_code    TEXT    DEFAULT '',
        price        REAL    DEFAULT 0,
        sale_price   REAL    DEFAULT 0,
        gst_percent  REAL    DEFAULT 0,
        gst_amount   REAL    DEFAULT 0,
        quantity     INTEGER DEFAULT 1,
        total        REAL    DEFAULT 0
      )
    ''');

    // Items cache table
    await db.execute('''
      CREATE TABLE ${AppConstants.TABLE_ITEMS} (
        id           INTEGER PRIMARY KEY,
        type_id      INTEGER DEFAULT 0,
        type_name    TEXT    DEFAULT '',
        type_name_ta TEXT    DEFAULT '',
        name_en      TEXT    NOT NULL,
        name_ta      TEXT    DEFAULT '',
        item_code    TEXT    DEFAULT '',
        price        REAL    DEFAULT 0,
        sale_price   REAL    DEFAULT 0,
        gst_percent  REAL    DEFAULT 0,
        stock        REAL    DEFAULT 0,
        unit         TEXT    DEFAULT 'nos',
        is_active    INTEGER DEFAULT 1
      )
    ''');

    // Sync log
    await db.execute('''
      CREATE TABLE ${AppConstants.TABLE_SYNC_LOG} (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        action     TEXT NOT NULL,
        message    TEXT DEFAULT '',
        created_at INTEGER NOT NULL
      )
    ''');

    // Indexes for performance
    await db.execute('CREATE INDEX idx_bills_synced ON ${AppConstants.TABLE_BILLS}(synced)');
    await db.execute('CREATE INDEX idx_bills_created ON ${AppConstants.TABLE_BILLS}(created_at DESC)');
    await db.execute('CREATE INDEX idx_items_active ON ${AppConstants.TABLE_ITEMS}(is_active)');
    await db.execute('CREATE INDEX idx_items_type ON ${AppConstants.TABLE_ITEMS}(type_id)');
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    // Migration logic here
  }

  // ── Bills ───────────────────────────────────────────────────────
  Future<int> insertBill(Bill bill) async {
    final d = await db;
    return d.insert(AppConstants.TABLE_BILLS, bill.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertBillItems(List<BillItem> items) async {
    final d = await db;
    final batch = d.batch();
    for (final item in items) {
      batch.insert(AppConstants.TABLE_BILL_ITEMS, item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Bill>> getAllBills() async {
    final d    = await db;
    final rows = await d.query(AppConstants.TABLE_BILLS,
        orderBy: 'created_at DESC');
    return rows.map(Bill.fromMap).toList();
  }

  Future<List<Bill>> getPendingBills() async {
    final d    = await db;
    final rows = await d.query(AppConstants.TABLE_BILLS,
        where: 'synced = 0',
        orderBy: 'created_at ASC');
    return rows.map(Bill.fromMap).toList();
  }

  Future<int> getPendingCount() async {
    final d   = await db;
    final res = await d.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${AppConstants.TABLE_BILLS} WHERE synced = 0');
    return (res.first['cnt'] as int?) ?? 0;
  }

  Future<void> markBillSynced(int id, String serverBillNo) async {
    final d = await db;
    await d.update(
      AppConstants.TABLE_BILLS,
      {'synced': 1, 'server_bill_no': serverBillNo},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementSyncAttempt(int id) async {
    final d = await db;
    await d.rawUpdate(
        'UPDATE ${AppConstants.TABLE_BILLS} SET sync_attempts = sync_attempts + 1 WHERE id = ?',
        [id]);
  }

  Future<List<BillItem>> getBillItems(int billId) async {
    final d    = await db;
    final rows = await d.query(AppConstants.TABLE_BILL_ITEMS,
        where: 'bill_id = ?', whereArgs: [billId]);
    return rows.map(BillItem.fromMap).toList();
  }

  Future<void> deleteBill(int id) async {
    final d = await db;
    await d.delete(AppConstants.TABLE_BILLS, where: 'id = ?', whereArgs: [id]);
  }

  // ── Items ────────────────────────────────────────────────────────
  Future<void> upsertItems(List<Item> items) async {
    final d     = await db;
    final batch = d.batch();
    for (final item in items) {
      batch.insert(AppConstants.TABLE_ITEMS, item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Item>> getAllItems() async {
    final d    = await db;
    final rows = await d.query(AppConstants.TABLE_ITEMS,
        where: 'is_active = 1',
        orderBy: 'type_id ASC, name_en ASC');
    return rows.map(Item.fromMap).toList();
  }

  Future<List<Item>> searchItems(String query) async {
    final d    = await db;
    final q    = '%$query%';
    final rows = await d.query(AppConstants.TABLE_ITEMS,
        where: 'is_active = 1 AND (name_en LIKE ? OR name_ta LIKE ? OR item_code LIKE ?)',
        whereArgs: [q, q, q],
        orderBy: 'name_en ASC');
    return rows.map(Item.fromMap).toList();
  }

  Future<int> getItemCount() async {
    final d   = await db;
    final res = await d.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${AppConstants.TABLE_ITEMS} WHERE is_active = 1');
    return (res.first['cnt'] as int?) ?? 0;
  }

  Future<void> clearItems() async {
    final d = await db;
    await d.delete(AppConstants.TABLE_ITEMS);
  }

  // ── Dashboard stats ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboardStats() async {
    final d = await db;
    final now       = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day)
        .millisecondsSinceEpoch;

    final todaySales = await d.rawQuery(
        'SELECT COALESCE(SUM(total), 0) as total, COUNT(*) as count '
        'FROM ${AppConstants.TABLE_BILLS} WHERE created_at >= ?',
        [todayStart]);

    final totalStats = await d.rawQuery(
        'SELECT COALESCE(SUM(total), 0) as total, COUNT(*) as count '
        'FROM ${AppConstants.TABLE_BILLS}');

    final pending = await getPendingCount();

    return {
      'today_sales':    (todaySales.first['total'] as num?)?.toDouble() ?? 0.0,
      'today_bills':    (todaySales.first['count'] as int?) ?? 0,
      'total_revenue':  (totalStats.first['total'] as num?)?.toDouble() ?? 0.0,
      'total_bills':    (totalStats.first['count'] as int?) ?? 0,
      'pending_sync':   pending,
    };
  }
}
