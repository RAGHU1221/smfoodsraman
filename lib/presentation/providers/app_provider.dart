import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/session_manager.dart';
import '../../data/local/db/database_helper.dart';
import '../../data/models/bill.dart';
import '../../data/repositories/bill_repository.dart';

// ── Auth Provider ─────────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  bool _loading = false;
  String _error = '';
  bool get loading => _loading;
  String get error => _error;

  Future<bool> login(String email, String password) async {
    _loading = true; _error = ''; notifyListeners();
    try {
      final res = await ApiClient.post(
        endpoint: 'login.php',
        body: {'email': email.trim().toLowerCase(), 'password': password},
      );
      await SessionManager.instance.saveFromLoginJson(res);
      _loading = false; notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false; notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await SessionManager.instance.logout();
    notifyListeners();
  }
}

// ── Items Provider ─────────────────────────────────────────────────
class ItemsProvider extends ChangeNotifier {
  List<Item> _allItems     = [];
  List<Item> _filtered     = [];
  List<Item> get items     => _filtered;
  List<Item> get allItems  => _allItems;
  bool  _loading           = false;
  bool  get loading        => _loading;
  String _searchQuery      = '';
  int   _selectedCategory  = -1;
  int   get selectedCategory => _selectedCategory;

  Set<int> get categories => _allItems.map((i) => i.typeId).toSet();

  Future<void> init() async {
    // Load from local DB first
    final local = await DatabaseHelper.instance.getAllItems();
    if (local.isNotEmpty) {
      _allItems = local;
      _applyFilter();
      notifyListeners();
    }
    // Then refresh from server
    await refreshFromServer();
  }

  Future<void> refreshFromServer() async {
    final isOnline = (await Connectivity().checkConnectivity()) != ConnectivityResult.none;
    if (!isOnline) return;

    _loading = true; notifyListeners();
    try {
      final token = await SessionManager.instance.token;
      final res   = await ApiClient.get(endpoint: 'items.php', token: token);
      final list  = (res['items'] as List<dynamic>? ?? [])
          .map((e) => Item.fromMap(e as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) {
        await DatabaseHelper.instance.upsertItems(list);
        _allItems = list;
        _applyFilter();
      }
    } catch (_) { /* use cached */ }
    _loading = false; notifyListeners();
  }

  void search(String q) {
    _searchQuery = q;
    _applyFilter();
    notifyListeners();
  }

  void selectCategory(int catId) {
    _selectedCategory = catId;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filtered = _allItems.where((item) {
      final matchCat = _selectedCategory == -1 || item.typeId == _selectedCategory;
      final matchQ   = _searchQuery.isEmpty ||
          item.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.nameTa.contains(_searchQuery) ||
          item.itemCode.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchQ;
    }).toList();
  }

  String categoryName(int typeId, String lang) {
    if (_allItems.isEmpty) return '';
    final match = _allItems.where((i) => i.typeId == typeId);
    if (match.isEmpty) return '';
    return match.first.displayCategory(lang);
  }
}

// ── Cart Provider ──────────────────────────────────────────────────
class CartProvider extends ChangeNotifier {
  final List<CartItem> _cart = [];
  List<CartItem> get cart => List.unmodifiable(_cart);

  String gstMode      = 'no_gst';
  String paymentMethod= 'cash';
  double discount     = 0;

  double get subtotal => _cart.fold(0, (s, ci) => s + ci.lineTotal);
  double get gst      => gstMode == 'gst'
      ? _cart.fold(0, (s, ci) => s + ci.gstAmount) : 0;
  double get total    => (subtotal + gst - discount).clamp(0.0, double.infinity);
  int    get itemCount=> _cart.fold(0, (s, ci) => s + ci.quantity);
  bool   get isEmpty  => _cart.isEmpty;
  bool   get isNotEmpty => _cart.isNotEmpty;

  void addItem(Item item) {
    final idx = _cart.indexWhere((ci) => ci.item.id == item.id);
    if (idx >= 0) {
      _cart[idx] = _cart[idx].copyWith(quantity: _cart[idx].quantity + 1);
    } else {
      _cart.add(CartItem(item: item));
    }
    notifyListeners();
  }

  void updateQty(int itemId, int qty) {
    final idx = _cart.indexWhere((ci) => ci.item.id == itemId);
    if (idx < 0) return;
    if (qty <= 0) {
      _cart.removeAt(idx);
    } else {
      _cart[idx] = _cart[idx].copyWith(quantity: qty);
    }
    notifyListeners();
  }

  void removeItem(int itemId) {
    _cart.removeWhere((ci) => ci.item.id == itemId);
    notifyListeners();
  }

  void setGstMode(String mode) { gstMode = mode; notifyListeners(); }
  void setPayMode(String mode) { paymentMethod = mode; notifyListeners(); }
  void setDiscount(double d)   { discount = d; notifyListeners(); }

  void clear() {
    _cart.clear();
    gstMode = 'no_gst';
    paymentMethod = 'cash';
    discount = 0;
    notifyListeners();
  }
}

// ── Billing Provider ───────────────────────────────────────────────
class BillingProvider extends ChangeNotifier {
  final BillRepository _repo = BillRepository();
  bool _loading = false;
  bool get loading => _loading;

  Future<SaveBillResult?> checkout({
    required CartProvider cart,
    required String customerName,
    required String customerMobile,
    required String lang,
  }) async {
    if (cart.isEmpty) return null;
    _loading = true; notifyListeners();
    try {
      final result = await _repo.saveBill(
        cart:           cart.cart,
        customerName:   customerName,
        customerMobile: customerMobile,
        gstMode:        cart.gstMode,
        paymentMethod:  cart.paymentMethod,
        discount:       cart.discount,
        lang:           lang,
      );
      cart.clear();
      _loading = false; notifyListeners();
      return result;
    } catch (e) {
      _loading = false; notifyListeners();
      rethrow;
    }
  }
}

// ── Bills / Reports Provider ──────────────────────────────────────
class BillsProvider extends ChangeNotifier {
  final BillRepository _repo = BillRepository();
  List<Bill> _bills      = [];
  List<Bill> get bills   => _bills;
  int  _pendingCount     = 0;
  int  get pendingCount  => _pendingCount;
  bool _syncing          = false;
  bool get syncing       => _syncing;

  Future<void> load() async {
    _bills        = await _repo.getAllBills();
    _pendingCount = await _repo.getPendingCount();
    notifyListeners();
  }

  Future<void> sync() async {
    final isOnline = (await Connectivity().checkConnectivity()) != ConnectivityResult.none;
    if (!isOnline || _syncing) return;
    _syncing = true; notifyListeners();
    await _repo.syncPendingBills();
    await load();
    _syncing = false; notifyListeners();
  }

  Future<void> deleteBill(int id) async {
    await _repo.deleteBill(id);
    await load();
  }
}

// ── Dashboard Provider ────────────────────────────────────────────
class DashboardProvider extends ChangeNotifier {
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> get stats => _stats;

  Future<void> load() async {
    _stats = await DatabaseHelper.instance.getDashboardStats();
    notifyListeners();
  }
}

// ── Connectivity Provider ─────────────────────────────────────────
class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    Connectivity().onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
    });
    _init();
  }

  Future<void> _init() async {
    final result = await Connectivity().checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();
  }
}
