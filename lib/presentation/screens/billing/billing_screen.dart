import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/session_manager.dart';
import '../../../data/models/bill.dart';
import '../../providers/app_provider.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});
  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _lang = 'en', _cur = '₹';
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemsProvider>().init();
    });
  }

  Future<void> _loadPrefs() async {
    final l = await SessionManager.instance.lang;
    final c = await SessionManager.instance.currency;
    if (mounted) setState(() { _lang = l; _cur = c; });
  }

  bool get isTA => _lang == 'ta';

  @override
  void dispose() {
    _searchCtrl.dispose(); _searchFocus.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: C.bg,
      body: Column(children: [
        _SearchBar(ctrl: _searchCtrl, focus: _searchFocus, isTA: isTA,
          onChange: (q) => context.read<ItemsProvider>().search(q)),
        _CategoryRow(lang: _lang),
        Expanded(child: _ItemsGrid(lang: _lang, cur: _cur)),
      ]),
      bottomSheet: _CartSheet(lang: _lang, cur: _cur),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final bool isTA;
  final ValueChanged<String> onChange;
  const _SearchBar({required this.ctrl, required this.focus,
      required this.isTA, required this.onChange});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    color: C.surface,
    child: Row(children: [
      Expanded(
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: C.card, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.border)),
          child: TextField(
            controller: ctrl, focusNode: focus,
            style: const TextStyle(color: C.text, fontSize: 14),
            onChanged: onChange,
            decoration: InputDecoration(
              hintText: isTA ? 'பொருட்கள் தேடு...' : 'Search items...',
              hintStyle: const TextStyle(color: C.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: C.textMuted, size: 20),
              suffixIcon: ListenableBuilder(
                listenable: ctrl,
                builder: (_, __) => ctrl.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () { ctrl.clear(); onChange(''); },
                      child: const Icon(Icons.close, color: C.textMuted, size: 18))
                  : const SizedBox.shrink()),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
      ),
    ]),
  );
}

// ── Category Chips Row ────────────────────────────────────────────
class _CategoryRow extends StatelessWidget {
  final String lang;
  const _CategoryRow({required this.lang});

  @override
  Widget build(BuildContext context) => Consumer<ItemsProvider>(
    builder: (_, ip, __) {
      final cats = ip.allItems
          .map((i) => (id: i.typeId, name: i.displayCategory(lang)))
          .toSet().toList();
      if (cats.isEmpty) return const SizedBox.shrink();

      return Container(
        height: 44,
        color: C.surface,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            AppChip(
              label: lang == 'ta' ? 'அனைத்தும்' : 'All',
              active: ip.selectedCategory == -1,
              onTap: () => ip.selectCategory(-1)),
            const Gap(6),
            ...cats.map((c) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AppChip(
                label: c.name, active: ip.selectedCategory == c.id,
                onTap: () => ip.selectCategory(c.id)))),
          ],
        ),
      );
    },
  );
}

// ── Items Grid ────────────────────────────────────────────────────
class _ItemsGrid extends StatelessWidget {
  final String lang, cur;
  const _ItemsGrid({required this.lang, required this.cur});

  @override
  Widget build(BuildContext context) => Consumer<ItemsProvider>(
    builder: (_, ip, __) {
      if (ip.loading && ip.items.isEmpty) {
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 1.4,
            crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: 8,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: C.card, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: C.border)))
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1200.ms, color: C.elevated.withOpacity(.6)),
        );
      }

      if (ip.items.isEmpty) {
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.inventory_2_outlined, size: 56, color: C.textMuted),
          const Gap(12),
          Text(lang == 'ta' ? 'பொருட்கள் இல்லை' : 'No items found',
            style: const TextStyle(color: C.textSub, fontSize: 15)),
          const Gap(12),
          TextButton.icon(
            onPressed: ip.refreshFromServer,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(lang == 'ta' ? 'புதுப்பி' : 'Refresh')),
        ]));
      }

      return RefreshIndicator(
        color: C.primary,
        onRefresh: ip.refreshFromServer,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 1.35,
            crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: ip.items.length,
          itemBuilder: (ctx, i) {
            final item = ip.items[i];
            return _ItemCard(item: item, lang: lang, cur: cur,
              onTap: () {
                HapticFeedback.lightImpact();
                ctx.read<CartProvider>().addItem(item);
              })
            .animate().fadeIn(delay: Duration(milliseconds: i * 30))
            .slideY(begin: .05, duration: 250.ms);
          },
        ),
      );
    },
  );
}

