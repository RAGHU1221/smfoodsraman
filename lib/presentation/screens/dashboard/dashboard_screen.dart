import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/session_manager.dart';
import '../../../data/models/bill.dart';
import '../../providers/app_provider.dart';
import 'package:badges/badges.dart' as badges;
import '../billing/billing_screen.dart';

// ═══════════════════════════════════════════════════
// HOME SCREEN with bottom nav
// ═══════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 1;
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    SessionManager.instance.lang.then((l) {
      if (mounted) setState(() => _lang = l);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
      context.read<BillsProvider>().load();
    });
  }

  bool get isTA => _lang == 'ta';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: _buildAppBar(),
      body: IndexedStack(index: _idx, children: const [
        DashboardScreen(),
        BillingScreen(),
        ReportsScreen(),
        SyncScreen(),
      ]),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar _buildAppBar() => AppBar(
    backgroundColor: C.surface,
    elevation: 0,
    title: Row(children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          gradient: C.gradPrimary,
          borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 16)),
      const Gap(10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Sri Murugan POS',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.text)),
        Consumer<ConnectivityProvider>(
          builder: (_, cp, __) => Row(children: [
            Container(width: 6, height: 6,
              decoration: BoxDecoration(
                color: cp.isOnline ? C.green : C.red,
                shape: BoxShape.circle)),
            const Gap(4),
            Text(cp.isOnline ? 'Online' : 'Offline',
              style: TextStyle(fontSize: 10,
                  color: cp.isOnline ? C.green : C.red)),
          ])),
      ]),
    ]),
    actions: [
      Consumer<BillsProvider>(
        builder: (_, bp, __) => Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.cloud_sync_outlined, color: C.textSub),
              onPressed: () => setState(() => _idx = 3)),
            if (bp.pendingCount > 0)
              Positioned(right: 8, top: 8,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                    color: C.orange, shape: BoxShape.circle),
                  child: Center(child: Text('${bp.pendingCount}',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                        color: Colors.black)))).animate().scale()),
          ])),
      const Gap(4),
    ],
  );

  Widget _buildBottomNav() => Container(
    decoration: const BoxDecoration(
      color: C.surface,
      border: Border(top: BorderSide(color: C.border))),
    child: BottomNavigationBar(
      currentIndex: _idx,
      onTap: (i) => setState(() => _idx = i),
      backgroundColor: Colors.transparent,
      elevation: 0,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.grid_view_outlined),
          activeIcon: const Icon(Icons.grid_view_rounded),
          label: isTA ? 'Dashboard' : 'Dashboard'),
        BottomNavigationBarItem(
          icon: const Icon(Icons.point_of_sale_outlined),
          activeIcon: const Icon(Icons.point_of_sale_rounded),
          label: isTA ? 'பில்' : 'Billing'),
        BottomNavigationBarItem(
          icon: const Icon(Icons.receipt_long_outlined),
          activeIcon: const Icon(Icons.receipt_long_rounded),
          label: isTA ? 'அறிக்கை' : 'Reports'),
        BottomNavigationBarItem(
          icon: Consumer<BillsProvider>(
            builder: (_, bp, __) => badges.Badge(
              showBadge: bp.pendingCount > 0,
              badgeContent: Text('${bp.pendingCount}',
                  style: const TextStyle(fontSize: 9, color: Colors.white)),
              badgeStyle: const badges.BadgeStyle(badgeColor: C.orange),
              child: const Icon(Icons.cloud_upload_outlined))),
          activeIcon: const Icon(Icons.cloud_upload_rounded),
          label: 'Sync'),
      ],
    ),
  );
}

// Billing wrapper - uses BillingScreen from billing_screen.dart

