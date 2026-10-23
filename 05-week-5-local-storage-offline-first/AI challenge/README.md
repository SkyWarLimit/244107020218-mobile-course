# AI Challenge - Week 5: Local Storage & Offline-First

Dokumentasi ini berisi hasil pengerjaan **AI Prompt Challenge** untuk penentuan solusi penyimpanan data lokal (*Local Storage*) dan arsitektur *Offline-First* pada aplikasi Flutter Catatan (*Offline Notes*).

---

## 1. Prompt AI yang Digunakan

```text
Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift untuk dua kebutuhan ini.
Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream), type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan, beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan.
- Jelaskan trade-off setiap pilihan.
```

---

## 2. Tabel Perbandingan Solusi Penyimpanan (*Storage Comparison*)

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift (Moor) |
| :--- | :--- | :--- | :--- | :--- |
| **Kompleksitas Query** | Sangat Rendah (*Key-Value* primitif) | Rendah (Filter manual di memori/RAM) | Tinggi (Raw SQL, pagination `LIMIT/OFFSET`, sorting `ORDER BY`) | Tinggi (Query builder deklaratif, *type-safe*, pagination) |
| **Kebutuhan Relasi** | Tidak mendukung relasi | Tidak mendukung relasi (flat boxes) | Penuh (*Foreign Key*, *JOIN*, relasi tabel) | Penuh (*Type-safe relations*, relasi entitas terkompilasi) |
| **Reaktivitas (Stream)** | Tidak ada (manual polling/callback) | Ada (`box.watch()`) | Manual (perlu dibungkus StateNotifier / Riverpod) | Sangat Kuat (Auto-updating streams via SQL query watcher) |
| **Type-Safety** | Hanya tipe primitif (`bool`, `int`, `String`) | Menengah (Memerlukan generator `TypeAdapter`) | Rendah (Serialisasi `Map<String, dynamic>`, rawan typo kolom) | Sangat Tinggi (*Generated code*, validasi tipe sejak kompilasi) |
| **Ukuran Boilerplate** | Sangat Rendah (Langsung pakai tanpa setup rumit) | Sedang (Perlu adapter & registrasi box) | Sedang (SQL string schema & mapping manual) | Tinggi (Perlu konfigurasi `build_runner` & code generation) |
| **Kemudahan Testing** | Sangat Mudah (`SharedPreferences.setMockInitialValues`) | Mudah (Mendukung in-memory box) | Sulit (Memerlukan mock atau native SQLite library) | Mudah (Mendukung in-memory SQLite database murni) |

---

## 3. Keputusan Final & Rekomendasi Teknis

| Kebutuhan Aplikasi | Solusi Terpilih | Alasan Teknis |
| :--- | :--- | :--- |
| **Preferensi Tema & Waktu Terbuka** | **SharedPreferences** | Pilihan paling efisien untuk data konfigurasi tunggal (*key-value* primitif) seperti status `dark_mode` (boolean) dan timestamp `last_opened_at` (ISO String). Tidak memerlukan struktur tabel relasional, overhead memori sangat minim, dan integrasi pengujian sangat mudah. |
| **CRUD Catatan Persisten** | **sqflite (SQLite)** *(Opsi Produksi: Drift)* | Menangani volume catatan besar (1000+ catatan) secara efisien dengan indexing, *sorting* terindeks `ORDER BY updated_at DESC`, dan pagination tanpa membebani RAM perangkat. Struktur tabel mendukung flag sinkronisasi (`dirty`) untuk arsitektur *offline-first*. |

---

## 4. Desain Skema Database (Kapasitas 1000+ Catatan, Offline-First)

Untuk menangani skala 1000+ catatan tanpa latensi pada perangkat mobile, skema tabel SQLite dirancang sebagai berikut:

```sql
CREATE TABLE notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uuid TEXT UNIQUE,                   -- UUID v4 untuk sinkronisasi client-server tanpa bentrok ID
    title TEXT NOT NULL,                -- Judul catatan
    body TEXT NOT NULL DEFAULT '',      -- Isi detail catatan
    created_at TEXT NOT NULL,           -- Timestamp pembuatan (ISO-8601 UTC)
    updated_at TEXT NOT NULL,           -- Timestamp update terakhir (digunakan untuk sorting & LWW conflict resolution)
    dirty INTEGER NOT NULL DEFAULT 0,   -- Flag status sync: 1 = kotor/belum sync, 0 = synced
    is_deleted INTEGER NOT NULL DEFAULT 0 -- Soft-delete flag (tidak langsung drop agar server tahu ada catatan terhapus)
);

-- Indeks performa untuk query cepat di 1000+ data:
CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);
CREATE INDEX idx_notes_dirty ON notes(dirty);
CREATE INDEX idx_notes_is_deleted ON notes(is_deleted);
```

