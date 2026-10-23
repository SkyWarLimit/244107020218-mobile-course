import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';
import '../data/providers.dart';

/// Halaman Catatan Offline (CRUD persisten SQLite + Riverpod)
class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(local.hour)}:${pad(local.minute)}:${pad(local.second)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final isOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          // Tombol Sinkronisasi Manual
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkronisasi Catatan',
            onPressed: () async {
              try {
                final repo = ref.read(noteRepositoryProvider);
                final offline = ref.read(forceOfflineProvider);
                final dirtyCount = await syncNotes(repo, offline);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        dirtyCount == 0
                            ? 'Semua catatan sudah tersinkronisasi.'
                            : 'Berhasil menyinkronkan $dirtyCount catatan kotor.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                // Refresh daftar catatan setelah sync berhasil
                ref.invalidate(notesProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
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
          // Banner peringatan jika mode offline / pesawat aktif
          if (isOffline)
            Container(
              width: double.infinity,
              color: Colors.amber.shade700,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.airplanemode_active,
                      color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Mode Pesawat / Offline Aktif',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Daftar Catatan (READ)
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return const Center(
                    child: Text('Belum ada catatan. Tekan + untuk membuat baru!'),
                  );
                }
                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(
                          note.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (note.body.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                note.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Diperbarui: ${_formatTime(note.updatedAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        // Badge Dirty / Synced
                        trailing: note.dirty
                            ? const Tooltip(
                                message: 'Belum sinkron (Dirty)',
                                child: Chip(
                                  avatar: Icon(Icons.cloud_off,
                                      size: 16, color: Colors.orange),
                                  label: Text('Dirty',
                                      style: TextStyle(
                                          color: Colors.orange, fontSize: 12)),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                            : const Tooltip(
                                message: 'Tersinkronisasi (Synced)',
                                child: Chip(
                                  avatar: Icon(Icons.cloud_done,
                                      size: 16, color: Colors.green),
                                  label: Text('Synced',
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 12)),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                        // UPDATE: Tap catatan untuk mengedit
                        onTap: () => _showEditNoteDialog(context, ref, note),
                        // DELETE: Tekan lama untuk menghapus dengan konfirmasi
                        onLongPress: () =>
                            _confirmDeleteDialog(context, ref, note),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      // CREATE: Tambah Catatan Baru
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Dialog untuk Menambah Catatan Baru (CREATE)
  Future<void> _showAddNoteDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Catatan Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Judul',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                await ref.read(noteRepositoryProvider).addNote(
                      title: title,
                      body: bodyController.text.trim(),
                    );
                ref.invalidate(notesProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  /// Dialog untuk Mengedit Catatan (UPDATE)
  Future<void> _showEditNoteDialog(
      BuildContext context, WidgetRef ref, Note note) async {
    final titleController = TextEditingController(text: note.title);
    final bodyController = TextEditingController(text: note.body);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Catatan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Judul',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                await ref.read(noteRepositoryProvider).updateNote(
                      note.copyWith(
                        title: title,
                        body: bodyController.text.trim(),
                      ),
                    );
                ref.invalidate(notesProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Perbarui'),
          ),
        ],
      ),
    );
  }

  /// Dialog Konfirmasi Hapus Catatan (DELETE)
  Future<void> _confirmDeleteDialog(
      BuildContext context, WidgetRef ref, Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: Text('Apakah Anda yakin ingin menghapus "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && note.id != null) {
      await ref.read(noteRepositoryProvider).deleteNote(note.id!);
      ref.invalidate(notesProvider);
    }
  }
}