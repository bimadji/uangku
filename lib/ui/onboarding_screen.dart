import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uangku/services/platform_bridge.dart';
import 'package:uangku/ui/dashboard_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0; // 0: Sambutan/Privasi, 1: Notification Access, 2: Whitelist Baterai
  bool _listenerGranted = false;
  bool _batteryIgnored = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final listener = await PlatformBridge.isListenerEnabled();
    final battery = await PlatformBridge.isBatteryOptimizationIgnored();
    if (mounted) {
      setState(() {
        _listenerGranted = listener;
        _batteryIgnored = battery;
      });
      ref.invalidate(listenerStatusProvider);
      ref.invalidate(batteryStatusProvider);
    }
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selamat Datang di Uangku'),
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Lewati', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Stepper
              Row(
                children: [
                  for (int i = 0; i < 3; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _step ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),

              // Step Content
              Expanded(
                child: SingleChildScrollView(
                  child: _buildStepContent(),
                ),
              ),

              // Bottom Actions
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.shield_outlined, size: 40, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 24),
            const Text(
              '100% Offline & Privat',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Uangku mencatat keuanganmu tanpa koneksi internet. Data finansial, saldo, dan mutasimu 100% aman hanya tersimpan di ponsel ini.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tanpa server, tanpa login, bebas biaya.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.notifications_active_outlined, size: 40, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Akses Notifikasi Otomatis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Izinkan Uangku membaca notifikasi dari Bale by BTN dan GoPay agar transaksi QRIS/transfer tercatat otomatis tanpa repot input manual.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _listenerGranted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _listenerGranted ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _listenerGranted ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: _listenerGranted ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _listenerGranted
                          ? 'Izin Akses Notifikasi telah Aktif'
                          : 'Izin Belum Diberikan. Ketuk tombol di bawah untuk membuka Pengaturan.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _listenerGranted ? const Color(0xFF14532D) : const Color(0xFF78350F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                await PlatformBridge.openNotificationAccessSettings();
                await Future.delayed(const Duration(milliseconds: 500));
                await _checkPermissions();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Buka Pengaturan Akses Notifikasi'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      case 2:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.battery_charging_full_rounded, size: 40, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Optimasi Baterai (OEM)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Beberapa ponsel (Xiaomi, Oppo, Vivo) sering mematikan aplikasi di latar belakang. Pastikan Uangku dikecualikan dari penghemat baterai agar pencatatan tidak terhenti.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _batteryIgnored ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    _batteryIgnored ? Icons.check_circle : Icons.info_outline,
                    color: _batteryIgnored ? const Color(0xFF15803D) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _batteryIgnored
                          ? 'Optimasi Baterai sudah Diabaikan'
                          : 'Tips: Buka Info Aplikasi Uangku > Penghemat Baterai > Pilih "Tidak Ada Pembatasan".',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        FilledButton(
          onPressed: () async {
            if (_step == 0) {
              // Minta izin notifikasi runtime (Android 13+) sebelum lanjut
              await PlatformBridge.requestPostNotificationsPermission();
            }
            if (_step < 2) {
              await _checkPermissions();
              setState(() => _step++);
            } else {
              _finish();
            }
          },
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _step < 2 ? 'Lanjut' : 'Mulai Gunakan Uangku',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
