import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca provider turunan yang sudah kita buat
    final uncompletedCount = ref.watch(uncompletedTodoProvider).length;
    final totalCount = ref.watch(todoListProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik ToDo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Total Tugas: $totalCount', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text('Belum Selesai: $uncompletedCount', 
                style: const TextStyle(fontSize: 20, color: Colors.red)),
          ],
        ),
      ),
    );
  }
}