import 'package:bazino_parent/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MasteryRow پارس درست JSON', () {
    final m = MasteryRow.fromJson({
      'topic_id': 'math.g8.guz.uslu',
      'subject': 'math',
      'name_tr': 'Üslü İfadeler',
      'score': 71.5,
      'mastered': true,
      'evidence': 4,
    });
    expect(m.mastered, isTrue);
    expect(m.subject, 'math');
  });

  test('WalletTx پارس', () {
    final t = WalletTx.fromJson({
      'id': 1, 'type': 'topup_cash', 'amount_kurus': 50000,
      'ref_code': 'BZ-AAAA-BBBB', 'note': 'x',
    });
    expect(t.liras, 500.0);
  });
}