### Penjelasan Atribut Skema:
1. **`uuid` (Identitas Global)**: Menghindari tabrakan ID saat banyak catatan dibuat dalam kondisi offline sebelum dikirim ke database backend.
2. **`updated_at` (Sorting & Resolusi Konflik)**: Menjadi acuan utama penyusunan daftar catatan terbaru dan resolusi konflik *Last-Write-Wins (LWW)*.
3. **`dirty` (Sinkronisasi)**: Catatan baru atau yang diedit lokal memiliki status `dirty = 1`. Saat sync berhasil diunggah ke server, diubah menjadi `0`.
4. **`is_deleted` (Soft Delete)**: Menghindari hilangnya jejak penghapusan saat perangkat offline. Server harus menerima status hapus terlebih dahulu sebelum data benar-benar di-purge secara lokal.
5. **Indeks**: Memastikan *query listing* dan filter catatan yang belum disinkronkan beroperasi pada waktu $O(\log N)$, bukan $O(N)$ *full table scan*.

---

## 5. Analisis Trade-Off Masing-Masing Storage

### A. SharedPreferences
* **Kelebihan**: Sangat ringan, tidak membutuhkan inisialisasi kompleks, bawaan platform Android (`SharedPreferences`) dan iOS (`NSUserDefaults`).
* **Kekurangan**: Tidak cocok untuk data koleksi atau relasi. Pembacaan seluruh XML/Plist ke memori menyebabkan *bottleneck I/O* jika dipaksakan menyimpan daftar catatan.
* **Keputusan**: Digunakan secara ketat hanya untuk preferensi aplikasi (Dark Mode & Last Opened).

### B. Hive
* **Kelebihan**: NoSQL key-value murni Dart, performa baca-tulis in-memory sangat kencang.
* **Kekurangan**: Seluruh indeks atau box dimuat ke RAM. Jika terdapat ribuan catatan panjang, konsumsi RAM melonjak drastis. Fitur query pencarian teks dan sorting sangat terbatas.
* **Keputusan**: Kurang optimal untuk kebutuhan pencarian dan pengurutan relasional data catatan besar.

### C. sqflite (SQLite)
* **Kelebihan**: Standar industri berbasis RDBMS SQLite. Sangat stabil, mendukung transaksi ACID, query SQL kompleks, indexing, dan pagination `LIMIT / OFFSET`.
* **Kekurangan**: Membutuhkan penulisan raw SQL string yang rentan typo jika tidak diuji dengan baik, serta membutuhkan integrasi wrapper Riverpod untuk menjadikannya reaktif.
* **Keputusan**: **Dipilih untuk implementasi project ini** karena menyeimbangkan performa tinggi, kemandirian tanpa build generator yang berat, dan fleksibilitas query relasional.

### D. Drift
* **Kelebihan**: Lapisan abstraksi di atas SQLite dengan generator Dart yang sangat type-safe, otomatis membuat reactive stream (`watch()`), serta mendukung web & native in-memory testing.
* **Kekurangan**: Waktu kompilasi lebih lama karena dependensi pada `build_runner` dan ukuran boilerplate kode generator yang besar.
* **Keputusan**: Solusi ideal untuk aplikasi skala *enterprise / production*, namun sqflite lebih dari cukup dan efisien untuk ruang lingkup tugas ini.

---

## 6. Struktur Kode Implementasi

Implementasi nyata dari analisis ini tersedia pada proyek:
* **Proyek Utama**: [`week5_offline_notes/`](../week5_offline_notes/)
* **Proyek Eksperimen AI**: [`ai_challenge_notes/`](./ai_challenge_notes/)

Struktur lapisan arsitektur:
```
week5_offline_notes/lib/
├── main.dart                          # Root application, inisialisasi last_opened & reaktif dark theme
├── data/
│   ├── prefs.dart                     # SharedPreferences repository (Dark mode & last opened)
│   ├── providers.dart                 # Riverpod state management & offline notifier
│   ├── local/
│   │   ├── db.dart                    # Inisialisasi SQLite database & skema tabel
│   │   └── note.dart                  # Model Note (serialisasi toMap/fromMap, copyWith)
│   └── repositories/
│       └── note_repository.dart       # Operasi CRUD SQLite, countDirty, markAllSynced, & syncNotes
└── pages/
    ├── notes_page.dart                # UI Catatan: CRUD lengkap, badge dirty, dialog edit & konfirmasi hapus
    └── settings_page.dart             # UI Pengaturan: Toggle dark mode, display last opened, & simulasi mode pesawat
```
