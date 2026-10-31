import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uangku/data/database.dart';
import 'package:uangku/data/transaction_repository.dart';
import 'package:uangku/services/platform_bridge.dart';
import 'package:uangku/ui/parser_log_screen.dart';

// ---- Riverpod Providers ----

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Override databaseProvider di ProviderScope');
});

final repositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
});

final selectedPeriodProvider = StateProvider<Period>((ref) => Period.day);

final cashFlowProvider = FutureProvider<CashFlow>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final period = ref.watch(selectedPeriodProvider);
  return repo.cashFlow(period);
});

final feedProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.feed();
});

final categoryListProvider = FutureProvider<List<Category>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.select(db.categories).get();
});

final listenerStatusProvider = FutureProvider<bool>((ref) async {
  return PlatformBridge.isListenerEnabled();
});

final batteryStatusProvider = FutureProvider<bool>((ref) async {
  return PlatformBridge.isBatteryOptimizationIgnored();
});

// ---- UI Komponen Inti (DBD §5) ----

/// Banner status listener + whitelist baterai (DBD §5, AFD §8, mitigasi R-04)
class StatusBanner extends ConsumerWidget {
  const StatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listener = ref.watch(listenerStatusProvider);
    final battery = ref.watch(batteryStatusProvider);

    return listener.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (listenerEnabled) {
        final batteryOk = switch (battery) {
          AsyncData(:final value) => value,
          _ => false,
        };
        if (listenerEnabled && batteryOk) {
          // Semua izin lengkap → banner hijau singkat sebagai affirmation
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Listener otomatis aktif (BTN & GoPay)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF14532D)),
                  ),
                ),
              ],
            ),
          );
        }

        // Ada izin yang belum lengkap → banner peringatan
        final (bg, border, fg, icon, message) = listenerEnabled
            ? (
                const Color(0xFFFEF3C7),
                const Color(0xFFFCD34D),
                const Color(0xFF78350F),
                Icons.warning_amber_rounded,
                'Optimasi baterai belum diaktifkan — listener bisa dimatikan OS',
              )
            : (
                const Color(0xFFFEE2E2),
                const Color(0xFFFCA5A5),
                const Color(0xFF7F1D1D),
                Icons.error_outline,
                'Akses notifikasi belum aktif — transaksi digital tidak tercatat otomatis',
              );

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, color: fg),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (!listenerEnabled) {
                    PlatformBridge.openNotificationAccessSettings();
                  }
                  ref.invalidate(listenerStatusProvider);
                  ref.invalidate(batteryStatusProvider);
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'Perbaiki',
                  style: TextStyle(fontSize: 12, color: fg),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.source});
  final TxSource source;

  @override
  Widget build(BuildContext context) {
    final label = switch (source) {
      TxSource.BTN => 'BTN',
      TxSource.GOPAY => 'GoPay',
      TxSource.CASH => 'Tunai',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class ModeChip extends StatelessWidget {
  const ModeChip({super.key, required this.origin});
  final TxOrigin origin;

  @override
  Widget build(BuildContext context) {
    final isAuto = origin == TxOrigin.auto;
    return Text(
      isAuto ? 'auto' : 'manual',
      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
    );
  }
}

class CashFlowCard extends ConsumerWidget {
  const CashFlowCard({super.key});

  String _formatRp(int amount) => 'Rp ${amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPeriod = ref.watch(selectedPeriodProvider);
    final flow = ref.watch(cashFlowProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Arus Kas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                SegmentedButton<Period>(
                  segments: const [
                    ButtonSegment(value: Period.day, label: Text('Hari')),
                    ButtonSegment(value: Period.week, label: Text('Minggu')),
                    ButtonSegment(value: Period.month, label: Text('Bulan')),
                  ],
                  selected: {currentPeriod},
                  onSelectionChanged: (s) =>
                      ref.read(selectedPeriodProvider.notifier).state = s.first,
                ),
              ],
            ),
            const SizedBox(height: 16),
            flow.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Gagal memuat: $e'),
              data: (data) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Pemasukan', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('+ ${_formatRp(data.income)}',
                          style: const TextStyle(
                              color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Pengeluaran', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('- ${_formatRp(data.expense)}',
                          style: const TextStyle(
                              color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.tx});
  final Transaction tx;

  String _formatRp(int amount) => 'Rp ${amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.type == TxType.expense;
    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TransactionDetailScreen(tx: tx)),
      ),
      leading: CircleAvatar(
        backgroundColor: isExpense ? Colors.red.shade50 : Colors.green.shade50,
        child: Icon(
          isExpense ? Icons.arrow_downward : Icons.arrow_upward,
          color: isExpense ? Colors.red : Colors.green,
          size: 18,
        ),
      ),
      title: Text(tx.merchant ?? (isExpense ? 'Pengeluaran' : 'Pemasukan')),
      subtitle: Row(
        children: [
          SourceBadge(source: tx.source),
          const SizedBox(width: 6),
          ModeChip(origin: tx.origin),
          if (tx.note != null) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Text(tx.note!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ),
          ],
        ],
      ),
      trailing: Text(
        '${isExpense ? '-' : '+'} ${_formatRp(tx.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isExpense ? Colors.red : Colors.green,
        ),
      ),
    );
  }
}

