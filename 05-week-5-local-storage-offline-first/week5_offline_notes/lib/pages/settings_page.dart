import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return 'Belum pernah dicatat';
    }
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return isoString;
    final local = dt.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(local.day)}/${pad(local.month)}/${local.year} ${pad(local.hour)}:${pad(local.minute)}:${pad(local.second)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkModeAsync = ref.watch(darkModeProvider);
    final lastOpenedAsync = ref.watch(lastOpenedProvider);
    final forceOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          // 1. Preferensi Tema Gelap / Terang
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Mode Gelap (Dark Mode)'),
            subtitle: const Text('Disimpan persisten via SharedPreferences'),
            value: darkModeAsync.value ?? false,
            onChanged: (_) {
              ref.read(darkModeProvider.notifier).toggle();
            },
          ),
          const Divider(),

          // 2. Waktu Terakhir Dibuka via SharedPreferences
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Waktu Terakhir Dibuka'),
            subtitle: lastOpenedAsync.when(
              data: (val) => Text(_formatDateTime(val)),
              loading: () => const Text('Memuat...'),
              error: (err, stack) => const Text('Gagal memuat waktu'),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Perbarui info waktu',
              onPressed: () => ref.invalidate(lastOpenedProvider),
            ),
          ),
          const Divider(),

          // 3. Simulasi Mode Pesawat / Force Offline
          SwitchListTile(
            secondary: const Icon(Icons.airplanemode_active),
            title: const Text('Mode Pesawat (Force Offline)'),
            subtitle: const Text(
                'Simulasi jaringan terputus untuk menguji offline-first & sync'),
            value: forceOffline,
            onChanged: (value) {
              ref.read(forceOfflineProvider.notifier).setOfflineState(value);
            },
          ),
        ],
      ),
    );
  }
}