// ── Item Card ──────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final Item item;
  final String lang, cur;
  final VoidCallback onTap;
  const _ItemCard({required this.item, required this.lang,
      required this.cur, required this.onTap});

  @override
  Widget build(BuildContext context) => Consumer<CartProvider>(
    builder: (_, cart, __) {
      final inCart = cart.cart.where((ci) => ci.item.id == item.id).firstOrNull;
      final active = inCart != null;

      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 180.ms,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? C.primary.withOpacity(.08) : C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? C.primary.withOpacity(.6) : C.border,
              width: active ? 1.5 : 1)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(item.displayName(lang),
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: active ? C.primary : C.text),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
                if (active)
                  AnimatedContainer(
                    duration: 200.ms,
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      gradient: C.gradPrimary, shape: BoxShape.circle),
                    child: Center(child: Text('${inCart.quantity}',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.w700)))),
              ]),
              if (item.itemCode.isNotEmpty) ...[
                const Gap(2),
                Text(item.itemCode,
                  style: const TextStyle(fontSize: 10, color: C.textMuted))],
              const Spacer(),
              Text('$cur${item.salePrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: C.green)),
              if (item.stock > 0)
                Text('${item.stock.toInt()} ${item.unit}',
                  style: const TextStyle(fontSize: 10, color: C.textMuted)),
            ],
          ),
        ),
      );
    },
  );
}

// ── Cart Bottom Sheet ──────────────────────────────────────────────
class _CartSheet extends StatelessWidget {
  final String lang, cur;
  const _CartSheet({required this.lang, required this.cur});

  @override
  Widget build(BuildContext context) => Consumer<CartProvider>(
    builder: (_, cart, __) {
      if (cart.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: C.surface,
          border: const Border(top: BorderSide(color: C.border)),
          boxShadow: [BoxShadow(
            color: C.primary.withOpacity(.08),
            blurRadius: 20, offset: const Offset(0, -4))]),
        child: Row(children: [
          // Cart info
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${cart.itemCount} ${lang == "ta" ? "items" : "items"}',
              style: const TextStyle(fontSize: 11, color: C.textSub)),
            Text('$cur${cart.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: C.primary)),
          ]),
          const Spacer(),

          // View cart
          GestureDetector(
            onTap: () => _showCart(context, cart),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: C.card, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.border)),
              child: Row(children: [
                const Icon(Icons.shopping_cart_outlined, size: 16, color: C.primary),
                const Gap(4),
                Text('${cart.cart.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: C.primary)),
              ]),
            ),
          ),

          // Checkout
          GestureDetector(
            onTap: () => _showCheckout(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: C.gradGreen,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                  color: C.green.withOpacity(.3), blurRadius: 12)]),
              child: Row(children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const Gap(6),
                Text(lang == 'ta' ? 'Checkout' : 'Checkout',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
            ),
          ),
        ]),
      )
      .animate().slideY(begin: 1, duration: 250.ms, curve: Curves.easeOut);
    },
  );

  void _showCart(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider.value(
        value: cart,
        child: _CartListSheet(lang: lang, cur: cur,
          onCheckout: () { Navigator.pop(context); _showCheckout(context); }),
      ),
    );
  }

  void _showCheckout(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _CheckoutSheet(lang: lang, cur: cur)),
    );
  }
}

// ── Cart List Sheet ───────────────────────────────────────────────
class _CartListSheet extends StatelessWidget {
  final String lang, cur;
  final VoidCallback onCheckout;
  const _CartListSheet({required this.lang, required this.cur, required this.onCheckout});

  @override
  Widget build(BuildContext context) => Consumer<CartProvider>(
    builder: (_, cart, __) => DraggableScrollableSheet(
      expand: false, initialChildSize: .6, maxChildSize: .9,
      builder: (_, scroll) => Column(children: [
        // Handle
        Container(margin: const EdgeInsets.only(top: 10, bottom: 8),
          width: 36, height: 4,
          decoration: BoxDecoration(color: C.border,
              borderRadius: BorderRadius.circular(2))),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Text(lang == 'ta' ? 'கார்ட்' : 'Cart',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.text)),
            const Spacer(),
            TextButton(
              onPressed: () { cart.clear(); Navigator.pop(context); },
              child: Text(lang == 'ta' ? 'அழி' : 'Clear',
                style: const TextStyle(color: C.red))),
          ]),
        ),