// ═══════════════════════════════════════════════════
// DASHBOARD SCREEN
// ═══════════════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _lang = 'en', _cur = '₹', _name = 'Admin';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await SessionManager.instance.lang;
    final c = await SessionManager.instance.currency;
    final n = await SessionManager.instance.userName;
    if (mounted) setState(() { _lang=l; _cur=c; _name=n; });
    if (mounted) context.read<DashboardProvider>().load();
  }

  bool get isTA => _lang == 'ta';
  String t(String en, String ta) => isTA ? ta : en;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      color: C.primary,
      onRefresh: () async => context.read<DashboardProvider>().load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Welcome header
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${t("Hi","வணக்கம்")}, $_name! 👋',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.text)),
                const Gap(2),
                Text(DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
                  style: const TextStyle(fontSize: 12, color: C.textSub)),
              ])),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: C.gradPrimary, shape: BoxShape.circle),
                child: Center(child: Text(_name.isNotEmpty ? _name[0].toUpperCase() : 'A',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: Colors.white)))),
            ]),
          )
          .animate().fadeIn().slideY(begin: -.05),

          const Gap(16),

          // Stats
          Consumer<DashboardProvider>(
            builder: (_, dp, __) {
              final s = dp.stats;
              if (s.isEmpty) return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: C.primary, strokeWidth: 2)));

              return Column(children: [
                Row(children: [
                  Expanded(child: _StatCard(
                    label: t("Today's Sales", 'இன்று விற்பனை'),
                    value: '$_cur${(s['today_sales'] ?? 0.0).toStringAsFixed(2)}',
                    icon: Icons.trending_up_rounded,
                    gradient: C.gradGreen, delay: 0)),
                  const Gap(10),
                  Expanded(child: _StatCard(
                    label: t("Today's Bills", 'இன்று பில்கள்'),
                    value: '${s['today_bills'] ?? 0}',
                    icon: Icons.receipt_rounded,
                    gradient: C.gradPrimary, delay: 100)),
                ]),
                const Gap(10),
                Row(children: [
                  Expanded(child: _StatCard(
                    label: t('Total Bills', 'மொத்த பில்கள்'),
                    value: '${s['total_bills'] ?? 0}',
                    icon: Icons.list_alt_rounded,
                    color: C.blue, delay: 200)),
                  const Gap(10),
                  Expanded(child: _StatCard(
                    label: t('Pending Sync', 'Sync Pending'),
                    value: '${s['pending_sync'] ?? 0}',
                    icon: Icons.cloud_upload_outlined,
                    color: (s['pending_sync'] ?? 0) > 0 ? C.orange : C.green,
                    delay: 300)),
                ]),
              ]);
            }),

          const Gap(20),

          // Quick actions
          Text(t('Quick Actions', 'விரைவு செயல்கள்'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: C.textSub, letterSpacing: .3))
          .animate().fadeIn(delay: 400.ms),
          const Gap(10),

          Row(children: [
            Expanded(child: _QuickBtn(
              icon: Icons.add_shopping_cart_rounded,
              label: t('New Bill', 'புதிய பில்'),
              gradient: C.gradPrimary,
              onTap: () {
                final state = context.findAncestorStateOfType<_HomeScreenState>();
                if (state != null) {
                  state.setState(() => state._idx = 1);
                }
              })),
            const Gap(10),
            Expanded(child: _QuickBtn(
              icon: Icons.cloud_sync_rounded,
              label: t('Sync Now', 'Sync'),
              gradient: LinearGradient(colors: [C.orange, C.orange.withOpacity(.7)]),
              onTap: () => context.read<BillsProvider>().sync())),
          ])
          .animate().fadeIn(delay: 500.ms).slideY(begin: .1),

          const Gap(16),

          // Recent bills
          Consumer<BillsProvider>(
            builder: (_, bp, __) {
              final recent = bp.bills.take(3).toList();
              if (recent.isEmpty) return const SizedBox.shrink();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t('Recent Bills', 'சமீபத்திய பில்கள்'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: C.textSub, letterSpacing: .3)),
                const Gap(10),
                ...recent.asMap().entries.map((e) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _BillTile(bill: e.value, lang: _lang, cur: _cur))
                  .animate().fadeIn(delay: Duration(milliseconds: 600 + e.key * 80))
                  .slideX(begin: .05)),
              ]);
            }),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final LinearGradient? gradient;
  final Color? color;
  final int delay;

  const _StatCard({required this.label, required this.value,
      required this.icon, this.gradient, this.color, required this.delay});

  @override
  Widget build(BuildContext context) {
    final c = color ?? C.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient != null
            ? LinearGradient(colors: [
                gradient!.colors.first.withOpacity(.12),
                gradient!.colors.last.withOpacity(.06)])
            : null,
        color: gradient == null ? C.card : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (gradient?.colors.first ?? c).withOpacity(.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? c.withOpacity(.15) : null,
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20,
              color: gradient != null ? Colors.white : c)),
        const Gap(12),
        Text(value, style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w800,
          color: gradient?.colors.first ?? c)),
        const Gap(2),
        Text(label, style: const TextStyle(
          fontSize: 11, color: C.textSub), maxLines: 1,
          overflow: TextOverflow.ellipsis),
      ]),
    )
    .animate().fadeIn(delay: Duration(milliseconds: delay))
    .slideY(begin: .1, duration: 300.ms);
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _QuickBtn({required this.icon, required this.label,
      required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: gradient, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: gradient.colors.first.withOpacity(.3), blurRadius: 12)]),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 20),
        const Gap(8),
        Text(label, style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      ])));
}

