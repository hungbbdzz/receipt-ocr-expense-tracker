import 'package:flutter/material.dart';
import '../data/expense_db.dart';

class ExpenseProvider extends ChangeNotifier {
  final _db = ExpenseDb.instance;

  List<Expense> _items = [];
  ExpenseCategory? _category;
  DateTimeRange? _range;
  String _search = '';
  ThemeMode themeMode = ThemeMode.system;

  List<Expense> get items => _items;
  ExpenseCategory? get categoryFilter => _category;

  Future<void> load() async {
    _items = await _db.query(
      category: _category,
      from: _range?.start,
      to: _range?.end.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)),
      search: _search,
    );
    notifyListeners();
  }

  Future<void> add(Expense e) async {
    await _db.insert(e);
    await load();
  }

  Future<void> update(Expense e) async {
    await _db.update(e);
    await load();
  }

  Future<void> remove(int id) async {
    await _db.delete(id);
    await load();
  }

  Future<void> setFilter({ExpenseCategory? category, DateTimeRange? range, String? search, bool clearCategory = false, bool clearRange = false}) async {
    _category = clearCategory ? null : (category ?? _category);
    _range = clearRange ? null : (range ?? _range);
    _search = search ?? _search;
    await load();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // Du lieu cho chart (tinh tren toan bo danh sach dang hien thi)
  Map<ExpenseCategory, int> get totalsByCategory {
    final m = <ExpenseCategory, int>{};
    for (final e in _items) {
      m[e.category] = (m[e.category] ?? 0) + e.total;
    }
    return m;
  }

  /// 7 ngay gan nhat, index 0 = 6 ngay truoc, index 6 = hom nay.
  List<({DateTime day, int total})> get last7Days {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return List.generate(7, (i) {
      final day = start.subtract(Duration(days: 6 - i));
      final sum = _items
          .where((e) =>
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day)
          .fold<int>(0, (s, e) => s + e.total);
      return (day: day, total: sum);
    });
  }
}
