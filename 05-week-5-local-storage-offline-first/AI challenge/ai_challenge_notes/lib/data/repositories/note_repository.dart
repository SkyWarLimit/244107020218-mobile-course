import 'package:sqflite/sqflite.dart';
import '../local/db_helper.dart';
import '../models/note.dart';

/// Repository CRUD catatan menggunakan sqflite (SQLite).
/// Semua operasi database dienkapsulasi di sini agar UI tidak
/// bersentuhan langsung dengan SQL.
class NoteRepository {
  NoteRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  /// READ: Ambil semua catatan, diurutkan dari yang terbaru diperbarui
  Future<List<Note>> fetchNotes() async {
    final db = await _openDb();
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  /// CREATE: Tambah catatan baru (otomatis ditandai dirty untuk sync)
  Future<Note> addNote({required String title, String body = ''}) async {
    final db = await _openDb();
    final now = DateTime.now();
    final note = Note(title: title, body: body, updatedAt: now, dirty: true);
    final id = await db.insert('notes', note.toMap());
    return note.copyWith(id: id);
  }

  /// UPDATE: Perbarui catatan yang sudah ada
  Future<void> updateNote(Note note) async {
    final db = await _openDb();
    final updated = note.copyWith(updatedAt: DateTime.now(), dirty: true);
    await db.update(
      'notes',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// DELETE: Hapus catatan berdasarkan ID
  Future<void> deleteNote(int id) async {
    final db = await _openDb();
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  /// Hitung jumlah catatan yang belum tersinkronisasi (dirty = 1)
  Future<int> countDirty() async {
    final db = await _openDb();
    final rows =
        await db.rawQuery('SELECT COUNT(*) AS c FROM notes WHERE dirty = 1');
    return ((rows.first['c'] as num?)?.toInt() ?? 0);
  }

  /// Tandai semua catatan dirty menjadi synced setelah upload berhasil
  Future<void> markAllSynced() async {
    final db = await _openDb();
    await db.update('notes', {'dirty': 0}, where: 'dirty = 1');
  }
}

/// Helper: Simulasi proses sinkronisasi catatan ke server.
/// Jika [isOffline] = true, langsung lempar exception.
Future<int> syncNotes(NoteRepository repo, bool isOffline) async {
  if (isOffline) {
    throw Exception('Aplikasi sedang offline. Sinkronisasi dibatalkan.');
  }
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;

  // Simulasi upload ke server (delay 1 detik)
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}
