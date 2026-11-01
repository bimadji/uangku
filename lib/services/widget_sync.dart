import 'package:uangku/data/database.dart';
import 'package:uangku/data/transaction_repository.dart';
import 'package:uangku/services/widget_bridge.dart';

/// Sinkronkan angka widget home screen dengan pengeluaran hari ini.
/// Dipanggil setiap kali transaksi berubah agar widget tidak menampilkan
/// angka basi (DBD §7).
Future<void> syncWidget(AppDatabase db) async {
  final flow = await TransactionRepository(db).cashFlow(Period.day);
  await WidgetBridge.updateExpenseToday(flow.expense);
}