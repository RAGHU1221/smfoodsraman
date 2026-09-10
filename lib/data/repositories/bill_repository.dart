import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/db/database_helper.dart';
import '../models/bill.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/session_manager.dart';

class BillRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // ── Save bill (offline-first) ─────────────────────────────────
  Future<SaveBillResult> saveBill({
    required List<CartItem> cart,
    required String customerName,
    required String customerMobile,
    required String gstMode,
    required String paymentMethod,
    required double discount,
    required String lang,
  }) async {
    final subtotal = cart.fold(0.0, (s, ci) => s + ci.lineTotal);
    final gst      = gstMode == 'gst'
        ? cart.fold(0.0, (s, ci) => s + ci.gstAmount)
        : 0.0;
    final total    = (subtotal + gst - discount).clamp(0.0, double.infinity);
    final offlineId= 'OFF_${DateTime.now().millisecondsSinceEpoch}';
    final now      = DateTime.now().millisecondsSinceEpoch;

    final bill = Bill(
      offlineId:      offlineId,
      billType:       'retail',
      customerName:   customerName,
      customerMobile: customerMobile,
      gstMode:        gstMode,
      paymentMethod:  paymentMethod,
      subtotal:       subtotal,
      gstAmount:      gst,
      discount:       discount,
      total:          total,
      receivedAmount: total,
      paymentStatus:  'paid',
      lang:           lang,
      createdAt:      now,
      synced:         false,
    );

    // 1. Save locally FIRST (always works, even offline)
    final billId = await _db.insertBill(bill);

    final items = cart.map((ci) => BillItem(
      billId:     billId,
      itemId:     ci.item.id,
      itemName:   ci.item.nameEn,
      itemNameTa: ci.item.nameTa,
      itemCode:   ci.item.itemCode,
      price:      ci.item.price,
      salePrice:  ci.salePrice,
      gstPercent: ci.item.gstPercent,
      gstAmount:  ci.gstAmount,
      quantity:   ci.quantity,
      total:      ci.lineTotal,
    )).toList();

    await _db.insertBillItems(items);

    // 2. Try immediate online sync if connected
    final isOnline = await _isOnline();
    if (isOnline) {
      try {
        final result = await _syncBillToServer(
          bill.copyWith(id: billId), items);
        if (result != null) {
          await _db.markBillSynced(billId, result);
          return SaveBillResult(
            billId:      billId,
            offlineId:   offlineId,
            serverBillNo: result,
            isOffline:   false,
            total:       total,
          );
        }
      } catch (_) {
        // Sync failed — will retry via background sync
      }
    }

    return SaveBillResult(
      billId:    billId,
      offlineId: offlineId,
      isOffline: true,
      total:     total,
    );
  }

  // ── Sync one bill to server ───────────────────────────────────
  Future<String?> _syncBillToServer(Bill bill, List<BillItem> items) async {
    final token = await SessionManager.instance.token;
    if (token.isEmpty) return null;

    final payload = {
      'offline_id':      bill.offlineId,
      'bill_type':       bill.billType,
      'customer_name':   bill.customerName,
      'customer_mobile': bill.customerMobile,
      'gst_mode':        bill.gstMode,
      'payment_method':  bill.paymentMethod,
      'lang':            bill.lang,
      'subtotal':        bill.subtotal,
      'gst_amount':      bill.gstAmount,
      'discount':        bill.discount,
      'total':           bill.total,
      'received_amount': bill.receivedAmount,
      'items': items.map((i) => {
        'item_id':        i.itemId,
        'item_name':      i.itemName,
        'item_name_ta':   i.itemNameTa,
        'item_code':      i.itemCode,
        'price':          i.price,
        'original_price': i.price,
        'sale_price':     i.salePrice,
        'gst_percent':    i.gstPercent,
        'gst_amount':     i.gstAmount,
        'quantity':       i.quantity,
        'total':          i.total,
      }).toList(),
    };

    final res = await ApiClient.post(
      endpoint: 'save_bill.php',
      body: payload,
      token: token,
    );

    return res['bill_no'] as String?;
  }

  // ── Sync all pending bills ────────────────────────────────────
  Future<SyncResult> syncPendingBills() async {
    final pending = await _db.getPendingBills();
    if (pending.isEmpty) return const SyncResult(synced: 0, failed: 0);

    int synced = 0;
    int failed = 0;

    for (final bill in pending) {
      try {
        final items = await _db.getBillItems(bill.id!);
        final serverBillNo = await _syncBillToServer(bill, items);
        if (serverBillNo != null) {
          await _db.markBillSynced(bill.id!, serverBillNo);
          synced++;
        } else {
          await _db.incrementSyncAttempt(bill.id!);
          failed++;
        }
      } catch (_) {
        await _db.incrementSyncAttempt(bill.id!);
        failed++;
      }
    }

    return SyncResult(synced: synced, failed: failed);
  }

  Future<List<Bill>> getAllBills()    => _db.getAllBills();
  Future<int> getPendingCount()       => _db.getPendingCount();
  Future<List<BillItem>> getBillItems(int billId) => _db.getBillItems(billId);
  Future<void> deleteBill(int id)    => _db.deleteBill(id);

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}

class SaveBillResult {
  final int    billId;
  final String offlineId;
  final String serverBillNo;
  final bool   isOffline;
  final double total;

  const SaveBillResult({
    required this.billId,
    required this.offlineId,
    this.serverBillNo = '',
    required this.isOffline,
    this.total = 0.0,
  });

  String get displayBillNo =>
      serverBillNo.isNotEmpty ? serverBillNo : 'OFFLINE-$billId';
}

class SyncResult {
  final int synced;
  final int failed;
  const SyncResult({required this.synced, required this.failed});
}
