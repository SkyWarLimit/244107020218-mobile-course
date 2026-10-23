import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/providers.dart';
import 'pages/notes_page.dart';
import 'pages/settings_page.dart';

void main() {
  // ProviderScope membungkus aplikasi agar Riverpod aktif
  runApp(const ProviderScope(child: MyApp()));
}

/// Root widget dengan integrasi preferensi tema SharedPreferences
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Catat waktu terakhir dibuka via SharedPreferences saat app dibuka
    Future.microtask(() async {
      try {
        await ref.read(prefsRepositoryProvider).markOpenedNow();
        ref.invalidate(lastOpenedProvider);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    // Membaca preferensi tema secara reaktif dari SharedPreferences
    final isDark = ref.watch(darkModeProvider).value ?? false;

    return MaterialApp(
      title: 'Catatan Offline (Offline-First)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const MainScreen(),
    );
  }
}

// Widget untuk menampung Navigasi Bawah (Catatan & Pengaturan)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Daftar halaman yang akan ditampilkan
  final List<Widget> _pages = const [
    NotesPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Catatan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }
}