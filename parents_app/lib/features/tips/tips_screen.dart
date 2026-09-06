import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/session.dart';

/// توصیه‌های یاری خانگی — بر پایهٔ موضوعات ضعیف (از موتور تسلط).
/// محتوا بر اساس سندهای research/02–03؛ هر هفته چند فعالیت ۱۰دقیقه‌ای.
class TipsScreen extends StatelessWidget {
  final int childId;
  const TipsScreen({super.key, required this.childId});

  static const _tips = <String, List<String>>{
    'math': [
      '🛒 در فروشگاه: قیمت‌های مشترک ۴ و ۶ پیدا کنید (EKOK) — ۱۰ دقیقه بازی فروشگاهی.',
      '🔢 جدول توان بسازید: 2¹…2⁶ را بخواند و الگو را حدس بزند.',
      '🧮 یک «معادلهٔ جیب» بنویسید (مثلاً 3x−7=11) و x را با حدس/جدول پیدا کنید.',
    ],
    'physics': [
      '⚖️ با پاکت و مداد یک اهرم بسازید؛ جای وزنه را جابه‌جا کنید.',
      '🔦 با چراغ‌قوه آینه: زاویهٔ بازتاب را حدس بزند و ببیند.',
    ],
    'chemistry': [
      '🧪 با جوش‌شیرین و سرکه «کف‌ساز» بسازید؛ دربارهٔ اسید/باز حرف بزنید.',
      '🥤 محلول قند: دانه‌به‌دانه اضافه‌اش کنید و «اشباع» را کشف کند.',
    ],
    'biology': [
      '🌱 یک گیاه در پنجره: هر روز ۱ عکس — چرخهٔ انرژی را توضیح دهد.',
      '🍎 زنجیرهٔ غذایی خانه: چه‌کسی چه‌کسی را می‌خورد؟ کارتی رسم کنید.',
    ],
    'english': [
      '🗣️ Morning! 5 words today — هر روز ۵ واژه از آشپزخانه.',
      '🎧 یک قسمت انیمیشن کوتاه با زیرنویس انگلیسی و سپس تعریف انگلیسی آن.',
    ],
    'ict': [
      '💻 دنبالهٔ دستور صبحانه: الگوریتم صبح‌شنینی بنویسید!',
    ],
    'logic': [
      '🧩 یک پازل ۲۰ تکه، بدون تابلوی راهنما؛ الگوی گوشه‌ها را نام ببرد.',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('یاری خانگی')),
      body: FutureBuilder<MasteryReport>(
        future: Session.I.api.mastery(childId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final weak = snap.data!.rows
              .where((r) => r.score < 70)
              .toList()
            ..sort((a, b) => a.score.compareTo(b.score));
          final subjects = <String>{};
          for (final r in weak.take(3)) {
            subjects.add(r.subject);
          }
          final cards = subjects
              .expand((s) => (_tips[s] ?? []).map((tip) => _tipCard(s, tip)))
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('💪 این هفته روی این موضوعات کار کنید —'
                  ' هر کدام ۱۰ دقیقه، تفریحی و بدون امتحان:',
                  style: TextStyle(fontSize: 15)),
              const SizedBox(height: 12),
              if (cards.isEmpty)
                const Card(
                    child: ListTile(
                        title: Text('همهٔ چراغ‌ها سبزند! 🎉'),
                        subtitle: Text('فعالیت تفریحی آزاد پیشنهاد می‌شود.')))
              else
                ...cards,
            ],
          );
        },
      ),
    );
  }

  Widget _tipCard(String subject, String tip) => Card(
        child: ListTile(
          leading: const Icon(Icons.lightbulb, color: Color(0xFFFFD166)),
          title: Text(tip),
          subtitle: Text('درس: $subject'),
        ),
      );
}
