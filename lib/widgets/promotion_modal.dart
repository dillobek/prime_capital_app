import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';
import '../core/i18n.dart';
import '../core/session.dart';
import 'modal_sheet.dart';

/// "Report an investment" — the user submits proof (screenshots/receipts)
/// of money they sent outside the app; an admin reviews `/promotion-reports`
/// and tops up the matching balance manually. Images are downsized by
/// image_picker itself (maxWidth/imageQuality) before being base64-encoded,
/// mirroring the client-side compression Webapp does with a canvas.
class PromotionModal extends StatefulWidget {
  const PromotionModal({super.key});

  @override
  State<PromotionModal> createState() => _PromotionModalState();
}

class _PromotionModalState extends State<PromotionModal> {
  final _phpCtrl = TextEditingController();
  final _primeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final List<XFile> _images = [];
  bool _submitting = false;
  bool _done = false;
  String? _status;

  @override
  void dispose() {
    _phpCtrl.dispose();
    _primeCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 80, maxWidth: 1600);
      if (picked.isEmpty) return;
      setState(() {
        _images.addAll(picked);
        if (_images.length > 5) _images.removeRange(5, _images.length);
      });
    } catch (_) {
      // Picker cancelled or permission denied — nothing to do.
    }
  }

  Future<void> _submit() async {
    if (_images.isEmpty || _images.length > 5) {
      setState(() => _status = t(context, 'wa.promotion.validationImages'));
      return;
    }
    final phpAmount = double.tryParse(_phpCtrl.text.replaceAll(',', '.')) ?? 0;
    final primeAmount = double.tryParse(_primeCtrl.text.replaceAll(',', '.')) ?? 0;
    if (phpAmount <= 0 && primeAmount <= 0) {
      setState(() => _status = t(context, 'wa.promotion.validationAmount'));
      return;
    }
    if (_descriptionCtrl.text.trim().isEmpty) return;

    setState(() {
      _submitting = true;
      _status = t(context, 'wa.promotion.preparing');
    });
    try {
      final encoded = <String>[];
      for (final image in _images) {
        final bytes = await image.readAsBytes();
        encoded.add('data:image/jpeg;base64,${base64Encode(bytes)}');
      }
      await SessionScope.of(context).api.createPromotionReport(
            phpInvestAmount: phpAmount > 0 ? phpAmount : null,
            primeCapitalAmount: primeAmount > 0 ? primeAmount : null,
            description: _descriptionCtrl.text.trim(),
            images: encoded,
          );
      if (mounted) {
        setState(() {
          _done = true;
          _status = t(context, 'wa.promotion.success');
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalSheet(
      title: t(context, 'wa.promotion.title'),
      child: _done
          ? Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(_status ?? '', style: const TextStyle(fontSize: 14)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t(context, 'wa.promotion.subtitle'), style: const TextStyle(fontSize: 13, color: PrimeColors.slate)),
                const SizedBox(height: 14),
                Text(t(context, 'wa.promotion.phpAmount'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: _phpCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 14),
                Text(t(context, 'wa.promotion.primeAmount'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: _primeCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 14),
                Text(t(context, 'wa.promotion.description'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: _descriptionCtrl, maxLines: 3),
                const SizedBox(height: 14),
                Text(t(context, 'wa.promotion.images'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    _images.isEmpty ? t(context, 'wa.promotion.pickImages') : '${_images.length} ${t(context, 'wa.promotion.imagesSelected')}',
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(t(context, 'wa.promotion.submit')),
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
