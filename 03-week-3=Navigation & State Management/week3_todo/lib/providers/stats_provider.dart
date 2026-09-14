import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// AsyncNotifier mengelola state asynchronous List
class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    // Simulasi latency jaringan selama 2 detik
    await Future.delayed(const Duration(seconds: 2));

    // Simulasi kegagalan acak 30% (Random double < 0.3)
    final random = Random();
    if (random.nextDouble() < 0.3) {
      throw Exception('Gagal memuat statistik dari server (Koneksi Terputus)');
    }

    // Mengembalikan list data immutable jika berhasil
    return const [
      'Total Pengguna Aktif: 1.250',
      'Rata-rata Durasi Sesi: 4m 32s',
      'Tingkat Retensi Mingguan: 78.4%',
    ];
  }
}

// Provider dideklarasikan dengan tipe generik eksplisit
final statsProvider =
  AsyncNotifierProvider<StatsNotifier, List<String>>(StatsNotifier.new);