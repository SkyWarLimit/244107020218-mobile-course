import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/note.dart';
import 'repositories/note_repository.dart';
import 'repositories/prefs_repository.dart';

// ──────────────────────────────────────────────
// PROVIDER: Repository
// ──────────────────────────────────────────────

/// Provider NoteRepository (sqflite) — menangani CRUD catatan
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

/// Provider PrefsRepository (SharedPreferences) — menangani preferensi tema
final prefsRepositoryProvider = Provider<PrefsRepository>((ref) {
  return PrefsRepository();
});

// ──────────────────────────────────────────────
// PROVIDER: Daftar Catatan (Notes List)
// ──────────────────────────────────────────────

/// FutureProvider yang mengambil semua catatan dari SQLite
final notesListProvider = FutureProvider<List<Note>>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.fetchNotes();
});

// ──────────────────────────────────────────────
// PROVIDER: Dark Mode (Theme Preference)
// ──────────────────────────────────────────────

/// AsyncNotifier untuk mengelola state dark mode dari SharedPreferences
class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.watch(prefsRepositoryProvider).getDarkMode();

  /// Toggle dark mode: simpan ke SharedPreferences lalu update state
  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

// ──────────────────────────────────────────────
// PROVIDER: Force Offline Mode (Simulasi)
// ──────────────────────────────────────────────

/// Notifier untuk mensimulasikan status offline (toggle manual)
class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle(bool value) => state = value;
}

final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);
