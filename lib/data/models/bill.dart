class Bill {
  final int?   id;
  final String offlineId;
  final String serverBillNo;
  final String billType;
  final String customerName;
  final String customerMobile;
  final String gstMode;
  final String paymentMethod;
  final double subtotal;
  final double gstAmount;
  final double discount;
  final double total;
  final double receivedAmount;
  final double balanceAmount;
  final String paymentStatus;
  final String lang;
  final int    createdAt;
  final bool   synced;
  final int    syncAttempts;

  const Bill({
    this.id,
    required this.offlineId,
    this.serverBillNo  = '',
    this.billType      = 'retail',
    this.customerName  = '',
    this.customerMobile= '',
    this.gstMode       = 'no_gst',
    this.paymentMethod = 'cash',
    required this.subtotal,
    this.gstAmount     = 0,
    this.discount      = 0,
    required this.total,
    required this.receivedAmount,
    this.balanceAmount = 0,
    this.paymentStatus = 'paid',
    this.lang          = 'en',
    required this.createdAt,
    this.synced        = false,
    this.syncAttempts  = 0,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'offline_id':      offlineId,
    'server_bill_no':  serverBillNo,
    'bill_type':       billType,
    'customer_name':   customerName,
    'customer_mobile': customerMobile,
    'gst_mode':        gstMode,
    'payment_method':  paymentMethod,
    'subtotal':        subtotal,
    'gst_amount':      gstAmount,
    'discount':        discount,
    'total':           total,
    'received_amount': receivedAmount,
    'balance_amount':  balanceAmount,
    'payment_status':  paymentStatus,
    'lang':            lang,
    'created_at':      createdAt,
    'synced':          synced ? 1 : 0,
    'sync_attempts':   syncAttempts,
  };

  factory Bill.fromMap(Map<String, dynamic> m) => Bill(
    id:             m['id'] as int?,
    offlineId:      m['offline_id'] as String,
    serverBillNo:   m['server_bill_no'] as String? ?? '',
    billType:       m['bill_type'] as String? ?? 'retail',
    customerName:   m['customer_name'] as String? ?? '',
    customerMobile: m['customer_mobile'] as String? ?? '',
    gstMode:        m['gst_mode'] as String? ?? 'no_gst',
    paymentMethod:  m['payment_method'] as String? ?? 'cash',
    subtotal:       (m['subtotal'] as num).toDouble(),
    gstAmount:      (m['gst_amount'] as num? ?? 0).toDouble(),
    discount:       (m['discount'] as num? ?? 0).toDouble(),
    total:          (m['total'] as num).toDouble(),
    receivedAmount: (m['received_amount'] as num).toDouble(),
    balanceAmount:  (m['balance_amount'] as num? ?? 0).toDouble(),
    paymentStatus:  m['payment_status'] as String? ?? 'paid',
    lang:           m['lang'] as String? ?? 'en',
    createdAt:      m['created_at'] as int,
    synced:         (m['synced'] as int? ?? 0) == 1,
    syncAttempts:   m['sync_attempts'] as int? ?? 0,
  );

  Bill copyWith({
    int? id, String? serverBillNo, bool? synced,
    int? syncAttempts, String? paymentStatus,
  }) => Bill(
    id:             id            ?? this.id,
    offlineId:      offlineId,
    serverBillNo:   serverBillNo  ?? this.serverBillNo,
    billType:       billType,
    customerName:   customerName,
    customerMobile: customerMobile,
    gstMode:        gstMode,
    paymentMethod:  paymentMethod,
    subtotal:       subtotal,
    gstAmount:      gstAmount,
    discount:       discount,
    total:          total,
    receivedAmount: receivedAmount,
    balanceAmount:  balanceAmount,
    paymentStatus:  paymentStatus  ?? this.paymentStatus,
    lang:           lang,
    createdAt:      createdAt,
    synced:         synced         ?? this.synced,
    syncAttempts:   syncAttempts   ?? this.syncAttempts,
  );

  String get displayBillNo =>
      serverBillNo.isNotEmpty ? serverBillNo : offlineId;

  bool get isPending => !synced;
}

// ── BillItem ──────────────────────────────────────────────────────
class BillItem {
  final int?   id;
  final int    billId;
  final int    itemId;
  final String itemName;
  final String itemNameTa;
  final String itemCode;
  final double price;
  final double salePrice;
  final double gstPercent;
  final double gstAmount;
  final int    quantity;
  final double total;

  const BillItem({
    this.id,
    required this.billId,
    required this.itemId,
    required this.itemName,
    this.itemNameTa = '',
    this.itemCode   = '',
    required this.price,
    required this.salePrice,
    this.gstPercent = 0,
    this.gstAmount  = 0,
    required this.quantity,
    required this.total,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'bill_id':     billId,
    'item_id':     itemId,
    'item_name':   itemName,
    'item_name_ta':itemNameTa,
    'item_code':   itemCode,
    'price':       price,
    'sale_price':  salePrice,
    'gst_percent': gstPercent,
    'gst_amount':  gstAmount,
    'quantity':    quantity,
    'total':       total,
  };

  factory BillItem.fromMap(Map<String, dynamic> m) => BillItem(
    id:         m['id'] as int?,
    billId:     m['bill_id'] as int,
    itemId:     m['item_id'] as int,
    itemName:   m['item_name'] as String,
    itemNameTa: m['item_name_ta'] as String? ?? '',
    itemCode:   m['item_code'] as String? ?? '',
    price:      (m['price'] as num).toDouble(),
    salePrice:  (m['sale_price'] as num).toDouble(),
    gstPercent: (m['gst_percent'] as num? ?? 0).toDouble(),
    gstAmount:  (m['gst_amount'] as num? ?? 0).toDouble(),
    quantity:   m['quantity'] as int,
    total:      (m['total'] as num).toDouble(),
  );
}

// ── Item (product catalog) ────────────────────────────────────────
class Item {
  final int    id;
  final int    typeId;
  final String typeName;
  final String typeNameTa;
  final String nameEn;
  final String nameTa;
  final String itemCode;
  final double price;
  final double salePrice;
  final double gstPercent;
  final double stock;
  final String unit;
  final bool   isActive;

  const Item({
    required this.id,
    this.typeId     = 0,
    this.typeName   = '',
    this.typeNameTa = '',
    required this.nameEn,
    this.nameTa     = '',
    this.itemCode   = '',
    required this.price,
    required this.salePrice,
    this.gstPercent = 0,
    this.stock      = 0,
    this.unit       = 'nos',
    this.isActive   = true,
  });

  String displayName(String lang) =>
      lang == 'ta' && nameTa.isNotEmpty ? nameTa : nameEn;

  String displayCategory(String lang) =>
      lang == 'ta' && typeNameTa.isNotEmpty ? typeNameTa : typeName;

  Map<String, dynamic> toMap() => {
    'id':           id,
    'type_id':      typeId,
    'type_name':    typeName,
    'type_name_ta': typeNameTa,
    'name_en':      nameEn,
    'name_ta':      nameTa,
    'item_code':    itemCode,
    'price':        price,
    'sale_price':   salePrice,
    'gst_percent':  gstPercent,
    'stock':        stock,
    'unit':         unit,
    'is_active':    isActive ? 1 : 0,
  };

  factory Item.fromMap(Map<String, dynamic> m) => Item(
    id:         m['id'] as int,
    typeId:     m['type_id'] as int? ?? 0,
    typeName:   m['type_name'] as String? ?? '',
    typeNameTa: m['type_name_ta'] as String? ?? '',
    nameEn:     (m['name_en'] ?? m['name'] ?? '') as String,
    nameTa:     m['name_ta'] as String? ?? '',
    itemCode:   m['item_code'] as String? ?? '',
    price:      (m['price'] as num).toDouble(),
    salePrice:  ((m['sale_price'] as num?) ?? (m['price'] as num)).toDouble(),
    gstPercent: (m['gst_percent'] as num? ?? 0).toDouble(),
    stock:      (m['stock'] as num? ?? 0).toDouble(),
    unit:       m['unit'] as String? ?? 'nos',
    isActive:   _asBool(m['is_active']),
  );

  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return true;
  }
}

// ── CartItem (in-memory) ──────────────────────────────────────────
class CartItem {
  final Item item;
  int quantity;
  double salePrice;

  CartItem({required this.item, this.quantity = 1, double? salePrice})
      : salePrice = salePrice ?? item.salePrice;

  double get lineTotal  => salePrice * quantity;
  double get gstAmount  => lineTotal * (item.gstPercent / 100);

  CartItem copyWith({int? quantity, double? salePrice}) => CartItem(
    item:      item,
    quantity:  quantity  ?? this.quantity,
    salePrice: salePrice ?? this.salePrice,
  );
}
