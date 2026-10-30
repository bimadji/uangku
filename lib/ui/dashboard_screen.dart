import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uangku/data/database.dart';
import 'package:uangku/data/transaction_repository.dart';

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

// ---- UI Komponen Inti (DBD §5) ----

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

// ---- Layar Utama (AFD §1: 3 Tab) ----

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Dashboard' : (_tab == 1 ? 'Transaksi' : 'Pengaturan')),
      ),
      body: _tab == 0
          ? const _DashboardTab()
          : (_tab == 1 ? const _FeedTab() : const _SettingsTab()),
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

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Uangku v1.0.0 (MVP)', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Penyimpanan 100% lokal. Tanpa server, tanpa login (FR-12).',
            style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
