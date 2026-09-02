import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/i18n.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../widgets/money_modal.dart';
import '../widgets/notifications_panel.dart';
import '../widgets/prime_logo.dart';
import '../widgets/promotion_modal.dart';
import '../widgets/support_modal.dart';
import '../widgets/videos_modal.dart';
import 'apartments_screen.dart';
import 'finance_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// The signed-in app shell: top bar (logo + notifications bell), the four
/// tabs (Home / Apartments / Finance / Profile) and the bottom nav — mirrors
/// the layout `WebApp()` renders once a profile is loaded.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _tabIndex = 0;
  List<Balance> _balances = [];
  List<PropertyListing> _properties = [];
  List<ContentItem> _banners = [];
  List<ContentItem> _videos = [];
  List<ContentItem> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Deferred to right after the first frame: SessionScope.of(context) (an
    // InheritedWidget lookup) isn't allowed to run synchronously inside
    // initState().
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHome());
  }

  Future<void> _loadHome() async {
    final session = SessionScope.of(context);
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        session.api.getBalances(),
        session.api.getProperties(status: 'active'),
        session.api.getBanners(),
        session.api.getVideos(),
      ]);
      if (!mounted) return;
      setState(() {
        _balances = results[0] as List<Balance>;
        _properties = results[1] as List<PropertyListing>;
        _banners = results[2] as List<ContentItem>;
        _videos = results[3] as List<ContentItem>;
      });
      _loadNotifications();
    } catch (_) {
      // Honest empty state on failure — same fallback approach as Webapp's safeFetch.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadNotifications() async {
    final session = SessionScope.of(context);
    try {
      final items = await session.api.getNotifications();
      if (mounted) setState(() => _notifications = items);
    } catch (_) {
      /* leave whatever was loaded before */
    }
  }

  void _openMoneyModal(String action) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MoneyModal(action: action),
    );
  }

  void _openSupportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SupportModal(),
    );
  }

  void _openVideosModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VideosModal(items: _videos),
    );
  }

  void _openPromotionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PromotionModal(),
    );
  }

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationsPanel(items: _notifications),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final profile = session.profile!;
    final myBalances = <Balance>[
      Balance(
        id: kProductPrimeCapital,
        name: 'Prime Capital',
        amount: profile.primeCapital,
        monthlyChange: _percentFor(kProductPrimeCapital),
        updatedAt: DateTime.now().toIso8601String(),
      ),
      Balance(
        id: kProductPhpInvest,
        name: 'PHP Invest',
        amount: profile.phpInvest,
        monthlyChange: _percentFor(kProductPhpInvest),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    ];

    final tabs = <Widget>[
      HomeScreen(
        loading: _loading,
        balances: myBalances,
        properties: _properties,
        banners: _banners,
        onRefresh: _loadHome,
        onInvest: () => _openMoneyModal('investments'),
        onWithdraw: () => _openMoneyModal('withdrawals'),
        onSupport: _openSupportModal,
        onVideos: _openVideosModal,
        onSeeApartments: () => setState(() => _tabIndex = 1),
      ),
      ApartmentsScreen(properties: _properties, loading: _loading, onRefresh: _loadHome),
      const FinanceScreen(),
      ProfileScreen(
        profile: profile,
        onSupport: _openSupportModal,
        onVideos: _openVideosModal,
        onPromotion: _openPromotionModal,
      ),
    ];

    final navItems = [
      (Icons.home_rounded, t(context, 'wa.nav.home')),
      (Icons.apartment_rounded, t(context, 'wa.nav.apartments')),
      (Icons.account_balance_wallet_rounded, t(context, 'wa.nav.finance')),
      (Icons.person_rounded, t(context, 'wa.nav.profile')),
    ];

    return Scaffold(
      backgroundColor: PrimeColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const PrimeLogo(compact: true),
        actions: [
          InkWell(
            onTap: _openNotifications,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: PrimeColors.card, borderRadius: BorderRadius.circular(20), boxShadow: PrimeColors.softShadow(blur: 14, y: 4)),
              child: Badge(
                isLabelVisible: _notifications.isNotEmpty,
                smallSize: 9,
                backgroundColor: PrimeColors.negative,
                child: const Icon(Icons.notifications_none_rounded, color: PrimeColors.ink, size: 21),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(index: _tabIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: [
          for (final item in navItems) NavigationDestination(icon: Icon(item.$1), label: item.$2),
        ],
      ),
    );
  }

  double _percentFor(String productId) {
    for (final balance in _balances) {
      if (balance.id == productId) return balance.monthlyChange;
    }
    return 0;
  }
}
