import 'package:flutter_riverpod/flutter_riverpod.dart';

// Dummy providers agar kode tidak error (Sesuaikan dengan implementasi Anda nanti)
final tokenStoreProvider = Provider((ref) => DummyTokenStore());
final authRepositoryProvider = Provider((ref) => DummyAuthRepo());

class DummyTokenStore {
  Future<String?> readAccess() async => null;
  Future<void> save({required String access, required String refresh}) async {}
  Future<void> clear() async {}
}

class DummyAuthRepo {
  Future<({String access, String refresh})> login({required String email, required String password}) async {
    return (access: 'token', refresh: 'refresh');
  }
}

// Implementasi AuthProvider dari kode Anda
final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccess();
    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await ref
          .read(tokenStoreProvider)
          .save(access: session.access, refresh: session.refresh);
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    ref.invalidateSelf();
  }
}