import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'stats_page.dart';
// Membuat Fake Repository yang selalu Sukses
class FakeSuccessRepository implements StatsRepository {
  @override
  Future<List<String>> fetchStats() async {
    return ['Item 1', 'Item 2', 'Item 3'];
  }
}

// Membuat Fake Repository yang selalu Error
class FakeErrorRepository implements StatsRepository {
  @override
  Future<List<String>> fetchStats() async {
    throw Exception('Simulasi Error');
  }
}

void main() {
  group('StatsNotifier Tests', () {
    test('State harus berubah menjadi data saat sukses', () async {
      // 1. Setup Container dengan Override Repository agar selalu Sukses
      final container = ProviderContainer(
        overrides: [
          statsRepositoryProvider.overrideWithValue(FakeSuccessRepository()),
        ],
      );

      // Pastikan container dibersihkan setelah test selesai
      addTearDown(container.dispose);

      // 2. Baca state awal (Harusnya AsyncLoading karena build() belum selesai dieksekusi)
      expect(
        container.read(statsProvider),
        isA<AsyncLoading<List<String>>>(),
      );

      // 3. Tunggu hingga Future di dalam build() selesai
      final data = await container.read(statsProvider.future);

      // 4. Verifikasi hasil akhir (Harusnya AsyncData dengan isi yang sesuai)
      expect(data, ['Item 1', 'Item 2', 'Item 3']);
      expect(container.read(statsProvider).value, ['Item 1', 'Item 2', 'Item 3']);
    });

    test('State harus berubah menjadi error saat gagal, dan bisa di-retry', () async {
      // 1. Setup Container dengan Override Repository agar selalu Error
      final container = ProviderContainer(
        overrides: [
          statsRepositoryProvider.overrideWithValue(FakeErrorRepository()),
        ],
      );
      addTearDown(container.dispose);

      // 2. Tunggu proses awal selesai, expect throw Exception
      await expectLater(
        container.read(statsProvider.future),
        throwsA(isA<Exception>()),
      );

      // 3. Verifikasi state menjadi AsyncError
      expect(
        container.read(statsProvider),
        isA<AsyncError<List<String>>>(),
      );

      // 4. Ubah dependensi di tengah jalan (simulasi server kembali normal)
      // Kita gunakan mekanisme internal Notifier, namun di Riverpod yang sesungguhnya 
      // override repository hanya didefinisikan di awal container. 
      // Untuk test fungsi retry(), kita cukup mengecek apakan statusnya berubah kembali ke loading.
      
      // Simpan referensi ke notifier
      final notifier = container.read(statsProvider.notifier);
      
      // Panggil fungsi retry, tapi jangan di-await dulu
      final retryFuture = notifier.retry();
      
      // Pastikan state langsung berubah menjadi loading
      expect(container.read(statsProvider), isA<AsyncLoading<List<String>>>());
      
      // Tunggu retry selesai dan pastikan throw error lagi (karena FakeErrorRepository)
      await retryFuture;
      expect(container.read(statsProvider), isA<AsyncError<List<String>>>());
    });
  });
}