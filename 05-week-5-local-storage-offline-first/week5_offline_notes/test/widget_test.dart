import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/main.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository() : super(openDb: () => throw UnimplementedError());

  @override
  Future<List<Note>> fetchNotes() async => [];

  @override
  Future<int> countDirty() async => 0;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'dark_mode': false,
      'last_opened_at': '2026-10-23T10:00:00.000Z',
    });
  });

  testWidgets('App smoke test - Menampilkan judul Catatan Offline',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Catatan Offline'), findsOneWidget);
  });
}
