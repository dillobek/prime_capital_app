import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/i18n.dart';
import '../core/models.dart';
import 'modal_sheet.dart';

class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({super.key, required this.items});
  final List<ContentItem> items;

  @override
  Widget build(BuildContext context) {
    return ModalSheet(
      title: t(context, 'wa.notifications.title'),
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(t(context, 'wa.notifications.empty'), style: const TextStyle(color: PrimeColors.slate))),
            )
          : Column(
              children: [
                for (final item in items) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: item.description != null ? Text(item.description!, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                    onTap: () => _openDetail(context, item),
                  ),
                  const Divider(height: 1),
                ],
              ],
            ),
    );
  }

  void _openDetail(BuildContext context, ContentItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationDetailModal(item: item),
    );
  }
}

class _NotificationDetailModal extends StatelessWidget {
  const _NotificationDetailModal({required this.item});
  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    return ModalSheet(
      title: item.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
            const SizedBox(height: 12),
          ],
          if (item.description != null) Text(item.description!, style: const TextStyle(fontSize: 14)),
          if (item.buttons.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final button in item.buttons)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () {
                    final uri = Uri.tryParse(button.url);
                    if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: Text(button.label),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