        // Items
        Expanded(child: ListView.separated(
          controller: scroll,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: cart.cart.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final ci = cart.cart[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ci.item.displayName(lang),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text)),
                  Text('$cur${ci.salePrice.toStringAsFixed(2)} each',
                    style: const TextStyle(fontSize: 11, color: C.textSub)),
                ])),
                // Qty controls
                Row(children: [
                  _QtyBtn(icon: Icons.remove, onTap: () => cart.updateQty(ci.item.id, ci.quantity - 1)),
                  SizedBox(width: 36,
                    child: Text('${ci.quantity}', textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: C.text, fontSize: 15))),
                  _QtyBtn(icon: Icons.add, onTap: () => cart.updateQty(ci.item.id, ci.quantity + 1),
                    color: C.primary),
                ]),
                const Gap(8),
                Text('$cur${ci.lineTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: C.primary, fontSize: 13)),
              ]),
            );
          },
        )),

        // Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: C.border))),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lang == 'ta' ? 'மொத்தம்' : 'Total',
                style: const TextStyle(fontSize: 12, color: C.textSub)),
              Text('$cur${cart.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.text)),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: onCheckout,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: C.gradGreen, borderRadius: BorderRadius.circular(14)),
                child: Text(lang == 'ta' ? 'Checkout' : 'Checkout',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 15)))),
          ]),
        ),
      ]),
    ),
  );
}

// ── Checkout Sheet ────────────────────────────────────────────────
class _CheckoutSheet extends StatefulWidget {
  final String lang, cur;
  const _CheckoutSheet({required this.lang, required this.cur});
  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _nameCtrl = TextEditingController();
  final _mobCtrl  = TextEditingController();
  final _discCtrl = TextEditingController(text: '0');

  bool get isTA => widget.lang == 'ta';
  String get cur => widget.cur;
  String t(String en, String ta) => isTA ? ta : en;

  @override
  void dispose() {
    _nameCtrl.dispose(); _mobCtrl.dispose(); _discCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<CartProvider>(
    builder: (_, cart, __) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Handle
        Center(child: Container(width: 36, height: 4,
          decoration: BoxDecoration(color: C.border,
              borderRadius: BorderRadius.circular(2)))),
        const Gap(16),

        Text(t('Checkout', 'Checkout'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: C.text)),
        const Gap(20),

        // Customer Name
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: C.text),
          decoration: InputDecoration(
            labelText: t('Customer Name (optional)', 'வாடிக்கையாளர் பெயர்'),
            prefixIcon: const Icon(Icons.person_outline, color: C.textSub, size: 20))),
        const Gap(12),

