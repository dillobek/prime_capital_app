import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/models.dart';
import '../widgets/icon_badge.dart';
import '../widgets/income_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.loading,
    required this.balances,
    required this.properties,
    required this.banners,
    required this.onRefresh,
    required this.onInvest,
    required this.onWithdraw,
    required this.onSupport,
    required this.onVideos,
    required this.onSeeApartments,
  });

  final bool loading;
  final List<Balance> balances;
  final List<PropertyListing> properties;
  final List<ContentItem> banners;
  final Future<void> Function() onRefresh;
  final VoidCallback onInvest;
  final VoidCallback onWithdraw;
  final VoidCallback onSupport;
  final VoidCallback onVideos;
  final VoidCallback onSeeApartments;

  @override
  Widget build(BuildContext context) {
    if (loading && balances.every((b) => b.amount == 0) && properties.isEmpty && banners.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final hero = banners.isNotEmpty ? banners.first : null;
    final restBanners = banners.length > 1 ? banners.sublist(1) : const <ContentItem>[];
    final latest = properties.take(3).toList();

    final quickItems = [
      (Icons.add_circle_outline_rounded, t(context, 'wa.quick.invest'), onInvest),
      (Icons.play_circle_outline_rounded, t(context, 'wa.quick.videos'), onVideos),
      (Icons.headset_mic_outlined, t(context, 'wa.quick.support'), onSupport),
      (Icons.account_balance_wallet_outlined, t(context, 'wa.quick.withdrawFull'), onWithdraw),
    ];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _HeroCard(item: hero),
          if (restBanners.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: restBanners.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _BannerChip(item: restBanners[index]),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _BalanceCard(balance: balances.isNotEmpty ? balances[0] : null, icon: Icons.apartment_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _BalanceCard(balance: balances.length > 1 ? balances[1] : null, icon: Icons.account_balance_rounded, cyan: true)),
          ]),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            children: [for (final item in quickItems) _QuickAction(icon: item.$1, label: item.$2, onTap: item.$3)],
          ),
          const SizedBox(height: 16),
          IncomeChartCard(balances: balances),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t(context, 'wa.home.newBuildings'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              TextButton(onPressed: onSeeApartments, child: Text('${t(context, 'wa.home.viewAll')} →')),
            ],
          ),
          if (latest.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(t(context, 'wa.apartments.empty'), style: const TextStyle(color: PrimeColors.slate))),
            )
          else
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: latest.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _PropertyCard(item: latest[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.item});
  final ContentItem? item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: PrimeColors.softShadow(blur: 32, y: 16, opacity: 0.14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: item?.imageUrl != null
                  ? Image.network(item!.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _heroFallback())
                  : _heroFallback(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    stops: const [0.35, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item?.title ?? t(context, 'wa.hero.default.title'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item?.description ?? t(context, 'wa.hero.default.subtitle'),
                    style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroFallback() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [PrimeColors.blueDeep, PrimeColors.blue, PrimeColors.cyan],
          ),
        ),
      );
}

class _BannerChip extends StatelessWidget {
  const _BannerChip({required this.item});
  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PrimeColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: PrimeColors.softShadow(blur: 20, y: 8),
      ),
      child: Row(children: [
        if (item.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(item.imageUrl!, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 48, height: 48)),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              if (item.description != null)
                Text(item.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: PrimeColors.slate)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.icon, this.cyan = false});
  final Balance? balance;
  final IconData icon;
  final bool cyan;

  @override
  Widget build(BuildContext context) {
    final amount = balance?.amount ?? 0;
    final change = balance?.monthlyChange ?? 0;
    // Uch holat: manfiy (qizil, pastga), musbat (yashil, tepaga), va aynan
    // 0% — bu "o'sish" ham, "tushish" ham emas, shuning uchun neytral
    // (kulrang, to'g'ri chiziq) ko'rsatiladi — avval 0% ham "musbat/yashil
    // yuqoriga" deb ko'rsatilar edi, bu chalg'ituvchi edi.
    final negative = change < 0;
    final positive = change > 0;
    final trendColor = negative ? PrimeColors.negative : (positive ? PrimeColors.positive : PrimeColors.slate);
    final trendIcon = negative
        ? Icons.trending_down_rounded
        : (positive ? Icons.trending_up_rounded : Icons.trending_flat_rounded);
    final accent = cyan ? PrimeColors.cyan : PrimeColors.blue;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PrimeIconBadge(icon: icon, color: accent, size: 38, iconSize: 19),
            const SizedBox(height: 12),
            Text(balance?.name ?? '—', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            Text(t(context, 'wa.balances.accountNumber'), style: const TextStyle(fontSize: 11, color: PrimeColors.slate)),
            const SizedBox(height: 7),
            Text(formatUsd(amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3)),
            const SizedBox(height: 5),
            Row(children: [
              Text('${t(context, 'wa.balances.monthlyChange')} ', style: const TextStyle(fontSize: 11, color: PrimeColors.slate)),
              Icon(trendIcon, size: 13, color: trendColor),
              const SizedBox(width: 1),
              Text(
                '${positive ? '+' : ''}$change%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: trendColor),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimeIconBadge(icon: icon, color: PrimeColors.blue, size: 54, iconSize: 23),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: PrimeColors.ink),
          ),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.item});
  final PropertyListing item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: DecoratedBox(decoration: const BoxDecoration(gradient: LinearGradient(colors: [PrimeColors.blue, PrimeColors.cyan]))),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: PrimeColors.softShadow(blur: 10, y: 3, opacity: 0.12),
                  ),
                  child: Text(t(context, 'wa.home.newBadge'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: PrimeColors.blue)),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 12, color: PrimeColors.slate),
                    const SizedBox(width: 2),
                    Expanded(child: Text(item.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: PrimeColors.slate))),
                  ]),
                  const SizedBox(height: 4),
                  Text(formatUsd(item.price), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
