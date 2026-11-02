import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/services/categorizer_service.dart';
import 'package:uangku/services/dedup_service.dart';
import 'package:uangku/services/local_notif_service.dart';
import 'package:uangku/services/notif_ingest_service.dart';
import 'package:uangku/services/parser_engine.dart';
import 'package:uangku/services/platform_bridge.dart';
import 'package:uangku/services/widget_bridge.dart';
import 'package:uangku/services/widget_sync.dart';
import 'package:uangku/services/watchdog.dart' as watchdog;
import 'package:workmanager/workmanager.dart';
import 'package:uangku/ui/app_theme.dart';
import 'package:uangku/ui/dashboard_screen.dart';
import 'package:uangku/ui/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'uangku.sqlite'));
  final db = AppDatabase(NativeDatabase(file));
  await db.seedCategories();
  final categorizer = CategorizerService(db);
  await categorizer.seedKeywords();
  final parser = ParserEngine(db);
  await parser.seedInitialRules();

  final localNotif = LocalNotifService(FlutterLocalNotificationsPlugin());
  await localNotif.init();

  final ingest = NotifIngestService(
    db: db,
    parser: parser,
    dedup: DedupService(db),
    categorizer: categorizer,
    localNotif: localNotif,
  );

  // Watchdog T-037c: jadwalkan pemulihan listener berkala (BUG-003).
  await Workmanager().initialize(watchdog.callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    'uangku-watchdog',
    watchdog.kWatchdogTaskName,
    // Interval minimum yang diizinkan Android = 15 menit.
    frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: UangkuApp(ingest: ingest),
    ),
  );
}

class UangkuApp extends ConsumerStatefulWidget {
  const UangkuApp({super.key, required this.ingest});
  final NotifIngestService ingest;

  @override
  ConsumerState<UangkuApp> createState() => _UangkuAppState();
}

class _UangkuAppState extends ConsumerState<UangkuApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  @override
  void initState() {
    super.initState();
    // Listener hanya menerima event saat engine hidup (lihat backlog T-011).
    widget.ingest.start(PlatformBridge.notificationStream);
    widget.ingest.localNotif.onAction = _handleNotifAction;
    // Event kontrol {"type":"listener_status"} dari Kotlin: segarkan banner.
    PlatformBridge.rawEvents.listen((event) {
      if (!mounted) return;
      if (event['type'] == 'listener_status') {
        ref.invalidate(listenerStatusProvider);
        ref.invalidate(listenerConnectedProvider);
      }
    });
    // Jaga proses tetap hidup agar binding listener tidak dilepas MIUI.
    PlatformBridge.startKeepAlive();
    WidgetsBinding.instance.addObserver(this);
    WidgetBridge.clicks.listen(_handleWidgetClick);
    _refreshWidget();
    _handleColdStartIntent();
    // Tarik notifikasi yang sempat tertinggal di tray saat app tidur / ditutup
    PlatformBridge.syncActiveNotifications();
  }

  /// Widget home screen menampilkan pengeluaran hari ini (DBD §7).
  Future<void> _refreshWidget() async {
    final db = ref.read(databaseProvider);
    await syncWidget(db);
  }

  /// Status izin berubah di luar aplikasi (mis. user mencabut Notification
  /// Access di Setelan Android). Segarkan saat app kembali aktif (R-04).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.invalidate(listenerStatusProvider);
    ref.invalidate(listenerConnectedProvider);
    ref.invalidate(batteryStatusProvider);
    _refreshWidget();
    PlatformBridge.syncActiveNotifications();
  }

  /// App dibuka lewat widget/tile "+" saat masih mati (cold start).
  Future<void> _handleColdStartIntent() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri?.toString() != WidgetBridge.quickCashUri) return;
    if (!mounted) return;
    _openQuickCash();
  }

  /// Widget / tile diklik → buka QuickCashSheet.
  void _handleWidgetClick(Uri? uri) {
    if (uri?.toString() == WidgetBridge.quickCashUri) _openQuickCash();
  }

  void _openQuickCash() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: QuickCashSheet()),
      ),
    );
  }

  /// FR-05: "Ubah Kategori" membuka layar Detail/Koreksi (AFD §3).
  /// "Abaikan" sudah ditangani OS lewat `cancelNotification: true`.
  Future<void> _handleNotifAction(int txId, String? actionId) async {
    if (actionId != LocalNotifService.actionEdit) return;
    final db = ref.read(databaseProvider);
    final tx = await (db.select(db.transactions)
          ..where((t) => t.id.equals(txId)))
        .getSingleOrNull();
    if (tx == null) return;
    await _navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => TransactionDetailScreen(tx: tx)),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.ingest.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Uangku',
      theme: buildAppTheme(),
      home: const _AppEntry(),
    );
  }
}

/// Onboarding ditampilkan hanya saat listener belum diizinkan; setelah itu
/// user langsung masuk Dashboard (AFD §2, banner peringatan tetap muncul).
class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PlatformBridge.isListenerEnabled(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final granted = snapshot.data ?? false;
        return granted ? const MainScreen() : const OnboardingScreen();
      },
    );
  }
}
