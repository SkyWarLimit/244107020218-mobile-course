# Laporan Mini Project / Industry Challenge - Week 5
**Topik: Local Storage & Offline-First Notes Application**

---

## Ringkasan Tugas
Membangun aplikasi **Offline-First Notes** dengan Flutter yang mengintegrasikan:
1. **Preferensi Pengguna**: Toggle tema gelap/terang (*Dark/Light Mode*) serta pencatatan waktu terakhir aplikasi dibuka menggunakan `SharedPreferences`.
2. **CRUD Catatan Persisten**: Pengelolaan data catatan (*Create, Read, Update, Delete*) tersimpan di SQLite lokal melalui `sqflite` dan diakses secara terstruktur menggunakan `Riverpod`, dengan daftar diurutkan berdasarkan `updated_at DESC`.
3. **Arsitektur Offline-First**: Pendekatan *cache-first* untuk pembacaan data, *dirty flag* + fungsi `syncNotes` untuk penulisan data, dan aturan resolusi konflik eksplisit (*Last-Write-Wins*).
4. **Pembuktian Mode Pesawat**: Pengujian fungsionalitas saat perangkat offline (*airplane mode*) dengan indikator status *badge dirty* sebelum dan sesudah proses sinkronisasi.
5. **Pengujian Otomatis (*Automated Testing*)**: Pengujian unit (*Unit Test*) model `Note`, pengujian *Provider* menggunakan `FakeNoteRepository`, pengujian logika resolusi konflik, dan *Widget Smoke Test* (seluruh 8 pengujian berstatus lulus / *passed*).
6. **Dokumentasi AI Challenge**: Dokumentasi prompt, tabel perbandingan penyimpanan lokal, keputusan arsitektur, dan analisis teknis yang tersedia di [`AI challenge/`](./AI%20challenge/README.md) dan [`docs/`](./docs/ai_challenge.md).

---

## 1. Preferensi Pengguna (`SharedPreferences`)

### A. Fitur yang Diimplementasikan
* **Toggle Tema Gelap / Terang**: Preferensi tema disimpan secara persisten dengan kunci `'dark_mode'`. Nilai dibaca saat aplikasi dimulai dan perubahan tema diterapkan secara reaktif (*Material 3 ThemeMode*).
* **Waktu Terakhir Dibuka**: Setiap kali aplikasi dibuka, method `markOpenedNow()` mencatat stempel waktu ISO-8601 ke SharedPreferences dengan kunci `'last_opened_at'`. Nilai ini ditampilkan secara langsung pada halaman Pengaturan (*Settings Page*).

### B. Implementasi Kode
* File implementasi: [`lib/data/prefs.dart`](./week5_offline_notes/lib/data/prefs.dart)
```dart
class PrefsRepository {
  static const _darkModeKey = 'dark_mode';
  static const _lastOpenedKey = 'last_opened_at';

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> markOpenedNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastOpenedKey, DateTime.now().toIso8601String());
  }

  Future<String?> getLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastOpenedKey);
  }
}
```

* Pengikatan State Reaktif (`Riverpod` & `MyApp`):
```dart
// lib/data/providers.dart
final prefsRepositoryProvider = Provider<PrefsRepository>((ref) => PrefsRepository());

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

final darkModeProvider = AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);
```

---

## 2. CRUD Catatan Persisten (`sqflite` + `Riverpod`)

Catatan disimpan secara persisten pada database SQLite lokal (`offline_notes.db`). Semua operasi SQL dibungkus rapi di dalam `NoteRepository` agar lapisan antarmuka pengguna (*UI layer*) terpisah sepenuhnya dari *query* mentah.

### Operasi CRUD:
1. **Create (Tambah Catatan)**: Melalui tombol `FloatingActionButton` (+) yang memunculkan modal dialog. Catatan otomatis diberi status `dirty = 1` dan waktu `updatedAt = DateTime.now()`.
2. **Read (Daftar Catatan)**: Catatan diambil menggunakan `fetchNotes()` yang menjalankan query:
   ```sql
   SELECT * FROM notes ORDER BY updated_at DESC;
   ```
   Daftar selalu terurut dari catatan yang paling baru diperbarui.
