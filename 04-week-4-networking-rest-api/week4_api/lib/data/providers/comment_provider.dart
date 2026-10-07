import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/comment.dart';
import '../repositories/comment_repository.dart';

final dioProvider = Provider<Dio>((ref) => Dio());

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(ref.watch(dioProvider));
});

// Menggunakan AsyncNotifier standar yang secara otomatis mendukung argumen di build()
class CommentNotifier extends AsyncNotifier<List<Comment>> {
  @override
  Future<List<Comment>> build() async {
    // Baris 15 diperbaiki: build() standar tidak menerima parameter langsung di sini
    return []; 
  }

  Future<List<Comment>> fetchComments(int postId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.watch(commentRepositoryProvider);
      return await repo.fetchComments(postId);
    });
    return state.value ?? [];
  }
}

// Baris 31 diperbaiki: Karena menggunakan AsyncNotifier biasa, gunakan AsyncNotifierProvider biasa
final commentProvider = AsyncNotifierProvider<CommentNotifier, List<Comment>>(
  CommentNotifier.new,
);