import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/services/categorizer_service.dart';
import 'package:uangku/services/parser_engine.dart';
import 'package:uangku/services/platform_bridge.dart';
import 'package:uangku/ui/dashboard_screen.dart';
import 'package:uangku/ui/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'uangku.sqlite'));
  final db = AppDatabase(NativeDatabase(file));
  await db.seedCategories();
  await CategorizerService(db).seedKeywords();
  await ParserEngine(db).seedInitialRules();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const UangkuApp(),
    ),
  );
}

class UangkuApp extends StatelessWidget {
  const UangkuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uangku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
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