// ---- TransactionDetailScreen (AFD §5, DBD §6, FR-06) ----

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.tx});
  final Transaction tx;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late final TextEditingController _noteController;
  late int _categoryId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.tx.amount.toString());
    _merchantController =
        TextEditingController(text: widget.tx.merchant ?? '');
    _noteController = TextEditingController(text: widget.tx.note ?? '');
    _categoryId = widget.tx.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _saving) return;
    setState(() => _saving = true);

    final db = ref.read(databaseProvider);
    await (db.update(db.transactions)..where((t) => t.id.equals(widget.tx.id)))
        .write(
      TransactionsCompanion(
        amount: Value(amount),
        categoryId: Value(_categoryId),
        merchant: Value(_merchantController.text.trim().isEmpty
            ? null
            : _merchantController.text.trim()),
        note: Value(_noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim()),
      ),
    );

    ref.invalidate(cashFlowProvider);
    ref.invalidate(feedProvider);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Transaksi ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final db = ref.read(databaseProvider);
    await (db.delete(db.transactions)..where((t) => t.id.equals(widget.tx.id)))
        .go();

    ref.invalidate(cashFlowProvider);
    ref.invalidate(feedProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);
    final date = DateTime.fromMillisecondsSinceEpoch(widget.tx.occurredAt);
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _saving ? null : _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SourceBadge(source: widget.tx.source),
                      const SizedBox(width: 8),
                      ModeChip(origin: widget.tx.origin),
                    ],
                  ),
                  Text(dateStr,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nominal (Rp)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _merchantController,
            decoration: const InputDecoration(
              labelText: 'Merchant / Keterangan',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Catatan Pribadi',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Kategori:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          categories.maybeWhen(
            data: (cats) => Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in cats
                    .where((c) => c.kind.name == widget.tx.type.name))
                  ChoiceChip(
                    label: Text(c.name),
                    selected: _categoryId == c.id,
                    onSelected: (_) => setState(() => _categoryId = c.id),
                  ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }
}

// ---- QuickCashSheet (AFD §4, DBD §5, FR-07) ----

class QuickCashSheet extends ConsumerStatefulWidget {
  const QuickCashSheet({super.key});

  @override
  ConsumerState<QuickCashSheet> createState() => _QuickCashSheetState();
}

class _QuickCashSheetState extends ConsumerState<QuickCashSheet> {
  String _amount = '';
  int? _categoryId;
  TxType _type = TxType.expense;
  bool _saving = false;

