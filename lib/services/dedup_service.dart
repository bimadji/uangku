import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/services/parser_engine.dart';

class DedupService {
  DedupService(this.db);
  final AppDatabase db;

  /// Toleransi waktu 60 detik (BSD §4)
  static const int toleranceMs = 60 * 1000;

  /// Menghasilkan hash kanonikal SHA-256 dari source, amount, merchant uppercase, dan waktu per bucket 60 detik
  static String computeHash({
    required TxSource source,
    required int amount,
    String? merchant,
    required int occurredAt,
  }) {
    final normMerchant = (merchant ?? '').trim().toUpperCase();
    final timeBucket = occurredAt ~/ toleranceMs; // Pembulatan bucket 60s
    final raw = '${source.name}|$amount|$normMerchant|$timeBucket';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  /// Cek apakah kandidat merupakan duplikat dari transaksi yang sudah ada
  Future<bool> isDuplicate(ParsedCandidate candidate, TxSource source) async {
    final hash = computeHash(
      source: source,
      amount: candidate.amount,
      merchant: candidate.merchant,
      occurredAt: candidate.occurredAt,
    );

    // Lapis 1: Cek via exact dedup_hash
    final byHash = await (db.select(db.transactions)
          ..where((t) => t.dedupHash.equals(hash)))
        .getSingleOrNull();
    if (byHash != null) return true;

    // Lapis 2: Cek window waktu ±60 detik dengan source, amount, dan merchant yang sama
    final minTime = candidate.occurredAt - toleranceMs;
    final maxTime = candidate.occurredAt + toleranceMs;
    final normMerchant = (candidate.merchant ?? '').trim().toUpperCase();

    final nearby = await (db.select(db.transactions)
          ..where((t) =>
              t.source.equalsValue(source) &
              t.amount.equals(candidate.amount) &
              t.occurredAt.isBiggerOrEqualValue(minTime) &
              t.occurredAt.isSmallerOrEqualValue(maxTime)))
        .get();

    for (final tx in nearby) {
      if ((tx.merchant ?? '').trim().toUpperCase() == normMerchant) {
        return true;
      }
    }

    return false;
  }

  /// Catat notifikasi terduplikasi ke parser_logs sebagai 'ignored' untuk keperluan audit (BSD §4)
  Future<void> logIgnored({
    required String packageName,
    required String title,
    required String body,
    required int postedAt,
    required int ruleId,
  }) async {
    await db.into(db.parserLogs).insert(
          ParserLogsCompanion.insert(
            packageName: packageName,
            title: title,
            body: body,
            status: ParserLogStatus.ignored,
            postedAt: postedAt,
            ruleId: Value(ruleId),
            error: const Value('Duplikat tertahan dedup (window 60s)'),
          ),
        );
  }
}
