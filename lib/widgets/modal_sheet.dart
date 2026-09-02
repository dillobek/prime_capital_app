import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Shared chrome for every bottom-sheet modal in the app (Invest/Withdraw,
/// Support, Videos, Notifications, Promotion report) — rounded top corners,
/// a drag handle, a title row with a close button, and safe-area padding.
class ModalSheet extends StatelessWidget {
  const ModalSheet({super.key, required this.title, required this.child, this.maxHeightFactor = 0.88});

  final String title;
  final Widget child;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * maxHeightFactor),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: PrimeColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [BoxShadow(color: PrimeColors.ink.withOpacity(0.12), blurRadius: 40, offset: const Offset(0, -12))],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: PrimeColors.border, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: -0.2))),
                      InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: PrimeColors.fieldFill, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.close_rounded, size: 18, color: PrimeColors.slate),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Flexible(child: SingleChildScrollView(child: child)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
