import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/post.dart';
import '../data/providers.dart'; // Mengambil dari data/providers.dart milik Anda
import '../data/network_errors.dart';

class PostDetailPage extends ConsumerWidget {
  final int postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca state list post yang sudah ada dari paged_posts.dart / providers.dart
    final postsAsync = ref.watch(postListProvider); 

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Post')),
      body: postsAsync.when(
        data: (posts) {
          final post = posts.firstWhere(
            (p) => p.id == postId,
            orElse: () => Post(id: postId, userId: 0, title: 'Tidak ditemukan', body: ''),
          );
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(post.body, style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Agar column hanya memakan ruang sebesar isinya
              children: [
                Text(
                  friendlyErrorMessage(error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    // Menyuruh Riverpod untuk membuat ulang state (refresh)
                    ref.invalidate(postListProvider);
                  },
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}