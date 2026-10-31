import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:uangku/data/database.dart';

class CategorizerService {
  CategorizerService(this.db);
  final AppDatabase db;

  /// Kata kunci awal per kategori (FR-04), berasal dari sampel nyata T-010
  /// dan merchant kampus/warung umum. Disimpan sebagai JSON array di
  /// `categories.keywords`.
  static const Map<String, List<String>> defaultKeywords = {
    'Makanan & Minuman': [
      'GEPREK', 'WARUNG', 'KANTIN', 'BAKSO', 'NASI', 'AYAM', 'KOPI',
      'CAFE', 'RESTO', 'MAKAN', 'KAFE', 'ES TEH', 'SATE',
    ],
    'Transportasi': [
      'GOJEK', 'GRAB', 'GO-RIDE', 'GORIDE', 'OJOL', 'BENSIN', 'PERTALITE',
      'PERTAMAX', 'SPBU', 'PARKIR', 'KRL', 'BUS', 'ANGKOT', 'TOL',
    ],
    'Kos & Tagihan': [
      'KOS', 'KOST', 'LISTRIK', 'PLN', 'AIR', 'PDAM', 'INDIHOME',
      'WIFI', 'PULSA', 'TELKOMSEL', 'TOKEN',
    ],
    'Belanja': [
      'INDOMARET', 'ALFAMART', 'ALFAMIDI', 'SUPERINDO', 'INDOMARCO',
      'MINIMARKET', 'SUPERMARKET',
    ],
    'Hiburan': ['BIOSKOP', 'CINEMA', 'XXI', 'CGV', 'GAME', 'SPOTIFY', 'NETFLIX'],
    'Kesehatan': ['APOTEK', 'KLINIK', 'RUMAH SAKIT', 'DOKTER', 'OBAT'],
    'Pendidikan': ['BUKU', 'KULIAH', 'SPP', 'UKT', 'PRINT', 'FOTOKOPI', 'ATK'],
    'Uang Saku': ['UANG SAKU', 'ORANG TUA', 'ORANGTUA', 'MAMA', 'PAPA'],
    'Gaji/Part-time': ['GAJI', 'UPAH', 'HONOR', 'FREELANCE', 'PART-TIME'],
    'Transfer Masuk': [
      'TRANSFER MASUK', 'TOP UP', 'TOPUP', 'TERIMA TRANSFER',
      'INTERNET BANKING', 'MOBILE BANKING', 'BANKING APP',
    ],
  };

  /// Isi kolom `keywords` untuk kategori yang belum punya (idempotent).
  Future<void> seedKeywords() async {
    final all = await db.select(db.categories).get();
    for (final cat in all) {
      final kws = defaultKeywords[cat.name];
      if (kws == null || cat.keywords != null) continue;
      await (db.update(db.categories)..where((c) => c.id.equals(cat.id)))
          .write(CategoriesCompanion(keywords: Value(jsonEncode(kws))));
    }
  }

  /// Tentukan kategori dari merchant/keterangan. Fallback ke `Lainnya`
  /// sesuai jenis transaksi bila tidak ada keyword yang cocok (FR-04).
  Future<Category> categorize({
    String? merchant,
    required TxType txType,
  }) async {
    final kind = txType == TxType.income
        ? CategoryKind.income
        : CategoryKind.expense;

    final candidates = await (db.select(db.categories)
          ..where((c) => c.kind.equalsValue(kind)))
        .get();

    final haystack = (merchant ?? '').trim().toUpperCase();
    if (haystack.isNotEmpty) {
      for (final cat in candidates) {
        final raw = cat.keywords;
        if (raw == null) continue;
        final kws = (jsonDecode(raw) as List).cast<String>();
        if (kws.any((k) => haystack.contains(k.toUpperCase()))) {
          return cat;
        }
      }
    }

    return candidates.firstWhere(
      (c) => c.name == 'Lainnya',
      orElse: () => candidates.first,
    );
  }
}
