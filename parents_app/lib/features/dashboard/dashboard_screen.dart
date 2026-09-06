import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/theme.dart';

/// داشبورد: تسلط موضوعی هر درس (خروجی «موتور تسلط» سرور — بازیکن نمی‌بیند) +
/// چراغ آمادگی امتحان پایان‌فصل.
class DashboardScreen extends StatelessWidget {
  final int childId;
  const DashboardScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پیشرفت درسی فرزند'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Session.I.logout(),
          )
        ],
      ),
      body: FutureBuilder<MasteryReport>(
        future: Session.I.api.mastery(childId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('خطا در بارگذاری: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rep = snap.data!;
          if (rep.rows.isEmpty) {
            return const Center(
              child: Text(
                'هنوز داده‌ای ثبت نشده.\nفرزند شما وقتی بازی کند، تسلط موضوعی این‌جا روشن می‌شود —'
                ' در خودِ بازی هیچ نمره‌ای دیده نمی‌شود ✦',
                textAlign: TextAlign.center,
              ),
            );
          }
          final by = rep.bySubject();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _readinessBanner(rep.readiness),
              const SizedBox(height: 12),
              ...by.entries.map(_subjectCard),
            ],
          );
        },
      ),
    );
  }

  Widget _readinessBanner(Map<String, String> r) {
    final worst = r.values.contains('red')
        ? 'red'
        : r.values.contains('yellow')
            ? 'yellow'
            : 'green';
    return Card(
      child: ListTile(
        leading: Icon(Icons.flag_circle,
            size: 40, color: BazinoTheme.readinessColor(worst)),
        title: const Text('آمادگی امتحان پایان‌فصل (Güz)'),
        subtitle: Text(BazinoTheme.readinessFa(worst)),
      ),
    );
  }

  Widget _subjectCard(MapEntry<String, List<MasteryRow>> e) {
    final rows = e.value;
    final avg = rows.fold<double>(0, (a, b) => a + b.score) / rows.length;
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: BazinoTheme.readinessColor(
              avg >= 70 ? 'green' : avg >= 40 ? 'yellow' : 'red'),
          child: Text(e.key.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.black)),
        ),
        title: Text(_subjectName(e.key)),
        subtitle: Text('${rows.where((r) => r.mastered).length}/${rows.length}'
            ' موضوع ملکه ذهن · میانگین ${avg.toStringAsFixed(0)}٪'),
        children: rows
            .map((r) => ListTile(
                  dense: true,
                  title: Text(r.nameTr, textDirection: TextDirection.ltr),
                  trailing: SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      value: r.score / 100,
                      backgroundColor: Colors.white12,
                      color: r.mastered
                          ? const Color(0xFF9DFF70)
                          : const Color(0xFFFFD166),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  static String _subjectName(String s) => switch (s) {
        'math' => 'ریاضیات',
        'physics' => 'فیزیک',
        'chemistry' => 'شیمی',
        'biology' => 'زیست‌شناسی',
        'english' => 'انگلیسی',
        'ict' => 'فناوری اطلاعات',
        'logic' => 'ذکا و منطق',
        _ => s,
      };
}
