import 'package:drift/drift.dart';

part 'database.g.dart';

enum CategoryKind { income, expense }
enum TxType { income, expense }
enum TxSource { BTN, GOPAY, CASH }
enum TxOrigin { auto, manual }
enum ParserLogStatus { parsed, failed, ignored }

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get kind => textEnum<CategoryKind>()();
  IntColumn get sortOrder => integer()();
  // JSON array keyword/merchant untuk auto-kategorisasi (FR-04); NULL diperbolehkan.
  TextColumn get keywords => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {name, kind},
      ];
}

@TableIndex(name: 'idx_tx_occurred', columns: {#occurredAt})
@TableIndex(name: 'idx_tx_category', columns: {#categoryId, #occurredAt})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amount => integer()();
  TextColumn get type => textEnum<TxType>()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get source => textEnum<TxSource>()();
  TextColumn get origin => textEnum<TxOrigin>()();
  TextColumn get merchant => text().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get occurredAt => integer()(); // epoch ms
  TextColumn get dedupHash => text().unique()();
}

class ParserRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get packageName => text()();
  TextColumn get appLabel => text()();
  TextColumn get txType => textEnum<TxType>()();
  TextColumn get pattern => text()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  IntColumn get enabled => integer().withDefault(const Constant(1))();
}

@TableIndex(name: 'idx_plog_posted', columns: {#postedAt})
class ParserLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get packageName => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get status => textEnum<ParserLogStatus>()();
  TextColumn get error => text().nullable()();
  IntColumn get ruleId => integer().nullable().references(ParserRules, #id)();
  IntColumn get postedAt => integer()();

  List<Index> get customIndexes => [
        Index('idx_plog_posted', r'posted_at DESC'),
      ];
}

@DriftDatabase(tables: [Categories, Transactions, ParserRules, ParserLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  /// Seed kategori FR-11, idempotent (insert hanya jika name belum ada).
  Future<void> seedCategories() async {
    const expense = [
      'Makanan & Minuman', 'Transportasi', 'Kos & Tagihan', 'Belanja',
      'Hiburan', 'Kesehatan', 'Pendidikan', 'Lainnya',
    ];
    const income = ['Uang Saku', 'Gaji/Part-time', 'Transfer Masuk', 'Lainnya'];
    Future<void> upsert(String name, CategoryKind kind) async {
      final existing = await (select(categories)
            ..where((c) => c.name.equals(name) & c.kind.equalsValue(kind)))
          .getSingleOrNull();
      if (existing == null) {
        await into(categories).insert(CategoriesCompanion.insert(
            name: name, kind: kind, sortOrder: 0));
      }
    }

    for (final n in expense) {
      await upsert(n, CategoryKind.expense);
    }
    for (final n in income) {
      await upsert(n, CategoryKind.income);
    }
  }
}
