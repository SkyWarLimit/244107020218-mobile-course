# AI Challenge Documentation - Week 5

Dokumen ini mendokumentasikan analisis perbandingan solusi penyimpanan lokal (*local storage*) dan arsitektur *offline-first* untuk aplikasi Catatan Offline Flutter.

Salinan utama dokumentasi ini juga dapat diakses langsung pada:
[AI Challenge Folder](../AI%20challenge/README.md)

---

## 1. Prompt AI

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
| **Preferensi Tema & Waktu Terbuka** | **SharedPreferences** | Paling tepat dan ringan untuk data primitif tunggal (`dark_mode: bool`, `last_opened_at: String`). Tidak membutuhkan struktur tabel SQL, overhead memori sangat minim, dan mudah diuji dengan mock. |
| **CRUD Catatan Persisten** | **sqflite (SQLite)** | Sangat stabil untuk kapasitas catatan besar (1000+ item) dengan dukungan indexing dan sorting `ORDER BY updated_at DESC`. Mengurangi konsumsi memori dan mendukung dirty flag untuk arsitektur *offline-first*. |

---

## 4. Desain Skema Database (1000+ Catatan, Offline-First)

```sql
CREATE TABLE notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uuid TEXT UNIQUE,                   -- UUID v4 unik global
    title TEXT NOT NULL,                -- Judul catatan
    body TEXT NOT NULL DEFAULT '',      -- Isi detail catatan
    created_at TEXT NOT NULL,           -- Timestamp pembuatan (ISO-8601 UTC)
    updated_at TEXT NOT NULL,           -- Timestamp perbaruan (sorting & LWW conflict resolution)
    dirty INTEGER NOT NULL DEFAULT 0,   -- Status sync: 1 = kotor/belum sync, 0 = synced
    is_deleted INTEGER NOT NULL DEFAULT 0 -- Soft delete flag
);

-- Indeks performa:
CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);
CREATE INDEX idx_notes_dirty ON notes(dirty);
CREATE INDEX idx_notes_is_deleted ON notes(is_deleted);
```

---

## 5. Ringkasan Trade-Off

* **SharedPreferences**: Efisien untuk preferensi konfigurasi kecil. Dilarang untuk menyimpan ribuan entitas catatan karena membebani I/O dan RAM.
* **Hive**: Sangat cepat untuk NoSQL key-value ringan, namun seluruh entitas dimuat di RAM dan fitur querying/filtering terbatas untuk relasi data.
* **sqflite**: Solusi RDBMS standar industri yang sangat tangguh untuk dataset ribuan catatan, indexing cepat, dan transaksi ACID aman.
* **Drift**: Solusi type-safe tingkat lanjut dengan reaktivitas stream bawaan, namun memiliki overhead build generator (`build_runner`) yang tinggi.
