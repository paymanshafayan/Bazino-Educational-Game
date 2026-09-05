import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/models.dart';
import '../../core/session.dart';

/// کیف پول — D11: شارژ اصلی **حضوری** در گیم‌نت؛ درگاه آنلاین «به‌زودی» (غیرفعال).
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pid = Session.I.parentId ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('کیف پول')),
      body: FutureBuilder<Wallet>(
        future: Session.I.api.wallet(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('خطا: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final w = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('مانده'),
                      Text('${w.liras.toStringAsFixed(2)} ₺',
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9DFF70))),
                      const SizedBox(height: 8),
                      const Text('برای شارژ: به گیم‌نت مراجعه و این کد را به پرسنل نشان دهید',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      QrImageView(
                        data: 'BZ-TOPUP:$pid',
                        size: 150,
                        backgroundColor: Colors.white,
                      ),
                      TextButton.icon(
                        onPressed: null, // فاز بعد: İktisat Cardplus / Near East
                        icon: const Icon(Icons.credit_card_off),
                        label: const Text('پرداخت آنلاین — به‌زودی (در انتظار تایید بانک)'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('تاریخچه', style: TextStyle(fontSize: 16)),
              ...w.history.map(_txTile),
            ],
          );
        },
      ),
    );
  }

  Widget _txTile(WalletTx t) {
    final plus = t.amountKurus >= 0;
    return ListTile(
      dense: true,
      leading: Icon(plus ? Icons.add_circle : Icons.remove_circle,
          color: plus ? Colors.greenAccent : Colors.redAccent),
      title: Text('${t.liras.toStringAsFixed(2)} ₺ — ${_txName(t.type)}'),
      subtitle: Text('${t.refCode}  ${t.note}',
          style: const TextStyle(fontSize: 11)),
    );
  }

  String _txName(String t) => switch (t) {
        'topup_cash' => 'شارژ حضوری',
        'spend_stage' => 'بازکردن مرحله',
        'reward_redeem' => 'جایزه',
        _ => t,
      };
}
