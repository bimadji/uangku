
import 'package:flutter/material.dart';

/// State kosong/loading/error yang konsisten di seluruh aplikasi (DBD §8).
/// Dipakai Dashboard, Feed Transaksi, dan Log Parser.

/// Placeholder untuk state kosong dengan pesan + aksi (DBD §8).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.receipt_long_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: const Color(0xFF2563EB),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Placeholder untuk state error lokal (tanpa jaringan, DB error) (DBD §8).
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                child: const Text('Coba lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Angka dengan digit rata (DBD §4: tabular figures).
class TabularNumber extends StatelessWidget {
  const TabularNumber({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: (style ?? const TextStyle()).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
