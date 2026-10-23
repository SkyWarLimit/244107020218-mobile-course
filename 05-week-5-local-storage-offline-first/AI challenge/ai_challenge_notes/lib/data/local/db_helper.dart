import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Helper untuk membuka database SQLite lokal.
/// Membuat tabel `notes` saat pertama kali digunakan (version: 1).
/// Tabel ini dirancang untuk offline-first dengan kolom `dirty`
/// sebagai flag antrean sinkronisasi.
Future<Database> openNotesDb() async {
  final dir = await getDatabasesPath();
  return openDatabase(
    p.join(dir, 'ai_challenge_notes.db'),
    version: 1,
    onCreate: (db, version) async {
      // Buat tabel notes dengan indeks untuk optimasi query 1000+ data
      await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0
        )
      ''');
      // Indeks pada updated_at agar ORDER BY DESC tetap cepat
      await db.execute(
        'CREATE INDEX idx_notes_updated ON notes(updated_at DESC)',
      );
    },
  );
}
