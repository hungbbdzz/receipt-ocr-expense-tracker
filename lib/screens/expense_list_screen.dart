import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/expense_db.dart';
import '../providers/expense_provider.dart';
import '../utils/format.dart';
import '../widgets/charts.dart';
import 'review_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});
  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  DateTimeRange? _range;

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _range,
    );
    if (r == null || !mounted) return;
    setState(() => _range = r);
    context.read<ExpenseProvider>().setFilter(range: r);
  }

  void _clearRange() {
    setState(() => _range = null);
    context.read<ExpenseProvider>().setFilter(clearRange: true);
  }

  Future<bool> _confirmDelete(Expense e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa giao dịch?'),
        content: Text('${e.merchant} - ${formatVnd(e.total)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm theo cửa hàng',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => p.setFilter(search: v),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Lọc theo ngày',
            icon: const Icon(Icons.date_range),
            onPressed: _pickRange,
          ),
        ]),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          if (_range != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text('${fmtDate(_range!.start)} - ${fmtDate(_range!.end)}'),
                onDeleted: _clearRange,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Tất cả'),
              selected: p.categoryFilter == null,
              onSelected: (_) => p.setFilter(clearCategory: true),
            ),
          ),
          for (final c in ExpenseCategory.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c.label),
                selected: p.categoryFilter == c,
                onSelected: (_) => p.setFilter(category: c),
              ),
            ),
        ]),
      ),
      Expanded(
        child: p.items.isEmpty
            ? const Center(child: Text('Chưa có giao dịch nào'))
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: p.items.length,
                itemBuilder: (_, i) {
                  final e = p.items[i];
                  return Dismissible(
                    key: ValueKey(e.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(e),
                    onDismissed: (_) => p.remove(e.id!),
                    background: Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete),
                    ),
                    child: ListTile(
                      leading: _thumb(e),
                      title: Text(e.merchant, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${e.category.label} - ${fmtDate(e.date)}'),
                      trailing: Text(formatVnd(e.total),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReviewScreen(existing: e)),
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _thumb(Expense e) {
    final color = categoryColors[e.category]!;
    final path = e.imagePath;
    if (path != null && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          cacheWidth: 120,
          cacheHeight: 120,
        ),
      );
    }
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(Icons.receipt_long, color: color),
    );
  }
}
