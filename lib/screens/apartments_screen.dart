import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/models.dart';

class ApartmentsScreen extends StatelessWidget {
  const ApartmentsScreen({super.key, required this.properties, required this.loading, required this.onRefresh});

  final List<PropertyListing> properties;
  final bool loading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t(context, 'wa.apartments.title'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(t(context, 'wa.apartments.subtitle'), style: const TextStyle(color: PrimeColors.slate, fontSize: 13)),
                ],
              ),
            ),
          ),
          if (loading && properties.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (properties.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(t(context, 'wa.apartments.empty'), style: const TextStyle(color: PrimeColors.slate))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i.isOdd) return const SizedBox(height: 12);
                    return _ApartmentRow(item: properties[i ~/ 2]);
                  },
                  childCount: properties.isEmpty ? 0 : properties.length * 2 - 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ApartmentRow extends StatelessWidget {
  const _ApartmentRow({required this.item});
  final PropertyListing item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 96,
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [PrimeColors.blue, PrimeColors.cyan])),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.isNewBuild ? t(context, 'wa.apartments.newBuild') : t(context, 'wa.apartments.secondary'),
                    style: const TextStyle(fontSize: 10.5, color: PrimeColors.blue, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 13, color: PrimeColors.slate),
                    const SizedBox(width: 3),
                    Expanded(child: Text(item.location, style: const TextStyle(fontSize: 12, color: PrimeColors.slate), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text(formatUsd(item.price), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    if (item.rooms > 0) ...[
                      const SizedBox(width: 10),
                      Text('${item.rooms} xona', style: const TextStyle(fontSize: 12, color: PrimeColors.slate)),
                    ],
                    if (item.area > 0) ...[
                      const SizedBox(width: 10),
                      Text('${item.area.toStringAsFixed(0)} m²', style: const TextStyle(fontSize: 12, color: PrimeColors.slate)),
                    ],
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
