// Audit rilis T-028: pastikan tidak ada logging konten transaksi ke Logcat
// (TRD §6, NFR-01) dan data lokal tidak keluar dari perangkat.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final repoRoot = Directory.current.path;

  Set<String> dartFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('database.g.dart'))
      .map((f) => f.path)
      .toSet();

  test('Tidak ada print/log di kode Dart produksi', () {
    final offenders = <String>[];
    for (final path in dartFiles('lib')) {
      final lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (RegExp(r'\bprint\s*\(').hasMatch(line) ||
            RegExp(r'\bdebugPrint\s*\(').hasMatch(line) ||
            RegExp(r'\bdeveloper\.log\b').hasMatch(line)) {
          offenders.add('${path.replaceAll(repoRoot, '.')}:${i + 1}  $line');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'Hapus print/debugPrint agar konten transaksi tidak bocor ke Logcat');
  });

  test('Tidak ada android.util.Log di kode Kotlin produksi', () {
    final offenders = <String>[];
    final kotlinDir = Directory('android/app/src/main/kotlin');
    if (!kotlinDir.existsSync()) return;
    for (final path in kotlinDir.listSync(recursive: true).whereType<File>()) {
      if (!path.path.endsWith('.kt')) continue;
      final lines = path.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (RegExp(r'android\.util\.Log').hasMatch(line) ||
            RegExp(r'\bLog\.[diwev]\s*\(').hasMatch(line)) {
          offenders.add('${path.path.replaceAll(repoRoot, '.')}:${i + 1}  $line');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'Hapus android.util.Log agar konten transaksi tidak bocor ke Logcat');
  });

  test('Manifest tidak meminta izin INTERNET (NFR-01)', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, isNot(contains('android.permission.INTERNET')));
  });

  test('Auto-backup dimatikan & data extraction rules mengecualikan DB', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:dataExtractionRules="@xml/data_extraction_rules"'));

    final rules = File('android/app/src/main/res/xml/data_extraction_rules.xml');
    expect(rules.existsSync(), isTrue);
    final content = rules.readAsStringSync();
    expect(content, contains('<exclude domain="database" />'));
    expect(content, contains('<exclude domain="sharedpref" />'));
  });

  test('Tidak ada dependensi analitik/iklan/cloud', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final banned in [
      'firebase',
      'analytics',
      'admob',
      'appsflyer',
      'amplitude',
      'sentry',
    ]) {
      expect(pubspec.toLowerCase(), isNot(contains(banned)),
          reason: 'Jangan pakai SDK analitik/iklan (NFR-01)');
    }
  });
}
