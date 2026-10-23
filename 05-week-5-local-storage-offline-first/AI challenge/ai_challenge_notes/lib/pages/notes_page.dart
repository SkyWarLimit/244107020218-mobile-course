import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/note.dart';
import '../data/providers.dart';
import '../data/repositories/note_repository.dart';

/// Halaman utama daftar catatan (CRUD).
/// Menggunakan sqflite melalui NoteRepository via Riverpod.
class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesListProvider);
    final isOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          // Tombol sinkronisasi
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkronisasi',
            onPressed: () async {
              try {
                final repo = ref.read(noteRepositoryProvider);
                final offline = ref.read(forceOfflineProvider);
                final count = await syncNotes(repo, offline);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$count catatan berhasil disinkronkan.')),
                  );
                }
                ref.invalidate(notesListProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner offline
          if (isOffline)
            Container(
              width: double.infinity,
              color: Colors.orangeAccent,
              padding: const EdgeInsets.all(8),
              child: const Text(
                '⚡ Mode Offline Aktif',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          // Daftar catatan
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return const Center(
                    child: Text('Belum ada catatan.\nTekan + untuk menambahkan.'),
                  );
                }
                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return ListTile(
                      title: Text(note.title),
                      subtitle: Text(
                        note.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: note.dirty
                          ? const Icon(Icons.cloud_off, color: Colors.orange)
                          : const Icon(Icons.cloud_done, color: Colors.green),
                      onTap: () => _showEditNoteDialog(context, ref, note),
                      onLongPress: () async {
                        // Hapus catatan (DELETE)
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Catatan?'),
                            content: Text('Hapus "${note.title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(noteRepositoryProvider).deleteNote(note.id!);
                          ref.invalidate(notesListProvider);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Dialog untuk menambah catatan baru (CREATE)
  Future<void> _showAddNoteDialog(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catatan Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(labelText: 'Isi Catatan'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty) {
                await ref.read(noteRepositoryProvider).addNote(
                      title: titleCtrl.text,
                      body: bodyCtrl.text,
                    );
                ref.invalidate(notesListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  /// Dialog untuk mengedit catatan (UPDATE)
  Future<void> _showEditNoteDialog(
      BuildContext context, WidgetRef ref, Note note) async {
    final titleCtrl = TextEditingController(text: note.title);
    final bodyCtrl = TextEditingController(text: note.body);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Catatan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(labelText: 'Isi Catatan'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty) {
                await ref.read(noteRepositoryProvider).updateNote(
                      note.copyWith(
                        title: titleCtrl.text,
                        body: bodyCtrl.text,
                      ),
                    );
                ref.invalidate(notesListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