class _BillTile extends StatelessWidget {
  final Bill bill;
  final String lang, cur;
  const _BillTile({required this.bill, required this.lang, required this.cur});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: bill.synced ? C.green.withOpacity(.1) : C.orange.withOpacity(.1),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(
          bill.synced ? Icons.cloud_done_outlined : Icons.schedule,
          color: bill.synced ? C.green : C.orange, size: 18)),
      const Gap(12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(bill.displayBillNo,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: bill.synced ? C.green : C.orange)),
        Text(bill.customerName.isNotEmpty
            ? bill.customerName : (lang == 'ta' ? 'Walk-in' : 'Walk-in'),
          style: const TextStyle(fontSize: 11, color: C.textSub)),
      ])),
      Text('$cur${bill.total.toStringAsFixed(2)}',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.text)),
    ]));
}

// ═══════════════════════════════════════════════════
// REPORTS SCREEN
// ═══════════════════════════════════════════════════
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _lang = 'en', _cur = '₹';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await SessionManager.instance.lang;
    final c = await SessionManager.instance.currency;
    if (mounted) setState(() { _lang=l; _cur=c; });
    if (mounted) context.read<BillsProvider>().load();
  }

  bool get isTA => _lang == 'ta';

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<BillsProvider>(
      builder: (_, bp, __) => Column(children: [
        // Summary header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: C.surface,
          child: Row(children: [
            _SumItem(label: isTA ? 'மொத்தம்' : 'Bills',
                value: '${bp.bills.length}', color: C.primary),
            _SumItem(label: isTA ? 'Pending' : 'Pending',
                value: '${bp.pendingCount}', color: C.orange),
            _SumItem(label: isTA ? 'Synced' : 'Synced',
                value: '${bp.bills.where((b) => b.synced).length}', color: C.green),
            _SumItem(
                label: isTA ? 'Total' : 'Revenue',
                value: '$_cur${bp.bills.fold(0.0,(s,b)=>s+b.total).toStringAsFixed(0)}',
                color: C.blue),
          ].map((w) => Expanded(child: w)).toList()),
        ),

        if (bp.bills.isEmpty)
          Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.receipt_long_outlined, size: 56, color: C.textMuted),
            const Gap(12),
            Text(isTA ? 'பில்கள் இல்லை' : 'No bills yet',
              style: const TextStyle(color: C.textSub, fontSize: 15)),
          ])))
        else
          Expanded(child: RefreshIndicator(
            color: C.primary,
            onRefresh: () async => bp.load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: bp.bills.length,
              separatorBuilder: (_, __) => const Gap(8),
              itemBuilder: (ctx, i) {
                final bill = bp.bills[i];
                return _ReportBillCard(bill: bill, lang: _lang, cur: _cur,
                  onDelete: () => _confirmDelete(ctx, bp, bill))
                .animate().fadeIn(delay: Duration(milliseconds: i * 30));
              }),
          )),
      ]),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, BillsProvider bp, Bill bill) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isTA ? 'நீக்கவா?' : 'Delete?',
            style: const TextStyle(color: C.text)),
        content: Text('${bill.displayBillNo}\n$_cur${bill.total.toStringAsFixed(2)}',
            style: const TextStyle(color: C.textSub)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: C.red, fontWeight: FontWeight.w700))),
        ]));
    if (ok == true && ctx.mounted) bp.deleteBill(bill.id!);
  }
}

class _SumItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SumItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(
      fontSize: 18, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: const TextStyle(fontSize: 10, color: C.textSub)),
  ]);
}

class _ReportBillCard extends StatelessWidget {
  final Bill bill;
  final String lang, cur;
  final VoidCallback onDelete;
  const _ReportBillCard({required this.bill, required this.lang,
      required this.cur, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yy · hh:mm a');
    final date = df.format(DateTime.fromMillisecondsSinceEpoch(bill.createdAt));
    final synced = bill.synced;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        // Status icon
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: (synced ? C.green : C.orange).withOpacity(.1),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(synced ? Icons.cloud_done_rounded : Icons.schedule_rounded,
              color: synced ? C.green : C.orange, size: 20)),
        const Gap(12),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(bill.displayBillNo, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: synced ? C.green : C.orange)),
          const Gap(2),
          Text(bill.customerName.isNotEmpty ? bill.customerName
              : (lang == 'ta' ? 'Walk-in' : 'Walk-in Customer'),
            style: const TextStyle(fontSize: 12, color: C.textSub)),
          const Gap(2),
          Text(date, style: const TextStyle(fontSize: 10, color: C.textMuted)),
        ])),

        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$cur${bill.total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.text)),
          const Gap(4),
          Text(bill.paymentMethod.toUpperCase(),
            style: const TextStyle(fontSize: 10, color: C.textSub)),
          const Gap(4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline, color: C.red, size: 18)),
        ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════
