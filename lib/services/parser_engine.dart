import 'package:drift/drift.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/services/platform_bridge.dart';

/// Hasil ekstraksi transaksi dari ParserEngine (FR-02)
class ParsedCandidate {
  const ParsedCandidate({
    required this.packageName,
    required this.appLabel,
    required this.txType,
    required this.amount,
    this.merchant,
    required this.occurredAt,
    required this.ruleId,
  });

  final String packageName;
  final String appLabel;
  final TxType txType;
  final int amount; // Rupiah utuh
  final String? merchant;
  final int occurredAt; // epoch ms
  final int ruleId;
}

class ParserEngine {
  ParserEngine(this.db);
  final AppDatabase db;

  /// Inisialisasi rule awal ke database dari sampel aktual nyata (T-010)
  Future<void> seedInitialRules() async {
    final existing = await db.select(db.parserRules).get();
    if (existing.isNotEmpty) return;

    // 1. GoPay: Top Up Masuk (Sampel: Top up Rp10.000 via BTN Internet Banking App udah masuk.)
    await db.into(db.parserRules).insert(
          ParserRulesCompanion.insert(
            packageName: 'com.gojek.gopay',
            appLabel: 'GoPay',
            txType: TxType.income,
            pattern: r'Top up Rp(?<amount>[\d\.]+) via (?<merchant>.*) udah masuk',
            priority: const Value(10),
            enabled: const Value(1),
          ),
        );

    // 2. Bale by BTN: QRIS Payment (Sampel: Payment GEPREK MASZEH ITS Successful)
    // Catatan: Notifikasi Bale tidak mencantumkan nominal (amount=0 agar ditandai perlu edit manual)
    await db.into(db.parserRules).insert(
          ParserRulesCompanion.insert(
            packageName: 'id.co.btn.mobilebanking.android',
            appLabel: 'BTN',
            txType: TxType.expense,
            pattern: r'Payment (?<merchant>.*) Successful',
            priority: const Value(10),
            enabled: const Value(1),
          ),
        );

    // 3. Bale by BTN: Transfer Masuk (Sampel: Transfer Masuk)
    await db.into(db.parserRules).insert(
          ParserRulesCompanion.insert(
            packageName: 'id.co.btn.mobilebanking.android',
            appLabel: 'BTN',
            txType: TxType.income,
            pattern: r'^Transfer Masuk$',
            priority: const Value(5),
            enabled: const Value(1),
          ),
        );
  }

  /// Eksekusi parsing terhadap notifikasi mentah
  Future<ParsedCandidate?> parse(RawNotification notif) async {
    final rules = await (db.select(db.parserRules)
          ..where((r) =>
              r.packageName.equals(notif.packageName) & r.enabled.equals(1))
          ..orderBy([(r) => OrderingTerm.desc(r.priority)]))
        .get();

    // Prioritaskan teks body jika ada, fallback ke title jika text kosong (seperti pada Bale BTN)
    final targetText =
        notif.text.trim().isNotEmpty ? notif.text.trim() : notif.title.trim();

    for (final rule in rules) {
      try {
        final regex = RegExp(rule.pattern, caseSensitive: false);
        final match = regex.firstMatch(targetText);
        if (match != null) {
          int amount = 0;
          try {
            final rawAmount = match.namedGroup('amount');
            if (rawAmount != null) {
              amount = int.parse(rawAmount.replaceAll('.', ''));
            }
          } catch (_) {
            amount = 0;
          }

          String? merchant;
          try {
            merchant = match.namedGroup('merchant')?.trim();
          } catch (_) {
            merchant = null;
          }

          // Catat sukses ke parser_logs
          await db.into(db.parserLogs).insert(
                ParserLogsCompanion.insert(
                  packageName: notif.packageName,
                  title: notif.title,
                  body: notif.text,
                  status: ParserLogStatus.parsed,
                  postedAt: notif.postTime,
                  ruleId: Value(rule.id),
                ),
              );

          return ParsedCandidate(
            packageName: rule.packageName,
            appLabel: rule.appLabel,
            txType: rule.txType,
            amount: amount,
            merchant: merchant,
            occurredAt: notif.postTime,
            ruleId: rule.id,
          );
        }
      } catch (e) {
        // Abaikan regex invalid, lanjut ke rule berikutnya
      }
    }

    // Tidak ada rule yang cocok: catat gagal ke parser_logs
    await db.into(db.parserLogs).insert(
          ParserLogsCompanion.insert(
            packageName: notif.packageName,
            title: notif.title,
            body: notif.text,
            status: ParserLogStatus.failed,
            postedAt: notif.postTime,
            error: const Value('Pola notifikasi belum didukung'),
          ),
        );

    return null;
  }
}
