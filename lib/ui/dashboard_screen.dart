import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uangku/data/database.dart';
import 'package:uangku/data/transaction_repository.dart';
import 'package:uangku/services/platform_bridge.dart';
import 'package:uangku/ui/app_theme.dart';
import 'package:uangku/ui/parser_log_screen.dart';
import 'package:uangku/ui/states.dart';

// ---- Riverpod Providers ----

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Override databaseProvider di ProviderScope');
});

final repositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
});

final selectedPeriodProvider = StateProvider<Period>((ref) => Period.day);

/// Tab aktif di bottom navigation (0=Dashboard, 1=Transaksi, 2=Pengaturan).
final selectedTabProvider = StateProvider<int>((ref) => 0);

final cashFlowProvider = FutureProvider<CashFlow>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final period = ref.watch(selectedPeriodProvider);
  return repo.cashFlow(period);
});

final categoryExpensesProvider = FutureProvider<List<CategoryTotal>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final period = ref.watch(selectedPeriodProvider);
  return repo.expenseByCategory(period);
});

final feedProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.feed();
});

/// Peta id kategori -> nama, dipakai label kategori di baris transaksi (mockup `.tx-time`).
final categoryNameMapProvider = FutureProvider<Map<int, String>>((ref) async {
  final db = ref.watch(databaseProvider);
  final cats = await db.select(db.categories).get();
  return {for (final c in cats) c.id: c.name};
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

/// Format nominal rupiah dengan pemisah ribuan lokal (DBD §4).
String formatRp(int amount) => 'Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';

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
              Semantics(
                button: true,
                label: 'Perbaiki status izin listener',
                child: TextButton(
                  onPressed: () {
                    if (!listenerEnabled) {
                      PlatformBridge.openNotificationAccessSettings();
                    }
                    ref.invalidate(listenerStatusProvider);
                    ref.invalidate(batteryStatusProvider);
                  },
                  style: TextButton.styleFrom(
                    // DBD §9: target sentuh minimal 48×48dp
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'Perbaiki',
                    style: TextStyle(fontSize: 12, color: fg),
                  ),
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

/// Kartu arus kas: hero nominal pengeluaran + baris bawah Pemasukan & Net Arus Kas
/// (mockup option-a `.card.cashflow-hero`). Segmented periode berada di luar
/// kartu (baris penuh di atasnya) — mockup `screen-content`.
class CashFlowCard extends ConsumerWidget {
  const CashFlowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(cashFlowProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Arus Kas', style: AppText.cardLabel),
            const SizedBox(height: 4),
            flow.when(
              loading: () => const SizedBox(
                height: 32,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Gagal memuat: $e', style: AppText.bodyRegular),
              data: (data) => TabularNumber(
                text: '- ${formatRp(data.expense)}',
                style: AppText.heroAmount.copyWith(color: AppColors.expense),
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.borderSoft),
            const SizedBox(height: 12),
            flow.when(
              loading: () => const SizedBox(height: 36),
              error: (e, _) => const SizedBox(height: 36),
              data: (data) => Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pemasukan', style: AppText.metricLabel),
                        const SizedBox(height: 2),
                        TabularNumber(
                          text: '+ ${formatRp(data.income)}',
                          style: AppText.metricValue.copyWith(color: AppColors.income),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Net Arus Kas', style: AppText.metricLabel),
                        const SizedBox(height: 2),
                        TabularNumber(
                          text: '${data.net >= 0 ? '+' : '-'} ${formatRp(data.net.abs())}',
                          style: AppText.metricValue.copyWith(color: AppColors.fg),
                        ),
                      ],
                    ),
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

/// Segmented pilihan periode — baris penuh di atas kartu Arus Kas (mockup).
class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  static const _labels = {
    Period.day: 'Hari Ini',
    Period.week: 'Minggu Ini',
    Period.month: 'Bulan Ini',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(selectedPeriodProvider);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final period in Period.values)
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    ref.read(selectedPeriodProvider.notifier).state = period,
                child: Semantics(
                  button: true,
                  selected: current == period,
                  label: _labels[period],
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: current == period
                          ? AppColors.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _labels[period]!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: current == period ? AppColors.fg : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


/// Badge "OFFLINE 100%" di header Dashboard (mockup `.badge-btn`).
class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.badgeBtnBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('OFFLINE 100%', style: AppText.badge),
    );
  }
}

/// Baris transaksi bergaya mockup `.tx-item`: avatar 40px, badge sumber,
/// chip mode, jam, nominal kanan + nama kategori di bawahnya.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.tx,
    this.categoryName,
    this.onTap,
  });

  final Transaction tx;
  final String? categoryName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.type == TxType.expense;
    final color = isExpense ? AppColors.expense : AppColors.income;

    return InkWell(
      onTap: onTap,
      child: Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpense ? Icons.arrow_downward : Icons.arrow_upward,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tx.merchant ?? (isExpense ? 'Pengeluaran' : 'Pemasukan'),
                  style: AppText.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    SourceBadge(source: tx.source),
                    const SizedBox(width: 6),
                    ModeChip(origin: tx.origin),
                    if (tx.note != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          tx.note!,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              TabularNumber(
                text: '${isExpense ? '-' : '+'} ${formatRp(tx.amount)}',
                style: AppText.txAmount.copyWith(color: color),
              ),
              if (categoryName != null) ...[
                const SizedBox(height: 2),
                Text(categoryName!, style: AppText.caption),
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }
}

/// Donut chart kategori pengeluaran via fl_chart (FR-08, DBD §5)
class CategoryDonutChart extends ConsumerWidget {
  const CategoryDonutChart({super.key});

  static const List<Color> palette = [
    Color(0xFF2563EB), // Blue (Opsi A accent)
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF64748B), // Slate / Lainnya
  ];


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(categoryExpensesProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Breakdown Kategori',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            expenses.when(
              loading: () => const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator())),
              error: (e, _) => Text('Gagal: $e'),
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('Belum ada pengeluaran di periode ini.',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  );
                }

                final total =
                    items.fold<int>(0, (sum, item) => sum + item.total);

                return Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 28,
                          sections: [
                            for (var i = 0; i < items.length; i++)
                              PieChartSectionData(
                                value: items[i].total.toDouble(),
                                color: palette[i % palette.length],
                                showTitle: false,
                                radius: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < items.take(4).length; i++) ...[
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: palette[i % palette.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    items[i].categoryName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                Text(
                                  '${total > 0 ? ((items[i].total / total) * 100).toStringAsFixed(0) : 0}%',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formatRp(items[i].total),
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            if (i < items.take(4).length - 1)
                              const SizedBox(height: 4),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
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
      trailing: TabularNumber(
        text: '${isExpense ? '-' : '+'} ${formatRp(tx.amount)}',
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
          Semantics(
            label: 'Nominal saat ini ${_amount.isEmpty ? '0' : _amount} rupiah',
            liveRegion: true,
            child: TabularNumber(
              text: _amount.isEmpty ? 'Rp 0' : 'Rp $_amount',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          // Keypad 1-9, 0, 00, backspace (DBD §5: nominal cepat).
          for (final row in [['1','2','3'],['4','5','6'],['7','8','9'],['00','0','⌫']])
            Row(
              children: [
                for (final k in row)
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: k == '⌫' ? 'Hapus digit terakhir' : 'Angka $k',
                      child: TextButton(
                        // DBD §9: target sentuh minimal 48×48dp
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
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

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  Future<void> _openQuickCash(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const QuickCashSheet(),
      );

  static const _titles = {
    0: 'Ringkasan Uangku',
    1: 'Riwayat Transaksi',
    2: 'Pengaturan',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedTabProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tab == 0) const Text('Halo, Bima', style: AppText.greeting),
            Text(_titles[tab]!, style: AppText.screenTitle),
          ],
        ),
        actions: [
          if (tab == 0)
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child: _OfflineBadge(),
            ),
        ],
      ),
      body: tab == 0
          ? const _DashboardTab()
          : (tab == 1 ? const _FeedTab() : const _SettingsTab()),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openQuickCash(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) =>
            ref.read(selectedTabProvider.notifier).state = i,
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
        ref.invalidate(categoryExpensesProvider);
        ref.invalidate(feedProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 0, AppSpacing.screen, 84),
        children: [
          const StatusBanner(),
          const SizedBox(height: AppSpacing.gap),
          const PeriodSelector(),
          const SizedBox(height: AppSpacing.gap),
          const CashFlowCard(),
          const SizedBox(height: AppSpacing.gap),
          const CategoryDonutChart(),
          const SizedBox(height: AppSpacing.gap),
          // Kartu "Transaksi Terbaru" + tautan "Lihat Semua" (mockup).
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transaksi Terbaru', style: AppText.sectionTitle),
                      TextButton(
                        onPressed: () =>
                            ref.read(selectedTabProvider.notifier).state = 1,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  feed.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => ErrorState(
                      message: 'Gagal memuat transaksi: $e',
                      onRetry: () => ref.invalidate(feedProvider),
                    ),
                    data: (items) => items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: EmptyState(
                              icon: Icons.add_circle_outline,
                              message:
                                  'Belum ada transaksi di periode ini.\nTap + untuk catat pengeluaran tunai.',
                            ),
                          )
                        : Column(
                            children: [
                              for (final t in items.take(5))
                                TransactionRow(
                                  tx: t,
                                  categoryName: ref
                                      .watch(categoryNameMapProvider)
                                      .value?[t.categoryId],
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TransactionDetailScreen(tx: t),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter sumber dana feed (FR-09). `null` = semua sumber.
final feedSourceFilterProvider = StateProvider<TxSource?>((ref) => null);

final filteredFeedProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final source = ref.watch(feedSourceFilterProvider);
  final all = await repo.feed();
  return source == null ? all : all.where((t) => t.source == source).toList();
});

class _FeedTab extends ConsumerWidget {
  const _FeedTab();

  static const _monthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static String _formatDateGroup(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(d.year, d.month, d.day);

    final dateStr = '${d.day} ${_monthNames[d.month]} ${d.year}';
    if (target == today) return 'Hari Ini · $dateStr';
    if (target == yesterday) return 'Kemarin · $dateStr';
    return dateStr;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(filteredFeedProvider);
    final selected = ref.watch(feedSourceFilterProvider);
    final categoryMap = ref.watch(categoryNameMapProvider).value ?? {};

    Widget filterChip(String label, TxSource? value, {Widget? badge}) {
      final isSelected = selected == value;
      return GestureDetector(
        onTap: () => ref.read(feedSourceFilterProvider.notifier).state = value,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null) ...[
                badge,
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.fg,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Filter baris atas (mockup: pill 36px ber-badge)
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen, vertical: 8),
            children: [
              filterChip('Semua', null),
              const SizedBox(width: 8),
              filterChip('BTN', TxSource.BTN),
              const SizedBox(width: 8),
              filterChip('GoPay', TxSource.GOPAY),
              const SizedBox(width: 8),
              filterChip('Tunai', TxSource.CASH),
            ],
          ),
        ),
        Expanded(
          child: feed.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              message: 'Gagal memuat riwayat: $e',
              onRetry: () => ref.invalidate(filteredFeedProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  message:
                      'Belum ada transaksi untuk filter ini.\nCoba pilih filter lain atau catat tunai.',
                );
              }

              // Grouping transaksi per tanggal kalender (mockup option-a)
              final groups = <String, List<Transaction>>{};
              for (final tx in items) {
                final d = DateTime.fromMillisecondsSinceEpoch(tx.occurredAt);
                final key = _formatDateGroup(d);
                groups.putIfAbsent(key, () => []).add(tx);
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen, 8, AppSpacing.screen, 84),
                children: [
                  for (final entry in groups.entries) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.card),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            for (final t in entry.value)
                              TransactionRow(
                                tx: t,
                                categoryName: categoryMap[t.categoryId],
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TransactionDetailScreen(tx: t),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.gap),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SettingsTab extends ConsumerWidget {
  const _SettingsTab();

  Widget _statusPill({required bool active, required String activeText, required String inactiveText, bool isWarn = false}) {
    final bg = active
        ? AppColors.incomeBg
        : (isWarn ? AppColors.warnBg : AppColors.expenseBg);
    final border = active
        ? AppColors.incomeBorder
        : (isWarn ? AppColors.warnBorder : AppColors.expenseBorder);
    final text = active
        ? AppColors.incomeText
        : (isWarn ? AppColors.warnText : AppColors.expenseText);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        active ? activeText : inactiveText,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listener = ref.watch(listenerStatusProvider);
    final battery = ref.watch(batteryStatusProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, 8, AppSpacing.screen, 84),
      children: [
        // Card Status listener hardware (mockup option-a)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status listener hardware', style: AppText.sectionTitle),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    await PlatformBridge.openNotificationAccessSettings();
                    ref.invalidate(listenerStatusProvider);
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Notification Access', style: AppText.body),
                            SizedBox(height: 2),
                            Text('Menangkap notifikasi BTN & GoPay',
                                style: AppText.caption),
                          ],
                        ),
                      ),
                      listener.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, s) => _statusPill(
                            active: false, activeText: 'AKTIF', inactiveText: 'MATI'),
                        data: (enabled) => _statusPill(
                          active: enabled,
                          activeText: 'AKTIF',
                          inactiveText: 'MATI',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: AppColors.borderSoft),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Whitelist Baterai (OEM)', style: AppText.body),
                          SizedBox(height: 2),
                          Text('Mencegah OS mematikan listener',
                              style: AppText.caption),
                        ],
                      ),
                    ),
                    battery.when(
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => _statusPill(
                          active: false, activeText: 'AKTIF', inactiveText: 'CEK SETELAN', isWarn: true),
                      data: (ignored) => _statusPill(
                        active: ignored,
                        activeText: 'AKTIF',
                        inactiveText: 'CEK SETELAN',
                        isWarn: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.gap),

        // Menu Card (mockup option-a)
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Log Notifikasi Mentah & Regex', style: AppText.body),
                trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ParserLogScreen()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gap),

        // Privacy Assurance Card (mockup option-a)
        Card(
          color: AppColors.surfaceSubtle,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.card, vertical: 20),
            child: Column(
              children: const [
                Icon(Icons.lock_outline, size: 28, color: AppColors.accent),
                SizedBox(height: 8),
                Text('100% Offline & Privat', style: AppText.sectionTitle),
                SizedBox(height: 6),
                Text(
                  'Uangku tidak meminta izin INTERNET. Seluruh transaksi, saldo, dan log notifikasi hanya tersimpan di memori ponselmu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
