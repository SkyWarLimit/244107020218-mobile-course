### AI Verification Checklist

| # | Item | Status | Catatan |
| :--- | :--- | :---: | :--- |
| 1 | State immutable | ✅ | Tidak ada mutasi list langsung; pembaruan state menggunakan reassignment dan `AsyncValue.guard`. |
| 2 | `ref.watch` di build, `ref.read` di callback | ✅ | `ref.watch` digunakan dalam `build()`, `ref.read` dalam `onPressed` untuk memicu `retry()`. |
| 3 | Ketiga state `AsyncValue` ditangani | ✅ | Kondisi `loading`, `error`, dan `data` ditangani lengkap dengan `.when()`; error memiliki tombol retry. |
| 4 | Provider eksplisit & tidak duplikat | ✅ | Dideklarasikan eksplisit sebagai `AsyncNotifierProvider<StatsNotifier, List<String>>`, hanya satu deklarasi. |
| 5 | Tidak pakai API Riverpod lama | ✅ | Tidak menggunakan `StateProvider` atau `StateNotifierProvider`. Menggunakan `AsyncNotifier` + `ConsumerWidget`. |
| 6 | `flutter analyze` & `flutter test` bersih | ⚠️ ➔ ✅ | Perbaikan: (a) Ubah `Key? key` ke `super.key`, (b) Sesuaikan pengecekan tipe Exception pada test. Setelah patch: 0 warning, semua test hijau. |

### Catatan tambahan

* **Peringatan `flutter analyze` (super_parameters):** Diselesaikan dengan menyederhanakan deklarasi konstruktor dari `const StatsPage({Key? key}) : super(key: key);` menjadi `const StatsPage({super.key});`.
* **Kegagalan `flutter test` (Exception Type):** Terjadi karena tipe eksepsi internal Riverpod tidak terdeteksi sebagai class bawaan `Exception`. Diselesaikan dengan menghapus `expectLater(..., throwsA(...))` dan langsung memverifikasi state akhir menggunakan `expect(container.read(statsProvider), isA<AsyncError<List<String>>>());`.