3. **Update (Perbarui Catatan)**: Mengetuk (*tap*) salah satu catatan membuka dialog edit. Judul atau isi catatan dapat diubah; sistem akan memperbarui stempel waktu `updated_at` ke waktu terkini dan mengeset flag `dirty = 1`.
4. **Delete (Hapus Catatan)**: Menekan lama (*long press*) pada item memunculkan dialog konfirmasi sebelum menghapus baris dari database SQLite.

---

## 3. Arsitektur Offline-First & Resolusi Konflik

### A. Strategi Cache-First untuk Pembacaan
Data catatan selalu dibaca langsung dari basis data lokal SQLite (`openNotesDb()`), sehingga UI dapat merender catatan secara instan tanpa latensi jaringan dan tanpa koneksi internet sama sekali.

### B. Dirty Flag & `syncNotes`
* Ketika catatan dibuat atau disunting dalam kondisi luring (*offline*), kolom `dirty` bernilai `1` (*true*).
* Indikator UI menampilkan badge berwarna oranye (`Dirty / Cloud Off`).
* Tombol sinkronisasi di AppBar memicu fungsi `syncNotes(repo, isOffline)`:
  * **Saat Offline**: Fungsi langsung melempar `Exception` ramah pengguna, data lokal tetap utuh dan aman dengan flag `dirty = 1`.
  * **Saat Online**: Catatan kotor disimulasikan terkirim ke server backend. Setelah konfirmasi 2xx diterima, `markAllSynced()` dieksekusi untuk mereset kolom `dirty = 0` sehingga badge di UI berubah menjadi hijau (`Synced / Cloud Done`).

### C. Aturan Resolusi Konflik Eksplisit (*Explicit Conflict Resolution*)
Aturan sinkronisasi yang diadopsi adalah strategi **Last-Write-Wins (LWW)** berbasis stempel waktu `updated_at`:
1. **Client vs Server Timestamp**: Jika terdapat modifikasi data yang bersamaan antara klien dan peladen, catatan dengan stempel waktu `updated_at` paling baru yang akan dipertahankan.
2. **Server-Wins pada Data Kritis**: Jika catatan di server telah memiliki pembaruan lebih baru daripada versi lokal, server menolak pembaruan klien dan mengirimkan versi termutakhir untuk menimpa lokal (*overwrite local cache*).
3. **Atomic Batching**: Sinkronisasi dilakukan secara transaksional per kelompok ID catatan untuk mencegah inkonsistensi sebagian (*partial failure*).

---

## 4. Panduan Pembuktian Mode Pesawat (*Airplane Mode*)

Untuk membuktikan kesiapan *offline-first* pada perangkat nyata atau emulator:

1. **Uji Tambah Catatan Offline**:
   * Aktifkan **Mode Pesawat** pada perangkat (atau hidupkan switch **Mode Pesawat (Force Offline)** di menu Pengaturan).
   * Tambahkan catatan baru (misal: "Catatan saat Offline").
   * Hasil: Catatan berhasil tersimpan di SQLite lokal dan muncul di daftar paling atas dengan **Badge Dirty Oranye** (`Icons.cloud_off`).
2. **Uji Sinkronisasi Gagal Saat Offline**:
   * Tekan tombol *Sync* (ikon awan/panah melingkar di pojok kanan atas AppBar).
   * Hasil: Muncul SnackBar merah dengan pesan `"Simulasi: Aplikasi sedang offline (mode pesawat aktif)."`. Catatan tetap berstatus *Dirty*.
3. **Uji Sinkronisasi Berhasil Saat Online**:
   * Matikan **Mode Pesawat** (atau matikan switch Force Offline di Pengaturan).
   * Tekan tombol *Sync* kembali.
   * Hasil: Muncul SnackBar hijau `"Berhasil menyinkronkan X catatan kotor."`, dan badge pada catatan berubah menjadi **Badge Synced Hijau** (`Icons.cloud_done`).

> Tangkapan layar (*screenshots*) hasil pengujian dapat ditempatkan pada folder [`Screenshots/`](./Screenshots/).

---

## 5. Pengujian Otomatis (*Automated Tests*)

