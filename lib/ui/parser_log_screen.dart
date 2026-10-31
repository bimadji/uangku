import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/services/parser_engine.dart';
import 'package:uangku/ui/dashboard_screen.dart';

// ---- Providers ----

final parserLogsProvider = FutureProvider<List<ParserLog>>((ref) async {
  final db = ref.watch(databaseProvider);
  return (db.select(db.parserLogs)
        ..orderBy([(l) => OrderingTerm.desc(l.postedAt)])
        ..limit(200))
      .get();
});

final parserRulesProvider = FutureProvider<List<ParserRule>>((ref) async {
  final db = ref.watch(databaseProvider);
  return (db.select(db.parserRules)
        ..orderBy([(r) => OrderingTerm.desc(r.priority)]))
      .get();
});

// ---- Layar Log Parser (AFD §6) ----

class ParserLogScreen extends ConsumerWidget {
  const ParserLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(parserLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Parser'),
        actions: [
          IconButton(
            tooltip: 'Hapus semua log',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus semua log?'),
                  content: const Text(
                      'Seluruh teks notifikasi mentah akan dihapus permanen.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Hapus')),
                  ],
                ),
              );
              if (ok != true) return;
              await ParserEngine(ref.read(databaseProvider)).clearLogs();
              ref.invalidate(parserLogsProvider);
            },
          ),
        ],
      ),
      body: logs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada notifikasi yang ditangkap listener.\n'
                  'Pastikan Notification Access sudah diizinkan.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final parsed = items.where((l) => l.status == ParserLogStatus.parsed).length;
          final failed = items.where((l) => l.status == ParserLogStatus.failed).length;
          final ignored = items.where((l) => l.status == ParserLogStatus.ignored).length;

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _stat('Parsed', parsed, Colors.green),
                    _stat('Failed', failed, Colors.red),
                    _stat('Ignored', ignored, Colors.grey),
                  ],
                ),
              ),
              for (final log in items)
                ListTile(
                  dense: true,
                  leading: Icon(
                    switch (log.status) {
                      ParserLogStatus.parsed => Icons.check_circle_outline,
                      ParserLogStatus.failed => Icons.error_outline,
                      ParserLogStatus.ignored => Icons.remove_circle_outline,
                    },
                    color: switch (log.status) {
                      ParserLogStatus.parsed => Colors.green,
                      ParserLogStatus.failed => Colors.red,
                      ParserLogStatus.ignored => Colors.grey,
                    },
                  ),
                  title: Text(
                    log.body.isEmpty ? log.title : log.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                  subtitle: Text(
                    '${log.packageName} · ${_fmt(log.postedAt)}'
                    '${log.error == null ? '' : ' · ${log.error}'}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RuleTestScreen(
                        prefill: log.body.isEmpty ? log.title : log.body,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _fmt(int epochMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _stat(String label, int value, Color color) => Expanded(
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      );
}

// ---- Layar Uji Rule Parser (AFD §6, FR-10) ----

class RuleTestScreen extends ConsumerStatefulWidget {
  const RuleTestScreen({super.key, this.prefill = ''});
  final String prefill;

  @override
  ConsumerState<RuleTestScreen> createState() => _RuleTestScreenState();
}

class _RuleTestScreenState extends ConsumerState<RuleTestScreen> {
  late final TextEditingController _textCtrl =
      TextEditingController(text: widget.prefill);
  final _patternCtrl = TextEditingController();
  RuleTestResult? _result;
  int? _ruleId;

  @override
  void dispose() {
    _textCtrl.dispose();
    _patternCtrl.dispose();
    super.dispose();
  }

  void _runTest(String pattern) {
    setState(() => _result = ParserRuleTesting.testPattern(pattern, _textCtrl.text));
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(parserRulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Uji Rule Parser')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _textCtrl,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Teks notifikasi mentah',
              border: OutlineInputBorder(),
            ),
            // Uji live: hasil ikut berubah saat teks mentah diedit (FR-10)
            onChanged: (_) {
              if (_patternCtrl.text.isNotEmpty) _runTest(_patternCtrl.text);
            },
          ),
          const SizedBox(height: 12),
          rules.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Gagal memuat rule: $e'),
            data: (list) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _ruleId,
                  decoration: const InputDecoration(
                    labelText: 'Rule (per aplikasi)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final r in list)
                      DropdownMenuItem(
                        value: r.id,
                        child: Text('${r.appLabel} · ${r.txType.name}',
                            style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                  onChanged: (id) {
                    final rule = list.firstWhere((r) => r.id == id);
                    _patternCtrl.text = rule.pattern;
                    setState(() => _ruleId = id);
                    _runTest(rule.pattern);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _patternCtrl,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Pattern regex (named groups)',
                    border: const OutlineInputBorder(),
                    errorText: _result != null && !_result!.ok
                        ? _result!.error
                        : null,
                  ),
                  onChanged: _runTest,
                ),
                const SizedBox(height: 8),
                if (_result != null && _result!.ok)
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cocok',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Nominal: ${_result!.amount ?? '-'}',
                              style: const TextStyle(fontSize: 12)),
                          Text('Merchant: ${_result!.merchant ?? '-'}',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _ruleId == null || !(_result?.ok ?? false)
                      ? null
                      : () async {
                          await ParserEngine(ref.read(databaseProvider))
                              .updateRulePattern(_ruleId!, _patternCtrl.text);
                          if (!context.mounted) return;
                          ref.invalidate(parserRulesProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Rule tersimpan tanpa build ulang')),
                          );
                        },
                  child: const Text('Uji & Simpan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
