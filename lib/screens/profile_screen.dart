import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'
    show
        CupertinoActionSheet,
        CupertinoActionSheetAction,
        CupertinoAlertDialog,
        CupertinoDialogAction,
        CupertinoIcons,
        CupertinoListSection,
        CupertinoListTile,
        CupertinoListTileChevron,
        showCupertinoModalPopup,
        showCupertinoDialog;

import '../core/constants.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../widgets/icon_badge.dart';

/// Profil / sozlamalar ekrani — iOS Settings ilovasidagi "inset grouped"
/// ro'yxat uslubida (Flutter'ning `cupertino.dart` paketidagi
/// `CupertinoListSection`/`CupertinoListTile` orqali). Faqat shu ekran iOS
/// uslubida — qolgan ekranlar (Home/Apartments/Finance) va umumiy ilova
/// qobig'i (AppBar, pastki navigatsiya) avvalgidek Material bo'lib qoladi.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onSupport,
    required this.onVideos,
    required this.onPromotion,
  });

  final Profile profile;
  final VoidCallback onSupport;
  final VoidCallback onVideos;
  final VoidCallback onPromotion;

  @override
  Widget build(BuildContext context) {
    final total = profile.phpInvest + profile.primeCapital;
    final lang = LangScope.of(context);

    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ProfileHeaderCard(profile: profile),
        ),
        const SizedBox(height: 24),
        CupertinoListSection.insetGrouped(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            CupertinoListTile(
              leading: PrimeIconBadgeSolid(icon: CupertinoIcons.globe, color: PrimeColors.blue),
              title: Text(t(context, 'wa.profile.language')),
              additionalInfo: Text(lang.locale.label, style: const TextStyle(color: PrimeColors.slate)),
              trailing: const CupertinoListTileChevron(),
              onTap: () => _showLanguageSheet(context, lang),
            ),
          ],
        ),
        const SizedBox(height: 24),
        CupertinoListSection.insetGrouped(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            CupertinoListTile(
              leading: PrimeIconBadgeSolid(icon: CupertinoIcons.person_crop_circle, color: PrimeColors.slate),
              title: Text(t(context, 'wa.profile.myInfo')),
              subtitle: (profile.phone != null && profile.phone!.isNotEmpty) ? Text(profile.phone!) : null,
            ),
            CupertinoListTile(
              leading: PrimeIconBadgeSolid(icon: CupertinoIcons.headphones, color: PrimeColors.cyan),
              title: Text(t(context, 'wa.support.title')),
              trailing: const CupertinoListTileChevron(),
              onTap: onSupport,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionHeader(text: t(context, 'wa.profile.myAssets')),
        CupertinoListSection.insetGrouped(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            CupertinoListTile(
              leading: PrimeIconBadgeSolid(icon: CupertinoIcons.building_2_fill, color: PrimeColors.blue),
              title: Text('Prime Capital'),
              additionalInfo: Text(formatUsd(profile.primeCapital), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            CupertinoListTile(
              leading: PrimeIconBadgeSolid(icon: CupertinoIcons.money_dollar_circle_fill, color: PrimeColors.cyan),
              title: const Text('PHP Invest'),
              additionalInfo: Text(formatUsd(profile.phpInvest), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 16, 0),
          child: Text(
            '${t(context, 'wa.profile.totalBalance')}: ${formatUsd(total)}',
            style: const TextStyle(color: PrimeColors.slate, fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),
        CupertinoListSection.insetGrouped(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            CupertinoListTile(
              leading: PrimeIconBadgeSolid(icon: CupertinoIcons.play_circle_fill, color: PrimeColors.blue),
              title: Text(t(context, 'wa.videos.title')),
              trailing: const CupertinoListTileChevron(),
              onTap: onVideos,
            ),
            CupertinoListTile(
              leading: PrimeIconBadgeSolid(icon: CupertinoIcons.speaker_2_fill, color: PrimeColors.positive),
              title: Text(t(context, 'wa.promotion.title')),
              trailing: const CupertinoListTileChevron(),
              onTap: onPromotion,
            ),
          ],
        ),
        const SizedBox(height: 24),
        CupertinoListSection.insetGrouped(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            CupertinoListTile(
              title: Center(
                child: Text(
                  t(context, 'wa.nav.logout'),
                  style: const TextStyle(color: PrimeColors.negative, fontWeight: FontWeight.w600),
                ),
              ),
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showLanguageSheet(BuildContext context, LangController lang) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(t(context, 'wa.profile.language')),
        actions: [
          for (final locale in AppLocale.values)
            CupertinoActionSheetAction(
              onPressed: () {
                lang.setLocale(locale);
                Navigator.of(sheetContext).pop();
              },
              isDefaultAction: locale == lang.locale,
              child: Text(locale.label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: Text(t(context, 'wa.finance.cancel')),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final session = SessionScope.of(context);
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(t(context, 'wa.nav.logout')),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t(context, 'wa.finance.cancel')),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              session.logout();
            },
            child: Text(t(context, 'wa.nav.logout')),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PrimeColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: PrimeColors.softShadow(),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: PrimeColors.blue.withOpacity(0.12),
          backgroundImage: profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
          child: profile.photoUrl == null ? const Icon(Icons.person_rounded, color: PrimeColors.blue, size: 28) : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              Text(profile.email, style: const TextStyle(color: PrimeColors.slate, fontSize: 13)),
            ],
          ),
        ),
      ]),
    );
  }
}

/// iOS Settings'dagi kabi guruh nomi: kichik, kulrang, katta harflar bilan,
/// chapdan bir oz kirim bilan — CupertinoListSection'ning o'z `header`
/// parametri o'rniga alohida qo'yilgan, chunki bu yerda u bitta bo'limga
/// emas, "Mening mulklarim" nomini yuqoridagi bo'sh joyga chiqarish uchun.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(color: PrimeColors.slate, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    );
  }
}