        // Mobile
        TextField(
          controller: _mobCtrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: C.text),
          decoration: InputDecoration(
            labelText: t('Mobile (optional)', 'கைபேசி'),
            prefixIcon: const Icon(Icons.phone_outlined, color: C.textSub, size: 20))),
        const Gap(16),

        // GST Mode
        _SectionLabel(label: t('GST', 'GST')),
        const Gap(8),
        Row(children: [
          Expanded(child: _OptionTile(
            label: t('No GST', 'GST இல்லை'), active: cart.gstMode == 'no_gst',
            onTap: () => cart.setGstMode('no_gst'))),
          const Gap(8),
          Expanded(child: _OptionTile(
            label: t('With GST', 'GST Bill'), active: cart.gstMode == 'gst',
            onTap: () => cart.setGstMode('gst'))),
        ]),
        const Gap(14),

        // Payment Method
        _SectionLabel(label: t('Payment', 'கட்டணம்')),
        const Gap(8),
        Row(children: [
          for (final m in [
            (id: 'cash',   icon: Icons.payments_outlined,  label: t('Cash','Cash')),
            (id: 'upi',    icon: Icons.qr_code,             label: 'UPI'),
            (id: 'card',   icon: Icons.credit_card,         label: t('Card','Card')),
            (id: 'credit', icon: Icons.account_balance_wallet_outlined, label: t('Credit','Credit')),
          ]) ...[
            Expanded(child: _PayBtn(
              icon: m.icon, label: m.label,
              active: cart.paymentMethod == m.id,
              onTap: () => cart.setPayMode(m.id))),
            if (m.id != 'credit') const Gap(6),
          ],
        ]),
        const Gap(14),

        // Discount
        TextField(
          controller: _discCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: C.text),
          decoration: InputDecoration(
            labelText: t('Discount (₹)', 'தள்ளுபடி (₹)'),
            prefixIcon: const Icon(Icons.local_offer_outlined, color: C.textSub, size: 20)),
          onChanged: (v) => cart.setDiscount(double.tryParse(v) ?? 0)),
        const Gap(16),

        // Totals
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: C.card, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.border)),
          child: Column(children: [
            _TotRow(label: t('Subtotal','உபமொத்தம்'),
                value: '$cur${cart.subtotal.toStringAsFixed(2)}'),
            if (cart.gstMode == 'gst' && cart.gst > 0)
              _TotRow(label: 'GST', value: '$cur${cart.gst.toStringAsFixed(2)}',
                  color: C.textSub),
            if (cart.discount > 0)
              _TotRow(label: t('Discount','தள்ளுபடி'),
                  value: '-$cur${cart.discount.toStringAsFixed(2)}', color: C.red),
            const Divider(height: 16),
            _TotRow(label: t('TOTAL','மொத்தம்'),
                value: '$cur${cart.total.toStringAsFixed(2)}', big: true),
          ]),
        ),
        const Gap(20),

        // Save Bill Button
        Consumer<BillingProvider>(
          builder: (ctx, billing, __) => PrimaryButton(
            label: t('✅  Save Bill', '✅  பில் சேமி'),
            loading: billing.loading,
            gradient: C.gradGreen,
            onTap: () => _save(ctx, billing, cart))),
        const Gap(8),

        Center(child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('Cancel', 'ரத்து'),
            style: const TextStyle(color: C.textSub)))),
      ]),
    ),
  );

  Future<void> _save(BuildContext ctx, BillingProvider billing, CartProvider cart) async {
    try {
      final result = await billing.checkout(
        cart: cart, customerName: _nameCtrl.text.trim(),
        customerMobile: _mobCtrl.text.trim(), lang: widget.lang);
      if (result == null || !ctx.mounted) return;
      Navigator.pop(ctx);
      _showSuccess(ctx, result, cart);
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(e.toString()), backgroundColor: C.red));
    }
  }

  void _showSuccess(BuildContext ctx, dynamic result, CartProvider cart) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: C.gradGreen, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: C.green.withOpacity(.4), blurRadius: 20)]),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36))
            .animate().scale(duration: 400.ms, curve: Curves.elasticOut),

            const Gap(16),
            Text(isTA ? 'பில் சேமிக்கப்பட்டது!' : 'Bill Saved!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.text)),
            const Gap(6),
            Text(result.displayBillNo,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.primary)),
            const Gap(4),
            Text('$cur${result.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, color: C.textSub)),

            if (result.isOffline) ...[
              const Gap(12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: C.orange.withOpacity(.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: C.orange.withOpacity(.3))),
                child: Row(children: [
                  const Icon(Icons.cloud_off_outlined, color: C.orange, size: 18),
                  const Gap(8),
                  Expanded(child: Text(
                    isTA ? 'Offline-ல் சேமிக்கப்பட்டது.\nInternet வந்தா sync ஆகும்.'
                         : 'Saved offline.\nWill sync when connected.',
                    style: const TextStyle(fontSize: 12, color: C.orange))),
                ])),
            ],

            const Gap(20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isTA ? '+ புதிய பில்' : '+ New Bill'))),
          ]),
        ),
      ),
    );
  }
}

// Supporting widgets
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
        color: C.textSub, letterSpacing: .5));
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _OptionTile({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: 150.ms, height: 42,
      decoration: BoxDecoration(
        color: active ? C.primary.withOpacity(.12) : C.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? C.primary : C.border, width: active ? 1.5 : 1)),
      child: Center(child: Text(label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: active ? C.primary : C.textSub)))));
}

class _PayBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PayBtn({required this.icon, required this.label,
      required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: 150.ms, height: 56,
      decoration: BoxDecoration(
        color: active ? C.primary.withOpacity(.1) : C.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? C.primary : C.border, width: active ? 1.5 : 1)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 18, color: active ? C.primary : C.textSub),
        const Gap(3),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
            color: active ? C.primary : C.textSub)),
      ])));
}

class _TotRow extends StatelessWidget {
  final String label, value;
  final bool big;
  final Color? color;
  const _TotRow({required this.label, required this.value,
      this.big = false, this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(label, style: TextStyle(
        fontSize: big ? 15 : 13,
        fontWeight: big ? FontWeight.w700 : FontWeight.normal,
        color: color ?? C.textSub)),
      const Spacer(),
      Text(value, style: TextStyle(
        fontSize: big ? 20 : 13,
        fontWeight: big ? FontWeight.w800 : FontWeight.w600,
        color: color ?? (big ? C.green : C.text))),
    ]));
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _QtyBtn({required this.icon, required this.onTap, this.color = C.border});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(.4))),
      child: Icon(icon, size: 16,
          color: color == C.border ? C.text : color)));
}
