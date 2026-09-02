import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/i18n.dart';
import '../core/models.dart';
import 'icon_badge.dart';
import 'modal_sheet.dart';

class VideosModal extends StatelessWidget {
  const VideosModal({super.key, required this.items});
  final List<ContentItem> items;

  @override
  Widget build(BuildContext context) {
    return ModalSheet(
      title: t(context, 'wa.videos.title'),
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(t(context, 'wa.videos.empty'), style: const TextStyle(color: PrimeColors.slate))),
            )
          : Column(
              children: [
                for (final item in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const PrimeIconBadge(icon: Icons.play_arrow_rounded, color: PrimeColors.blue, size: 44),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: item.description != null ? Text(item.description!) : null,
                    onTap: item.url == null
                        ? null
                        : () {
                            final uri = Uri.tryParse(item.url!);
                            if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                  ),
              ],
            ),
    );
  }
}
