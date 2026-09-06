/// مدل‌های دادهٔ اپ والدین — منطبق با قرارداد API بک‌اند (فاز ۲).
class MasteryRow {
  final String topicId;
  final String subject;
  final String nameTr;
  final double score;
  final bool mastered;
  final int evidence;

  MasteryRow.fromJson(Map<String, dynamic> j)
      : topicId = j['topic_id'] as String,
        subject = j['subject'] as String,
        nameTr = j['name_tr'] as String,
        score = (j['score'] as num).toDouble(),
        mastered = j['mastered'] as bool,
        evidence = (j['evidence'] as num).toInt();
}

class MasteryReport {
  final List<MasteryRow> rows;
  final Map<String, String> readiness;

  MasteryReport.fromJson(Map<String, dynamic> j)
      : rows = (j['rows'] as List)
            .map((e) => MasteryRow.fromJson(e as Map<String, dynamic>))
            .toList(),
        readiness = Map<String, String>.from(j['exam_readiness'] as Map);

  Map<String, List<MasteryRow>> bySubject() {
    final out = <String, List<MasteryRow>>{};
    for (final r in rows) {
      out.putIfAbsent(r.subject, () => []).add(r);
    }
    return out;
  }
}

class WalletTx {
  final int id;
  final String type;
  final int amountKurus;
  final String refCode;
  final String note;

  WalletTx.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        type = j['type'] as String,
        amountKurus = j['amount_kurus'] as int,
        refCode = (j['ref_code'] ?? '') as String,
        note = (j['note'] ?? '') as String;

  double get liras => amountKurus / 100.0;
}

class Wallet {
  final int balanceKurus;
  final List<WalletTx> history;

  Wallet.fromJson(Map<String, dynamic> j)
      : balanceKurus = j['balance_kurus'] as int,
        history = (j['history'] as List)
            .map((e) => WalletTx.fromJson(e as Map<String, dynamic>))
            .toList();

  double get liras => balanceKurus / 100.0;
}

class FamilyLink {
  final String code;
  final bool active;
  final int? childId;

  FamilyLink.fromJson(Map<String, dynamic> j)
      : code = j['code'] as String,
        active = j['active'] as bool,
        childId = j['child_id'] as int?;
}
