import 'package:flutter/material.dart';

import '../core/i18n.dart';
import '../core/models.dart';
import '../core/session.dart';
import 'modal_sheet.dart';

/// Invest / withdraw request form — posts to `/investments` or
/// `/withdrawals`; the backend always derives `userId` from the JWT and the
/// request lands as `pending` until an admin approves or rejects it.
class MoneyModal extends StatefulWidget {
  const MoneyModal({super.key, required this.action});

  /// 'investments' or 'withdrawals'.
  final String action;

  @override
  State<MoneyModal> createState() => _MoneyModalState();
}

class _MoneyModalState extends State<MoneyModal> {
  String _product = kProductPrimeCapital;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _sending = false;
  bool _done = false;
  String? _status;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;
    setState(() {
      _sending = true;
      _status = t(context, 'wa.money.sending');
    });
    final api = SessionScope.of(context).api;
    try {
      if (widget.action == 'investments') {
        await api.createInvestment(product: _product, amount: amount, note: _noteCtrl.text.trim());
      } else {
        await api.createWithdrawal(product: _product, amount: amount, note: _noteCtrl.text.trim());
      }
      if (mounted) {
        setState(() {
          _done = true;
          _status = t(context, 'wa.money.success');
        });
      }
    } catch (_) {
      if (mounted) setState(() => _status = t(context, 'wa.money.error'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInvest = widget.action == 'investments';
    return ModalSheet(
      title: isInvest ? t(context, 'wa.money.investTitle') : t(context, 'wa.money.withdrawTitle'),
      child: _done
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_status ?? '', style: const TextStyle(fontSize: 14)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                Text(t(context, 'wa.money.direction'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _product,
                  items: const [
                    DropdownMenuItem(value: kProductPrimeCapital, child: Text('Prime Capital')),
                    DropdownMenuItem(value: kProductPhpInvest, child: Text('PHP Invest')),
                  ],
                  onChanged: (value) => setState(() => _product = value ?? kProductPrimeCapital),
                ),
                const SizedBox(height: 14),
                Text(t(context, 'wa.money.title'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: _amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 14),
                Text(t(context, 'wa.money.note'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: _noteCtrl),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _sending ? null : _submit,
                  child: Text(t(context, 'wa.money.send')),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 8),
                  Text(_status!, style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
    );
  }
}
