// Spike T-003: Riverpod vs Provider — async state (simulasi feed).
// Keputusan final: RIVERPOD (lihat RESULT.md). Package `provider` dihapus
// dari pubspec; bagian Provider dipertahankan sebagai catatan komentar.


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:flutter_test/flutter_test.dart';

// ---- simulasi data (tanpa DB) ----
class FeedEntry {
  const FeedEntry(this.title, this.amount);
  final String title;
  final int amount;
}

Future<List<FeedEntry>> fakeFetch() => Future.delayed(
    const Duration(milliseconds: 10),
    () => const [FeedEntry('Kopi', 18000), FeedEntry('Gaji', 5000000)]);

// ================= RIVERPOD (dipilih) =================
final feedRiverpodProvider =
    rp.FutureProvider<List<FeedEntry>>((ref) => fakeFetch());

class RiverpodTotalView extends rp.ConsumerWidget {
  const RiverpodTotalView({super.key});

  @override
  Widget build(BuildContext context, rp.WidgetRef ref) {
    final feed = ref.watch(feedRiverpodProvider);
    return feed.when(
      loading: () => const Text('loading'),
      error: (e, _) => Text('error: $e'),
      data: (entries) =>
          Text('total: ${entries.fold<int>(0, (s, e) => s + e.amount)}'),
    );
  }
}

// ================= PROVIDER (dibuang — catatan saja) =================
// Versi lama butuh: package:provider + ChangeNotifier manual:
//   - flag loading/error ditulis sendiri di FeedModel
//   - notifyListeners() manual setelah tiap fetch
//   - widget: context.watch<FeedModel>() + if/else manual
//   - unit test state tanpa widget tree: tidak langsung didukung
// Keputusan: lihat RESULT.md.

void main() {
  group('Riverpod', () {
    testWidgets('loading -> data (total terhitung)', (tester) async {
      await tester.pumpWidget(rp.ProviderScope(
          child: const MaterialApp(home: RiverpodTotalView())));
      expect(find.text('loading'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('total: 5018000'), findsOneWidget);
    });

    test('unit test provider tanpa widget', () async {
      final container = rp.ProviderContainer();
      addTearDown(container.dispose);
      final entries = await container.read(feedRiverpodProvider.future);
      expect(entries, hasLength(2));
    });
  });
}
