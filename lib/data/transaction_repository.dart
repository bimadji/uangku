import 'package:drift/drift.dart';

import 'database.dart';



/// Periode agregasi arus kas (FR-08).
enum Period { day, week, month }

/// Hasil agregasi arus kas untuk satu periode.
class CashFlow {
  const CashFlow({required this.income, required this.expense});
  final int income;
  final int expense;
  int get net => income - expense;
}

/// Breakdown pengeluaran per kategori (chart FR-08).
class CategoryTotal {
  const CategoryTotal({required this.categoryName, required this.total});
  final String categoryName;
  final int total;
}

class TransactionRepository {
  TransactionRepository(this.db);
  final AppDatabase db;

  // ---- CRUD ----

  Future<int> insert(TransactionsCompanion entry) =>
      db.into(db.transactions).insert(entry);

  Future<int> update(TransactionsCompanion entry) =>
      db.update(db.transactions).write(entry);

  /// Hard delete (FR-06: Hapus Transaksi).
  Future<int> deleteById(int id) =>
      (db.delete(db.transactions)..where((t) => t.id.equals(id))).go();

  /// Feed kronologis (FR-09), terbaru dulu.
  Future<List<Transaction>> feed({int limit = 100, int offset = 0}) =>
      (db.select(db.transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
            ..limit(limit, offset: offset))
          .get();

  Future<Transaction?> byId(int id) =>
      (db.select(db.transactions)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Batas epoch ms untuk Period (naive week = Senin mulai).
  (int, int) _range(Period p, DateTime anchor) {
    final DateTime start;
    switch (p) {
      case Period.day:
        start = DateTime(anchor.year, anchor.month, anchor.day);
      case Period.week:
        final day = DateTime(anchor.year, anchor.month, anchor.day);
        start = day.subtract(Duration(days: day.weekday - 1));
      case Period.month:
        start = DateTime(anchor.year, anchor.month, 1);
    }
    const day = Duration(days: 1);
    final end = switch (p) {
      Period.day => start.add(day),
      Period.week => start.add(const Duration(days: 7)),
      Period.month => DateTime(anchor.year, anchor.month + 1, 1),
    };
    return (start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
  }

  /// Arus kas harian/mingguan/bulanan (FR-08).
  Future<CashFlow> cashFlow(Period p, {DateTime? at}) async {
    final (from, to) = _range(p, at ?? DateTime.now());
    final rows = await db.customSelect(
      "SELECT type, SUM(amount) s FROM transactions "
      "WHERE occurred_at >= ? AND occurred_at < ? GROUP BY type",
      variables: [Variable(from), Variable(to)],
    ).get();
    int income = 0, expense = 0;
    for (final r in rows) {
      if (r.data['type'] == 'income') {
        income = r.data['s'] as int;
      } else {
        expense = r.data['s'] as int;
      }
    }
    return CashFlow(income: income, expense: expense);
  }

  /// Total pengeluaran per kategori dalam periode (chart FR-08).
  Future<List<CategoryTotal>> expenseByCategory(Period p,
      {DateTime? at}) async {
    final (from, to) = _range(p, at ?? DateTime.now());
    final rows = await db.customSelect(
      "SELECT c.name n, SUM(t.amount) s FROM transactions t "
      "JOIN categories c ON c.id = t.category_id "
      "WHERE t.type = 'expense' AND t.occurred_at >= ? AND t.occurred_at < ? "
      "GROUP BY c.name ORDER BY s DESC",
      variables: [Variable(from), Variable(to)],
    ).get();
    return [
      for (final r in rows)
        CategoryTotal(categoryName: r.data['n'] as String, total: r.data['s'] as int)
    ];
  }
}
