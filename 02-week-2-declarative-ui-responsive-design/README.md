
# Evaluasi Layout Responsif dan Aksesibilitas di Flutter

Dokumen ini berisi analisis mengenai penggunaan tata letak dalam Flutter, *trade-off* aksesibilitas, serta evaluasi implementasi kode pada dashboard akademik.

## 1. Perbandingan: GridView vs. LayoutBuilder + Column

### **GridView**
*   **Responsivitas:** Sangat baik dan praktis untuk menampilkan data dalam bentuk grid (seperti kartu ringkasan). Kita bisa dengan mudah memanipulasi jumlah kolom (`crossAxisCount`) berdasarkan lebar layar.
*   **Aksesibilitas (Trade-off):** Kelemahan utamanya terletak pada penggunaan `childAspectRatio`. Jika pengguna memperbesar ukuran font pada sistem perangkat (fitur *Dynamic Type*) demi kebutuhan aksesibilitas visual, teks di dalam grid sering kali terpotong atau mengalami *overflow* vertikal karena tinggi item dipaksa mengikuti rasio lebar-tinggi yang kaku.

### **LayoutBuilder + Column (atau SingleChildScrollView dengan Wrap)**
*   **Responsivitas:** Membutuhkan sedikit logika tambahan (*boilerplate*) untuk mengatur *reflow* menjadi banyak kolom. Menggunakan `Column` secara tunggal kurang efisien untuk layar lebar (seperti tablet/desktop) karena akan menyisakan terlalu banyak ruang kosong horizontal.
*   **Aksesibilitas (Trade-off):** Sangat ramah aksesibilitas. Karena `Column` membiarkan setiap *child* menyesuaikan tinggi intrinsiknya (*wrap content*), teks yang diperbesar oleh sistem tidak akan terpotong; tinggi kontainer akan bertambah ke bawah secara alami.

---

## 2. Kapan `Expanded` Menyebabkan *Overflow* dalam `Row`?

Widget `Expanded` dirancang untuk mengisi sisa ruang (*bounded constraints*) di dalam widget Flex seperti `Row` atau `Column`. Jika Anda menempatkan `Row` di dalam *parent* yang memiliki ruang tak terbatas di sumbu tersebut (*unbounded width*), seperti `SingleChildScrollView` dengan arah *scroll* horizontal, `Expanded` akan kebingungan mencari tahu batas akhir dari ruang tersisa yang harus ia isi. Hal ini memicu *layout error* (RenderFlex overflow).

## 3. Evaluasi Implementasi Kode Praktikum (main.dart)

Berdasarkan implementasi kode pada dashboard akademik yang dibuat, berikut adalah hasil evaluasinya:

Responsivitas di Bawah 600px: Layout tetap responsif. Kode menetapkan variabel kWideBreakpoint = 700. Melalui LayoutBuilder, layar dengan lebar di bawah 700px (termasuk layar berukuran di bawah 600px) akan otomatis merender 1 kolom saja (jumlahKolom == 1).

Dampak pada Aksesibilitas: Meskipun sudah ada inisiatif penambahan widget Semantics pada tombol switch mode gelap untuk screen reader, penggunaan childAspectRatio: jumlahKolom == 1 ? 3.0 : 2.0 di dalam GridView.count berisiko menurunkan aksesibilitas. Jika pengguna memperbesar font sistem secara ekstrim, ukuran DashboardCard yang dipaksa mengikuti rasio statis 3.0 atau 2.0 dapat membuat teks (seperti teks nilai IPK atau SKS) saling menumpuk atau mengalami overflow.

Ketersediaan Widget: Semua widget yang digunakan—seperti CupertinoSwitch, GridView.count, LayoutBuilder, Semantics, serta properti Material 3 seperti colorSchemeSeed—sepenuhnya tersedia dan didukung pada versi stabil Flutter saat ini. Tidak ada widget berstatus deprecated (usang) yang digunakan.

### Contoh Kode yang Gagal (Error)
```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal, // Parent memiliki lebar tidak terbatas (unbounded)
  child: Row(
    children: [
      Icon(Icons.person),
      // Expanded tidak tahu batas akhir layar, sehingga error
      Expanded(
        child: Text('Nama Mahasiswa yang panjang'), 
      ),
    ],
  ),
)

### Contoh Kode yang Gagal (Error)

Ganti Expanded dengan widget yang memberikan ukuran pasti, batasi lebar parent, atau hapus pembungkus scroll jika tujuannya hanya untuk mengisi lebar layar.

Solusi 1: Hapus SingleChildScrollView jika tidak butuh scroll

Row(
  children: [
    Icon(Icons.person),
    Expanded(
      child: Text('Nama Mahasiswa yang panjang'), 
    ),
  ],
)

Solusi 2: Jika memang butuh scroll, berikan ukuran pasti (SizedBox)

SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      Icon(Icons.person),
      SizedBox(
        width: 200, // Berikan ukuran pasti alih-alih Expanded
        child: Text('Nama Mahasiswa yang panjang'),
      ),
    ],
  ),
)



