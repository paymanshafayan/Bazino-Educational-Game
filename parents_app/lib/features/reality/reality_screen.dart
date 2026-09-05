import 'package:flutter/material.dart';

import '../../core/session.dart';

/// Reality Bridge — ثبت نمرات واقعی مدرسه ← بوف درون‌بازی (GDD §۱۰/D10).
class RealityScreen extends StatefulWidget {
  final int childId;
  const RealityScreen({super.key, required this.childId});

  @override
  State<RealityScreen> createState() => _RealityScreenState();
}

class _RealityScreenState extends State<RealityScreen> {
  String _subject = 'math';
  double _score = 80;
  String _result = '';
  bool _busy = false;

  static const _subjects = [
    ['math', 'ریاضی'],
    ['physics', 'فیزیک'],
    ['chemistry', 'شیمی'],
    ['biology', 'زیست'],
    ['english', 'انگلیسی'],
    ['ict', 'فناوری'],
    ['logic', 'منطق'],
  ];

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _result = '';
    });
    try {
      final j = await Session.I.api
          .submitGrade(widget.childId, _subject, _score);
      setState(() => _result =
          '✔ بوف داده شد: ${j['buff']} × ${j['amount']}  (در بازی فعال است)');
    } catch (e) {
      setState(() => _result = 'خطا: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پل واقعیت')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'نمرهٔ واقعی مدرسه را ثبت کنید؛ در بازی برای فرزندتان انرژی/جان اضافه می‌شود.\n'
            '💡 نمرهٔ با تأیید حضوری کارنامه در گیم‌نت، بوف قوی‌تری دارد!',
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _subject,
            decoration: const InputDecoration(
                labelText: 'درس', border: OutlineInputBorder()),
            items: [
              for (final s in _subjects)
                DropdownMenuItem(value: s[0], child: Text(s[1]))
            ],
            onChanged: (v) => setState(() => _subject = v ?? 'math'),
          ),
          const SizedBox(height: 16),
          Text('نمره (از ۱۰۰): ${_score.round()}'),
          Slider(
            value: _score,
            min: 0,
            max: 100,
            divisions: 20,
            label: '${_score.round()}',
            onChanged: (v) => setState(() => _score = v),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: const Icon(Icons.bolt),
            label: const Text('ثبت و اعطای بوف'),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(child: Padding(
              padding: const EdgeInsets.all(16), child: Text(_result))),
          ],
        ],
      ),
    );
  }
}
