import 'package:dio/dio.dart';
import '../models/post.dart';
import 'note_repository.dart';

class PostRepository {
  PostRepository(this._dio);
  final Dio _dio;

  Future<List<Post>> fetchPosts() async {
    final response = await _dio.get<List>('/posts');
    final data = response.data ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
  }
  Future<List<Post>> fetchPostsPage({
  required int page,
  int limit = 10,
}) async {
  final response = await _dio.get<List>(
    '/posts',
    queryParameters: {'_page': page, '_limit': limit},
  );
  final data = response.data ?? [];
  return data
      .whereType<Map<String, dynamic>>()
      .map(Post.fromJson)
      .toList();
}

Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  // Simulasi upload: pada project nyata, kirim tiap catatan dirty
  // ke REST API di sini, lalu tandai bersih bila server menjawab 2xx.
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}

}

