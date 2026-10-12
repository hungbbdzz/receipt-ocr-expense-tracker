import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/charts.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  Widget _card(BuildContext context, String title, Widget child) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();
    final donut = _card(context, 'Chi tiêu theo danh mục',
        CategoryDonutChart(data: p.totalsByCategory));
    final bar = _card(context, '7 ngày gần nhất', WeeklyBarChart(data: p.last7Days));

    return LayoutBuilder(builder: (_, c) {
      final wide = c.maxWidth > 700; // man hinh ngang / tablet
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        child: wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: donut),
                const SizedBox(width: 16),
                Expanded(child: bar),
              ])
            : Column(children: [donut, const SizedBox(height: 16), bar]),
      );
    });
  }
}
