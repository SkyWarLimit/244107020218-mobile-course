import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';

/// Halaman pengaturan: toggle dark mode (SharedPreferences) & force offline.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkModeAsync = ref.watch(darkModeProvider);
    final forceOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          // Toggle Dark Mode — disimpan ke SharedPreferences
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Preferensi tema disimpan di SharedPreferences'),
            value: darkModeAsync.value ?? false,
            onChanged: (_) {
              ref.read(darkModeProvider.notifier).toggle();
            },
          ),
          const Divider(),
          // Toggle Force Offline — simulasi jaringan mati
          SwitchListTile(
            title: const Text('Force Offline Mode'),
            subtitle: const Text('Simulasi jaringan terputus untuk testing sync'),
            value: forceOffline,
            onChanged: (value) {
              ref.read(forceOfflineProvider.notifier).toggle(value);
            },
          ),
        ],
      ),
    );
  }
}