// SYNC SCREEN
// ═══════════════════════════════════════════════════
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});
  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _lang = 'en', _cur = '₹';

  @override
  void initState() {
    super.initState();
    SessionManager.instance.lang.then((l) { if (mounted) setState(() => _lang=l); });
    SessionManager.instance.currency.then((c) { if (mounted) setState(() => _cur=c); });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillsProvider>().load();
    });
  }

  bool get isTA => _lang == 'ta';
  String t(String en, String ta) => isTA ? ta : en;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer2<BillsProvider, ConnectivityProvider>(
      builder: (_, bp, cp, __) => RefreshIndicator(
        color: C.primary,
        onRefresh: () async => bp.load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [

            // Network status card
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: (cp.isOnline ? C.green : C.red).withOpacity(.1),
                    shape: BoxShape.circle),
                  child: Icon(cp.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                    color: cp.isOnline ? C.green : C.red, size: 22)),
                const Gap(12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cp.isOnline ? t('Connected', 'இணைக்கப்பட்டது')
                      : t('Offline', 'Offline'),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: cp.isOnline ? C.green : C.red)),
                  Text(cp.isOnline ? t('Internet is available', 'Internet உள்ளது')
                      : t('No internet connection', 'Internet இல்லை'),
                    style: const TextStyle(fontSize: 12, color: C.textSub)),
                ])),
                if (cp.isOnline && bp.pendingCount > 0)
                  GestureDetector(
                    onTap: bp.syncing ? null : bp.sync,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: C.gradGreen, borderRadius: BorderRadius.circular(10)),
                      child: Text(t('Sync', 'Sync'),
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w600, fontSize: 13)))),
              ]),
            )
            .animate().fadeIn(),
            const Gap(12),

            // Stats row
            Row(children: [
              Expanded(child: _SyncStatBox(
                label: t('Pending', 'Pending'),
                value: '${bp.pendingCount}',
                icon: Icons.schedule_rounded, color: C.orange)),
              const Gap(10),
              Expanded(child: _SyncStatBox(
                label: t('Synced', 'Synced'),
                value: '${bp.bills.where((b) => b.synced).length}',
                icon: Icons.cloud_done_rounded, color: C.green)),
              const Gap(10),
              Expanded(child: _SyncStatBox(
                label: t('Total', 'மொத்தம்'),
                value: '${bp.bills.length}',
                icon: Icons.receipt_rounded, color: C.primary)),
            ])
            .animate().fadeIn(delay: 100.ms),
            const Gap(20),

            // Main sync button
            PrimaryButton(
              label: bp.syncing
                ? t('Syncing...', 'Sync ஆகிறது...')
                : bp.pendingCount == 0
                  ? t('All Synced ✅', 'எல்லாம் Sync ✅')
                  : t('Sync ${bp.pendingCount} Bills', '${bp.pendingCount} பில்கள் Sync'),
              loading: bp.syncing,
              gradient: bp.pendingCount > 0 ? C.gradGreen : null,
              icon: Icons.cloud_upload_rounded,
              onTap: (!cp.isOnline || bp.syncing || bp.pendingCount == 0) ? null : bp.sync,
            )
            .animate().fadeIn(delay: 200.ms),
            const Gap(10),

            // Clear synced
            if (bp.bills.any((b) => b.synced))
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    for (final b in bp.bills.where((b) => b.synced).toList()) {
                      await bp.deleteBill(b.id!);
                    }
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: Text(t('Clear Synced Bills', 'Synced பில்கள் நீக்கு')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.textSub,
                    side: const BorderSide(color: C.border),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)))))
              .animate().fadeIn(delay: 300.ms),

            const Gap(20),

            // Pending list
            if (bp.pendingCount > 0) ...[
              Align(alignment: Alignment.centerLeft,
                child: Text(t('Pending Bills', 'Sync ஆகாத பில்கள்'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: C.textSub))),
              const Gap(8),
              ...bp.bills.where((b) => !b.synced).take(10).toList().asMap().entries.map((e) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _PendingBillRow(bill: e.value, cur: _cur))
                .animate().fadeIn(delay: Duration(milliseconds: 400 + e.key * 50))),
            ],
          ]),
        ),
      ),
    );
  }
}

class _SyncStatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SyncStatBox({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Column(children: [
      Icon(icon, color: color, size: 22),
      const Gap(6),
      Text(value, style: TextStyle(
        fontSize: 26, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: C.textSub)),
    ]));
}

class _PendingBillRow extends StatelessWidget {
  final Bill bill;
  final String cur;
  const _PendingBillRow({required this.bill, required this.cur});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      Container(width: 8, height: 8,
        decoration: const BoxDecoration(color: C.orange, shape: BoxShape.circle)),
      const Gap(10),
      Expanded(child: Text(bill.offlineId,
        style: const TextStyle(fontSize: 12, color: C.text))),
      Text('$cur${bill.total.toStringAsFixed(2)}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.orange)),
    ]));
}


