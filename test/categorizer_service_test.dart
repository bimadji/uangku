import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/services/categorizer_service.dart';

void main() {
  late AppDatabase db;
  late CategorizerService categorizer;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    categorizer = CategorizerService(db);
    await db.seedCategories();
    await categorizer.seedKeywords();
  });

  tearDown(() => db.close());

  group('T-017: CategorizerService (FR-04)', () {
    test('seedKeywords mengisi keywords sebagai JSON array', () async {
      final cats = await db.select(db.categories).get();
      final food = cats.firstWhere((c) => c.name == 'Makanan & Minuman');
      expect(food.keywords, contains('GEPREK'));
      expect(food.keywords, startsWith('['));
    });

    test('seedKeywords idempotent: 2x jalan tidak error', () async {
      await categorizer.seedKeywords();
      final cats = await db.select(db.categories).get();
      final food = cats.firstWhere((c) => c.name == 'Makanan & Minuman');
      expect(food.keywords, contains('GEPREK'));
    });

    test('merchant sampel nyata T-010 "GEPREK MASZEH ITS" → Makanan & Minuman',
        () async {
      final cat = await categorizer.categorize(
        merchant: 'GEPREK MASZEH ITS',
        txType: TxType.expense,
      );
      expect(cat.name, 'Makanan & Minuman');
      expect(cat.kind, CategoryKind.expense);
    });

    test('merchant Gojek → Transportasi', () async {
      final cat = await categorizer.categorize(
        merchant: 'Gojek Sukolilo',
        txType: TxType.expense,
      );
      expect(cat.name, 'Transportasi');
    });

    test('merchant Indomaret → Belanja', () async {
      final cat = await categorizer.categorize(
        merchant: 'Indomaret Gebang',
        txType: TxType.expense,
      );
      expect(cat.name, 'Belanja');
    });

    test('match case-insensitive', () async {
      final cat = await categorizer.categorize(
        merchant: 'geprek maszeh its',
        txType: TxType.expense,
      );
      expect(cat.name, 'Makanan & Minuman');
    });

    test('merchant tidak dikenal → fallback Lainnya (expense)', () async {
      final cat = await categorizer.categorize(
        merchant: 'Toko Misterius XYZ',
        txType: TxType.expense,
      );
      expect(cat.name, 'Lainnya');
      expect(cat.kind, CategoryKind.expense);
    });

    test('merchant null → fallback Lainnya (income)', () async {
      final cat = await categorizer.categorize(
        merchant: null,
        txType: TxType.income,
      );
      expect(cat.name, 'Lainnya');
      expect(cat.kind, CategoryKind.income);
    });

    test('merchant kosong → fallback Lainnya', () async {
      final cat = await categorizer.categorize(
        merchant: '   ',
        txType: TxType.expense,
      );
      expect(cat.name, 'Lainnya');
    });

    test('top-up GoPay → Transfer Masuk (income)', () async {
      final cat = await categorizer.categorize(
        merchant: 'Top up via BTN Internet Banking App',
        txType: TxType.income,
      );
      expect(cat.name, 'Transfer Masuk');
      expect(cat.kind, CategoryKind.income);
    });

    test('kategori income tidak pernah mengembalikan kategori expense',
        () async {
      final cat = await categorizer.categorize(
        merchant: 'GEPREK MASZEH ITS',
        txType: TxType.income,
      );
      expect(cat.kind, CategoryKind.income);
    });
  });
}
