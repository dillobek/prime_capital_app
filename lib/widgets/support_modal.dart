import 'package:flutter/material.dart';

import '../core/i18n.dart';
import '../core/session.dart';
import 'modal_sheet.dart';

class SupportModal extends StatefulWidget {
  const SupportModal({super.key});

  @override
  State<SupportModal> createState() => _SupportModalState();
}

class _SupportModalState extends State<SupportModal> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending = false;
  bool _done = false;
  String? _status;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) return;
    setState(() {
      _sending = true;
      _status = t(context, 'wa.money.sending');
    });
    try {
      await SessionScope.of(context).api.createSupport(subject: _subjectCtrl.text.trim(), message: _messageCtrl.text.trim());
      if (mounted) {
        setState(() {
          _done = true;
          _status = t(context, 'wa.support.success');
        });
      }
    } catch (_) {
      if (mounted) setState(() => _status = t(context, 'wa.support.error'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalSheet(
      title: t(context, 'wa.support.title'),
      child: _done
          ? Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(_status ?? '', style: const TextStyle(fontSize: 14)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                Text(t(context, 'wa.support.subject'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: _subjectCtrl),
                const SizedBox(height: 14),
                Text(t(context, 'wa.support.message'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: _messageCtrl, maxLines: 4),
                const SizedBox(height: 18),
                ElevatedButton(onPressed: _sending ? null : _submit, child: Text(t(context, 'wa.support.send'))),
                if (_status != null) ...[
                  const SizedBox(height: 8),
                  Text(_status!, style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
    );
  }
}
