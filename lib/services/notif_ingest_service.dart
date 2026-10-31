import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:uangku/data/database.dart';
import 'package:uangku/services/categorizer_service.dart';
import 'package:uangku/services/dedup_service.dart';
import 'package:uangku/services/local_notif_service.dart';
import 'package:uangku/services/parser_engine.dart';
import 'package:uangku/services/platform_bridge.dart';

/// Router notifikasi masuk → ParserEngine → DedupService → CategorizerService
/// → simpan transaksi → notifikasi interaktif (TRD §2, AFD §3).
class NotifIngestService {
  NotifIngestService({
    required this.db,
    required this.parser,
    required this.dedup,
    required this.categorizer,
    required this.localNotif,
  });

  final AppDatabase db;
  final ParserEngine parser;
  final DedupService dedup;
  final CategorizerService categorizer;
  final LocalNotifService localNotif;

  StreamSubscription<RawNotification>? _sub;

  void start(Stream<RawNotification> stream) {
    _sub?.cancel();
    _sub = stream.listen(handle);
  }

  Future<void> stop() async => _sub?.cancel();

  static TxSource? sourceFor(String packageName) => switch (packageName) {
        'id.co.btn.mobilebanking.android' => TxSource.BTN,
        'com.gojek.gopay' => TxSource.GOPAY,
        _ => null,
      };

  /// Proses satu notifikasi. Mengembalikan id transaksi jika tersimpan.
  Future<int?> handle(RawNotification notif) async {
    final source = sourceFor(notif.packageName);
    if (source == null) return null;

    final candidate = await parser.parse(notif);
    if (candidate == null) return null; // gagal parse sudah tercatat di parser_logs

    if (await dedup.isDuplicate(candidate, source)) {
      await dedup.logIgnored(
        packageName: notif.packageName,
        title: notif.title,
        body: notif.text,
        postedAt: notif.postTime,
        ruleId: candidate.ruleId,
      );
      return null;
    }

    final category = await categorizer.categorize(
      merchant: candidate.merchant,
      txType: candidate.txType,
    );

    final txId = await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            amount: candidate.amount,
            type: candidate.txType,
            categoryId: category.id,
            source: source,
            origin: TxOrigin.auto,
            merchant: Value(candidate.merchant),
            occurredAt: candidate.occurredAt,
            dedupHash: DedupService.computeHash(
              source: source,
              amount: candidate.amount,
              merchant: candidate.merchant,
              occurredAt: candidate.occurredAt,
            ),
          ),
        );

    await localNotif.showTransaction(
      txId: txId,
      merchant: candidate.merchant ?? candidate.appLabel,
      amount: candidate.amount,
      categoryName: category.name,
    );

    return txId;
  }
}