  Future<void> _save() async {
    final amount = int.tryParse(_amount);
    if (amount == null || amount <= 0 || _categoryId == null || _saving) return;
    setState(() => _saving = true);

    final db = ref.read(databaseProvider);
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
          amount: amount,
          type: _type,
          categoryId: _categoryId!,
          source: TxSource.CASH,
          origin: TxOrigin.manual,
          occurredAt: DateTime.now().millisecondsSinceEpoch,
          // Tunai manual tidak lewat parser → hash unik per insert.
          dedupHash: 'cash-${DateTime.now().millisecondsSinceEpoch}',
        ));

    ref.invalidate(cashFlowProvider);
    ref.invalidate(feedProvider);
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<TxType>(
            segments: const [
              ButtonSegment(value: TxType.expense, label: Text('Keluar')),
              ButtonSegment(value: TxType.income, label: Text('Masuk')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
          Text(
            _amount.isEmpty ? 'Rp 0' : 'Rp $_amount',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Keypad 1-9, 0, 00, backspace (DBD §5: nominal cepat).
          for (final row in [['1','2','3'],['4','5','6'],['7','8','9'],['00','0','⌫']])
            Row(
              children: [
                for (final k in row)
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() {
                        if (k == '⌫') {
                          if (_amount.isNotEmpty) {
                            _amount = _amount.substring(0, _amount.length - 1);
                          }
                        } else if (_amount.length < 12) {
                          _amount = (_amount + k).replaceFirst(RegExp(r'^0+(?=\d)'), '');
                        }
                      }),
                      child: Text(k, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          // Grid chip kategori 1 tap (kind sesuai tipe terpilih).
          categories.maybeWhen(
            data: (cats) => Wrap(
              spacing: 6, runSpacing: 6,
              children: [
                for (final c in cats.where((c) => c.kind.name == _type.name))
                  ChoiceChip(
                    label: Text(c.name),
                    selected: _categoryId == c.id,
                    onSelected: (_) => setState(() => _categoryId = c.id),
                  ),
              ],
            ),
            orElse: () => const SizedBox(height: 32),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (_amount.isEmpty || _categoryId == null || _saving) ? null : _save,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Simpan', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

// ---- Layar Utama (AFD §1: 3 Tab) ----

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  Future<void> _openQuickCash() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const QuickCashSheet(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Dashboard' : (_tab == 1 ? 'Transaksi' : 'Pengaturan')),
      ),
      body: _tab == 0
          ? const _DashboardTab()
          : (_tab == 1 ? const _FeedTab() : const _SettingsTab()),
      floatingActionButton: FloatingActionButton(
        onPressed: _openQuickCash,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Transaksi'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Pengaturan'),
        ],
      ),
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(cashFlowProvider);
        ref.invalidate(feedProvider);
      },
      child: ListView(
        children: [
          const StatusBanner(),
          const CashFlowCard(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          feed.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Gagal: $e')),
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Belum ada transaksi.')),
                  )
                : Column(children: items.take(5).map((t) => TransactionTile(tx: t)).toList()),
          ),
        ],
      ),
    );
  }
}

class _FeedTab extends ConsumerWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Gagal: $e')),
      data: (items) => items.isEmpty
          ? const Center(child: Text('Belum ada transaksi.'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => TransactionTile(tx: items[i]),
            ),
    );
  }
}

class _SettingsTab extends ConsumerWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listener = ref.watch(listenerStatusProvider);
    final battery = ref.watch(batteryStatusProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Status Otomatisasi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                title: const Text('Notification Access',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Menangkap notifikasi BTN & GoPay',
                    style: TextStyle(fontSize: 12)),
                trailing: listener.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (enabled) => Text(
                    enabled ? 'AKTIF' : 'MATI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: enabled
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ),
                onTap: () async {
                  await PlatformBridge.openNotificationAccessSettings();
                  ref.invalidate(listenerStatusProvider);
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Whitelist Baterai (OEM)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Mencegah OS mematikan listener',
                    style: TextStyle(fontSize: 12)),
                trailing: battery.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (ignored) => Text(
                    ignored ? 'AKTIF' : 'CEK SETELAN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ignored
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFD97706),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Log Parser & Uji Rule',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Riwayat notifikasi mentah + editor regex',
                style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ParserLogScreen()),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Uangku v1.0.0 (MVP)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Penyimpanan 100% lokal. Tanpa server, tanpa login (FR-12).',
            style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
