import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

enum ExpenseCategory {
  food('Food'),
  study('Study'),
  travel('Travel'),
  gear('Gear'),
  entertainment('Entertainment'),
  bills('Bills');

  final String label;
  const ExpenseCategory(this.label);
}

class Expense {
  final int? id;
  final String merchant;
  final int total; // VND
  final ExpenseCategory category;
  final DateTime date;
  final String? imagePath;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.merchant,
    required this.total,
    required this.category,
    required this.date,
    this.imagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Expense copyWith({
    String? merchant,
    int? total,
    ExpenseCategory? category,
    DateTime? date,
  }) =>
      Expense(
        id: id,
        merchant: merchant ?? this.merchant,
        total: total ?? this.total,
        category: category ?? this.category,
        date: date ?? this.date,
        imagePath: imagePath,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'merchant': merchant,
        'total': total,
        'category': category.name,
        'date': date.millisecondsSinceEpoch,
        'image_path': imagePath,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
        id: m['id'] as int,
        merchant: m['merchant'] as String,
        total: m['total'] as int,
        category: ExpenseCategory.values.byName(m['category'] as String),
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        imagePath: m['image_path'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );
}

class ExpenseDb {
  ExpenseDb._();
  static final instance = ExpenseDb._();
  Database? _db;

  Future<Database> get _database async => _db ??= await openDatabase(
        join(await getDatabasesPath(), 'expenses.db'),
        version: 1,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE expenses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant TEXT NOT NULL,
            total INTEGER NOT NULL,
            category TEXT NOT NULL,
            date INTEGER NOT NULL,
            image_path TEXT,
            created_at INTEGER NOT NULL
          )'''),
      );

  Future<int> insert(Expense e) async =>
      (await _database).insert('expenses', e.toMap()..remove('id'));

  Future<int> update(Expense e) async => (await _database)
      .update('expenses', e.toMap(), where: 'id = ?', whereArgs: [e.id]);

  Future<int> delete(int id) async =>
      (await _database).delete('expenses', where: 'id = ?', whereArgs: [id]);

  Future<List<Expense>> query({
    ExpenseCategory? category,
    DateTime? from,
    DateTime? to,
    String? search,
  }) async {
    final where = <String>[];
    final args = <Object?>[];
    if (category != null) {
      where.add('category = ?');
      args.add(category.name);
    }
    if (from != null) {
      where.add('date >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      where.add('date <= ?');
      args.add(to.millisecondsSinceEpoch);
    }
    if (search != null && search.trim().isNotEmpty) {
      where.add('merchant LIKE ?');
      args.add('%${search.trim()}%');
    }
    final rows = await (await _database).query(
      'expenses',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }
}
