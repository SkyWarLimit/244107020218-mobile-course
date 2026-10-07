# AI PROMPT CHALLENGE

### PROMPT AWAL
Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
Requirements:
- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
  dan fungsi pesan error
  ramah pengguna untuk timeout, connection error, 404, dan 500.
- Satu unit test untuk fromJson dengan field yang hilang.
Jelaskan setiap bagian kode dalam komentar.

#
### AI Verification Checklist

| # | Item | Status | Catatan |
| :--- | :--- | :---: | :--- |
| 1 | Pemisahan Layer (UI & Repository) | ✅ | UI (`PagedPostPage` dan `PostDetailPage`) tidak memanggil Dio secara langsung. Semua akses data dienkapsulasi lewat Riverpod (`postListProvider` / `pagedPostsProvider`) dan `PostRepository`. |
| 2 | Model *Crash-Free Null Safety* | ✅ | Fungsi `fromJson` pada model terbukti aman (diuji pada `comment_test.dart`). Menggunakan *fallback* nilai default (operator `??`) untuk mencegah *crash* akibat *null*. |
| 3 | Pemetaan Error Lengkap (*DioException*) | ✅ | File `network_errors.dart` telah memetakan semua varian `DioExceptionType` (timeout, badResponse, connectionError) ke pesan bahasa Indonesia yang ramah pengguna. |
| 4 | Pemusatan Konfigurasi HTTP (`Dio`) | ✅ | Konfigurasi dasar (`baseUrl`, `timeout`) tidak tersebar, melainkan terpusat di dalam `api_client.dart` (`createDio()`) dan dipanggil via `dioProvider`. |
| 5 | Pengujian Kasus Field Hilang & Edge Case | ✅ | *Unit test* sudah memvalidasi kasus *field* hilang/null (`incompleteJson`). *Tambahan Edge Case:* Menguji kegagalan *parsing* ketika API merespons dengan tipe data yang salah (misal: ID berupa *String* alih-alih *int*). |
| 6 | `flutter analyze` & `flutter test` bersih | ✅ | Kode lolos analisis statis (peringatan *unused import* dan duplikasi fungsi telah dihapus). Seluruh rangkaian *widget* dan *unit test* berstatus *All tests passed!*. |

### Catatan Tambahan
* **Keamanan Parsing JSON (`fromJson`):** Mencegah potensi *crash* aplikasi saat API mengembalikan data rumpang, bernilai null, ataupun tipe data yang tidak sesuai.
* **Hasil Pengujian Otomatis:** Memastikan bahwa mekanisme *fallback* pada model dan penerjemahan pesan kesalahan jaringan bekerja dengan optimal sesuai standar *Effective Dart*.
* **Pemisahan Tanggung Jawab (*Separation of Concerns*):** Akses data pada UI dilakukan secara bersih dan deklaratif melalui ekosistem Riverpod provider.