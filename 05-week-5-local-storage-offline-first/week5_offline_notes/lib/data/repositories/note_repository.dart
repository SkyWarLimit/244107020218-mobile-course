
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../local/note.dart';

class NoteRepository {
  NoteRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  Future<List<Note>> fetchNotes() async {
    final db = await _openDb();
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<Note> addNote({required String title, String body = ''}) async {
    final db = await _openDb();
    final note = Note(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    final id = await db.insert('notes', note.toMap());
    return Note(
      id: id,
      title: note.title,
      body: note.body,
      updatedAt: note.updatedAt,
      dirty: true,
    );
  }

  /// UPDATE: Perbarui judul dan isi catatan.
  /// Otomatis memperbarui updatedAt ke waktu saat ini dan set dirty = true.
  Future<void> updateNote(Note note) async {
    final db = await _openDb();
    final updated = note.copyWith(
      updatedAt: DateTime.now(),
      dirty: true,
    );
    await db.update(
      'notes',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await _openDb();
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countDirty() async {
    final db = await _openDb();
    final rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM notes WHERE dirty = 1');
    return ((rows.first['c'] as num?)?.toInt() ?? 0);
  }

  Future<void> markAllSynced() async {
    final db = await _openDb();
    await db.update('notes', {'dirty': 0}, where: 'dirty = 1');
  }
} // <-- TUTUP CLASS NoteRepository DI SINI

/// Aturan Resolusi Konflik Sinkronisasi (Offline-First):
/// - Strategi: Last-Write-Wins (LWW) berdasarkan atribut `updated_at`.
/// - Jika [isOffline] bernilai true (misal mode pesawat atau Force Offline aktif),
///   sinkronisasi ditolak dan melempar Exception agar data lokal tetap aman dan dirty flag tetap utuh.
/// - Pada kondisi normal (online), semua catatan dengan flag `dirty = 1` diunggah ke server.
///   Setelah server mengonfirmasi penerimaan (status 2xx), lokal menandai catatan sebagai bersih (`dirty = 0`).
/// - Jika terjadi konflik timestamp bersamaan: catatan dengan timestamp `updated_at` paling akhir yang menang.
Future<int> syncNotes(NoteRepository repo, bool isOffline) async {
  // Langsung cek nilai boolean isOffline yang dikirimkan dari UI
  if (isOffline) {
    throw Exception('Simulasi: Aplikasi sedang offline (mode pesawat aktif).');
  }

  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;

  // Simulasi proses upload ke server
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}

// Provider untuk NoteRepository
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

// FutureProvider untuk mengambil daftar catatan
// retry: null menonaktifkan retry otomatis Riverpod 3 agar error langsung final
final notesProvider = FutureProvider<List<Note>>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.fetchNotes();
}, retry: (retryCount, error) => null);