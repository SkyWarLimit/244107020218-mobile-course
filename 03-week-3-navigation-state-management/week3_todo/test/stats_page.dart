import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==========================================
// 1. REPOSITORY (Layer Data)
// ==========================================
// Memisahkan logika pengambilan data agar mudah di-mock saat unit test.
class StatsRepository {
  Future<List<String>> fetchStats() async {
    // Mensimulasikan delay jaringan selama 2 detik
    await Future.delayed(const Duration(seconds: 2));
    
    // Mensimulasikan 30% kemungkinan gagal (error)
    final random = Random();
    if (random.nextDouble() < 0.3) {
      throw Exception('Koneksi terputus. Gagal mengambil data.');
    }
    
    // Jika berhasil, kembalikan 3 data dummy
    return [
      'Total Pengguna: 1,500',
      'Pendapatan: Rp 5.000.000',
      'Sesi Aktif: 340'
    ];
  }
}

// Provider untuk mendistribusikan StatsRepository
final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository();
});

// ==========================================
// 2. NOTIFIER (Layer Logika / State Management)
// ==========================================
// Menggunakan AsyncNotifier karena kita berurusan dengan data asynchronous (Future)
class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    // Fungsi build akan dipanggil pertama kali saat provider di-listen.
    // Kita mengambil instance repository dari ref dan memanggil fungsinya.
    return ref.read(statsRepositoryProvider).fetchStats();
  }

  // Fungsi untuk melakukan retry ketika terjadi error
  Future<void> retry() async {
    // Set state kembali ke loading (agar spinner muncul lagi)
    state = const AsyncValue.loading();
    
    // Menjalankan ulang fetchStats dan membungkus hasilnya dalam AsyncValue
    // guard() secara otomatis menangkap error dan mengubahnya menjadi AsyncError
    state = await AsyncValue.guard(() => ref.read(statsRepositoryProvider).fetchStats());
  }
}

// Provider utama yang akan di-consume oleh UI
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);

// ==========================================
// 3. UI (Layer Presentasi)
// ==========================================
class StatsPage extends ConsumerWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau perubahan state dari statsProvider
    final statsState = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
      ),
      // Pola pattern-matching 'when' untuk menangani 3 kondisi AsyncValue
      body: statsState.when(
        // Kondisi 1: Loading
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        
        // Kondisi 2: Error
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              // Tombol Retry untuk memanggil fungsi retry() di notifier
              ElevatedButton(
                onPressed: () => ref.read(statsProvider.notifier).retry(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        
        // Kondisi 3: Sukses (Data tersedia)
        data: (stats) => ListView.builder(
          itemCount: stats.length, // Menampilkan tepat 3 item sesuai spesifikasi
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(stats[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}