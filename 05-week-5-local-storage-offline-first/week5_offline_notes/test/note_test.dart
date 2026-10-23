import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({
    this.items = const [],
    this.throwError = false,
  }) : super(openDb: () => throw UnimplementedError());

  final List<Note> items;
  final bool throwError;
  bool allSyncedCalled = false;

  @override
  Future<List<Note>> fetchNotes() async {
    if (throwError) throw Exception('db locked (simulasi)');
    return items;
  }

  @override
  Future<int> countDirty() =>
      Future.value(items.where((n) => n.dirty).length);

  @override
  Future<void> markAllSynced() async {
    allSyncedCalled = true;
  }
}

void main() {
  group('Unit Test Model Note', () {
    test('fromMap aman terhadap field yang hilang (fallback default)', () {
      final note = Note.fromMap({'title': 'Belanja'});
      expect(note.title, 'Belanja');
      expect(note.body, '');
      expect(note.dirty, isFalse);
    });

    test('flag dirty bertahan pada serialisasi toMap dan fromMap', () {
      final note = Note(
        title: 'Beli susu',
        body: '2 liter',
        updatedAt: DateTime(2026, 9, 18),
        dirty: true,
      );
      final restored = Note.fromMap(note.toMap());
      expect(restored.dirty, isTrue);
      expect(restored.title, 'Beli susu');
      expect(restored.body, '2 liter');
    });

    test('copyWith membuat salinan dengan field yang diperbarui', () {
      final original = Note(
        id: 1,
        title: 'Awal',
        body: 'Isi awal',
        updatedAt: DateTime(2026, 1, 1),
        dirty: false,
      );
      final updated = original.copyWith(
        title: 'Revisi',
        dirty: true,
      );
      expect(updated.id, 1);
      expect(updated.title, 'Revisi');
      expect(updated.body, 'Isi awal');
      expect(updated.dirty, isTrue);
    });
  });

  group('Provider Test dengan FakeNoteRepository', () {
    test('provider sukses mengambil daftar catatan dari fake repository', () async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            FakeNoteRepository(items: [
              Note(
                id: 1,
                title: 'Tes Catatan',
                body: 'Konten',
                updatedAt: DateTime.now(),
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notes = await container.read(notesProvider.future);
      expect(notes.length, 1);
      expect(notes.first.title, 'Tes Catatan');
    });

    test('provider menangani error database dari fake repository', () async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            FakeNoteRepository(throwError: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(notesProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Logic Test: Offline-First & Resolusi Konflik (syncNotes)', () {
    test('syncNotes melempar Exception saat aplikasi sedang offline (mode pesawat)', () async {
      final fakeRepo = FakeNoteRepository(items: [
        Note(title: 'Offline Note', updatedAt: DateTime.now(), dirty: true),
      ]);

      expect(
        () => syncNotes(fakeRepo, true),
        throwsA(isA<Exception>()),
      );
    });

    test('syncNotes berhasil menyinkronkan data kotor saat online', () async {
      final fakeRepo = FakeNoteRepository(items: [
        Note(title: 'Online Note', updatedAt: DateTime.now(), dirty: true),
      ]);

      final count = await syncNotes(fakeRepo, false);
      expect(count, 1);
      expect(fakeRepo.allSyncedCalled, isTrue);
    });
  });
}
