import 'package:dio/dio.dart';
import '../models/comment.dart';

class CommentRepository {
  final Dio _dio;

  CommentRepository(this._dio) {
    _dio.options.baseUrl = 'https://jsonplaceholder.typicode.com';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get(
      '/comments',
      queryParameters: {'postId': postId},
    );
    
    final List<dynamic> data = response.data;
    return data.map((json) => Comment.fromJson(json)).toList();
  }
}