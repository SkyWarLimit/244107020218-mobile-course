import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart'; 
void main() {
  group('Comment Model Tests', () {
    test('fromJson harus menangani field yang hilang atau bernilai null dengan aman (fallback nilai)', () {
      final Map<String, dynamic> incompleteJson = {
        'postId': 101,
        'name': null, 
        'body': 'Ini isi komentar' 
      };

      final comment = Comment.fromJson(incompleteJson);

      expect(comment.postId, 101);
      expect(comment.id, 0); 
      expect(comment.name, 'Unknown'); 
      expect(comment.email, 'No Email'); 
      expect(comment.body, 'Ini isi komentar'); 
    });
  });
}