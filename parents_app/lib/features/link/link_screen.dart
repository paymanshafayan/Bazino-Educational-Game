import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/session.dart';

/// کد خانواده: والد کد می‌گیرد ← فرزند در کلاینت بازی «links/accept» وارد می‌کند.
class LinkScreen extends StatefulWidget {
  const LinkScreen({super.key});

  @override
  State<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  String _code = '';
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final c = await Session.I.api.createFamilyCode();
    if (mounted) setState(() => _code = c);
    _poll = Timer.periodic(const Duration(seconds: 3), (_) async {
      await Session.I.refreshLinks();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اتصال خانواده')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'این کد را در بازی (صفحهٔ خوش‌آمد ← «اتصال خانواده») وارد کنید تا حساب فرزند به داشبورد شما متصل شود.',
                textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (_code.isEmpty)
                const CircularProgressIndicator()
              else ...[
                QrImageView(
                  data: 'BZ-FAMILY:$_code',
                  size: 180,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(_code,
                    style: const TextStyle(
                        fontSize: 42,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9DFF70))),
                const SizedBox(height: 16),
                const Text('⏳ منتظر تأیید فرزند…',
                    style: TextStyle(color: Colors.white54)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
