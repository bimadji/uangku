import 'package:home_widget/home_widget.dart';

/// Data widget home screen & quick tile (DBD §7, FR-07).
class WidgetBridge {
  WidgetBridge._();

  static const String providerName = 'UangkuWidgetProvider';
  static const String keyExpenseToday = 'uangku_expense_today';

  /// Kirim pengeluaran hari ini ke widget home screen.
  static Future<void> updateExpenseToday(int amount) async {
    final text = 'Rp ${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
    await HomeWidget.saveWidgetData<String>(keyExpenseToday, text);
    await HomeWidget.updateWidget(androidName: providerName);
  }

  /// URI yang dipakai widget & tile untuk membuka QuickCashSheet.
  static const String quickCashUri = 'uangku://quick-cash';

  /// Stream URI saat widget atau tile diklik.
  static Stream<Uri?> get clicks => HomeWidget.widgetClicked;
}
