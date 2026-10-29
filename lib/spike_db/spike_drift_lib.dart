import 'package:drift/drift.dart';

part 'spike_drift_lib.g.dart';

enum CategoryKind { income, expense }
enum TxType { income, expense }

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get kind => textEnum<CategoryKind>()();
  IntColumn get sortOrder => integer()();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amount => integer()();
  TextColumn get type => textEnum<TxType>()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get source => text()(); // BTN | GOPAY | CASH
  TextColumn get origin => text()(); // auto | manual
  TextColumn get merchant => text().nullable()();
  IntColumn get occurredAt => integer()(); // epoch ms
  TextColumn get dedupHash => text().unique()();
}

@DriftDatabase(tables: [Categories, Transactions])
class SpikeDb extends _$SpikeDb {
  SpikeDb(super.e);
  @override
  int get schemaVersion => 1;
}
