import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../core/i18n.dart';
import '../core/models.dart';
import '../core/session.dart';

/// Personal income/expense tracker — always scoped to the signed-in user on
/// the backend (`GET/POST /finance` derive `userId` from the JWT).
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  List<FinanceEntry> _entries = [];
  bool _loading = true;
  bool _showForm = false;
  bool _submitting = false;

  final _categoryCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'expense';

  @override
  void initState() {
    super.initState();
    // Deferred to right after the first frame: SessionScope.of(context) (an
    // InheritedWidget lookup) isn't allowed to run synchronously inside
    // initState().
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final entries = await SessionScope.of(context).api.getFinance();
      if (mounted) setState(() => _entries = entries);
    } catch (_) {
      if (mounted) setState(() => _entries = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (_categoryCtrl.text.trim().isEmpty || amount == null || amount <= 0) return;
    setState(() => _submitting = true);
    try {
      final created = await SessionScope.of(context).api.addFinance(
            type: _type,
            category: _categoryCtrl.text.trim(),
            amount: amount,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
      if (mounted) {
        setState(() {
          _entries = [created, ..._entries];
          _showForm = false;
          _categoryCtrl.clear();
          _amountCtrl.clear();
          _noteCtrl.clear();
        });
      }
    } catch (_) {
      // Form stays open on failure, matching Webapp's behaviour.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _remove(FinanceEntry entry) async {
    final previous = _entries;
    setState(() => _entries = _entries.where((e) => e.id != entry.id).toList());
    try {
      await SessionScope.of(context).api.removeFinance(entry.id);
    } catch (_) {
      if (mounted) setState(() => _entries = previous);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _entries.fold<double>(0, (sum, e) => sum + (e.type == 'income' ? e.amount : -e.amount));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(t(context, 'wa.nav.finance'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 4),
          Text(t(context, 'wa.finance.subtitle'), style: const TextStyle(color: PrimeColors.slate, fontSize: 13)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t(context, 'wa.finance.currentBalance'), style: const TextStyle(fontSize: 12, color: PrimeColors.slate)),
                        const SizedBox(height: 4),
                        Text("${formatMoney(total)} so'm", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => setState(() => _showForm = !_showForm),
                    child: Text(_showForm ? t(context, 'wa.finance.cancel') : t(context, 'wa.finance.addExpense')),
                  ),
                ],
              ),
            ),
          ),
          if (_showForm) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'income', label: Text(t(context, 'wa.finance.income'))),
                        ButtonSegment(value: 'expense', label: Text(t(context, 'wa.finance.expense'))),
                      ],
                      selected: {_type},
                      onSelectionChanged: (value) => setState(() => _type = value.first),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _categoryCtrl, decoration: InputDecoration(hintText: t(context, 'wa.finance.category'))),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(hintText: t(context, 'wa.finance.amount')),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: _noteCtrl, decoration: InputDecoration(hintText: t(context, 'wa.finance.note'))),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(t(context, 'wa.finance.save')),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_loading)
            Padding(padding: const EdgeInsets.only(top: 24), child: Center(child: Text(t(context, 'wa.finance.loading'), style: const TextStyle(color: PrimeColors.slate))))
          else if (_entries.isEmpty)
            Padding(padding: const EdgeInsets.only(top: 24), child: Center(child: Text(t(context, 'wa.finance.empty'), style: const TextStyle(color: PrimeColors.slate))))
          else
            ..._entries.map((entry) => _FinanceRow(entry: entry, onDismiss: () => _remove(entry))),
        ],
      ),
    );
  }
}

class _FinanceRow extends StatelessWidget {
  const _FinanceRow({required this.entry, required this.onDismiss});
  final FinanceEntry entry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.type == 'income';
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: PrimeColors.negative, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (isIncome ? PrimeColors.positive : PrimeColors.negative).withOpacity(0.12),
              child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isIncome ? PrimeColors.positive : PrimeColors.negative, size: 18),
            ),
            title: Text(entry.category, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(isIncome ? t(context, 'wa.finance.income') : t(context, 'wa.finance.expense')),
            trailing: Text(
              '${isIncome ? '+' : '-'}${formatMoney(entry.amount)}',
              style: TextStyle(fontWeight: FontWeight.w800, color: isIncome ? PrimeColors.positive : PrimeColors.negative),
            ),
          ),
        ),
      ),
    );
  }
}