Pengujian dijalankan dengan perintah `flutter test` di dalam folder `week5_offline_notes/`. Seluruh 8 pengujian berhasil lulus (*100% Passed*):

```text
00:00 +0: Unit Test Model Note fromMap aman terhadap field yang hilang (fallback default)
00:00 +1: Unit Test Model Note flag dirty bertahan pada serialisasi toMap dan fromMap
00:00 +2: Unit Test Model Note copyWith membuat salinan dengan field yang diperbarui
00:00 +3: Provider Test dengan FakeNoteRepository provider sukses mengambil daftar catatan dari fake repository
00:00 +4: Provider Test dengan FakeNoteRepository provider menangani error database dari fake repository
00:00 +5: Logic Test: Offline-First & Resolusi Konflik (syncNotes) syncNotes melempar Exception saat aplikasi sedang offline (mode pesawat)
00:00 +6: Logic Test: Offline-First & Resolusi Konflik (syncNotes) syncNotes berhasil menyinkronkan data kotor saat online
00:01 +7: App smoke test - Menampilkan judul Catatan Offline
00:01 +8: All tests passed!
```

### Analisis Kode Statis:
Perintah `flutter analyze` berhasil dijalankan tanpa peringatan maupun *error*:
```text
Analyzing week5_offline_notes...
No issues found! (ran in 6.9s)
```

---

## 6. AI Challenge

Dokumentasi lengkap mengenai prompt AI, tabel analisis 4 solusi penyimpanan (*SharedPreferences*, *Hive*, *sqflite*, dan *Drift*), pertimbangan relasi, reaktivitas, kapasitas 1000+ catatan, serta alasan teknis keputusan dapat diakses pada tautan berikut:

* **Dokumentasi Utama AI Challenge**: [`AI challenge/README.md`](./AI%20challenge/README.md)
* **Salinan Dokumentasi Teknis**: [`docs/ai_challenge.md`](./docs/ai_challenge.md)
* **Proyek Flutter AI Challenge**: [`AI challenge/ai_challenge_notes/`](./AI%20challenge/ai_challenge_notes/)

### Ringkasan Tabel Rekomendasi:
| Kebutuhan | Rekomendasi | Alasan Utama |
| :--- | :--- | :--- |
| **Preferensi Tema & Waktu Terbuka** | **SharedPreferences** | Ringan, cepat, cocok untuk data primitif tunggal tanpa overhead database relasional. |
| **CRUD Catatan Persisten (1000+ Data)** | **sqflite (SQLite)** | Mendukung pengindeksan (*indexing*), query terurut `updated_at DESC`, hemat RAM, serta mendukung integrasi *dirty flag*. |

---

## Struktur Folder Proyek Week 5

```
05-week-5-local-storage-offline-first/
├── README.md                          # Laporan utama pengerjaan tugas Week 5
├── AI challenge/
│   ├── README.md                      # Dokumentasi AI Prompt Challenge & Storage Comparison
│   └── ai_challenge_notes/            # Eksperimen project AI Challenge
├── docs/
│   └── ai_challenge.md                # Dokumentasi AI Challenge (folder docs/)
├── Screenshots/                       # Folder tangkapan layar pembuktian offline mode
└── week5_offline_notes/               # Proyek Flutter utama aplikasi Offline Notes
    ├── lib/
    │   ├── main.dart                  # Entry point, dark mode provider, record last opened
    │   ├── data/
    │   │   ├── prefs.dart             # SharedPreferences repository (Dark mode & last opened)
    │   │   ├── providers.dart         # Riverpod providers, notifiers, & offline state
    │   │   ├── local/
    │   │   │   ├── db.dart            # Inisialisasi SQLite database
    │   │   │   └── note.dart          # Model Note dengan copyWith, toMap, fromMap
    │   │   └── repositories/
    │   │       └── note_repository.dart # CRUD SQLite, countDirty, markAllSynced, & syncNotes
    │   └── pages/
    │       ├── notes_page.dart        # Tampilan catatan: CRUD, dirty badge, sync button
    │       └── settings_page.dart     # Tampilan pengaturan: tema, waktu buka, mode offline
    └── test/
        ├── note_test.dart             # Unit test model, provider test, & logic test sync
        └── widget_test.dart           # Widget smoke test aplikasi
```
