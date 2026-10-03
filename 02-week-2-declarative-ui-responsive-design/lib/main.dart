import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// 1. Ekstrak breakpoint ke dalam satu konstanta global
const double kWideBreakpoint = 700;

void main() => runApp(const DashboardApp());

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color.fromARGB(255, 183, 58, 158)),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color.fromARGB(255, 183, 58, 162),
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: DashboardUtama(
        isDark: isDark,
        onUbahTema: (nilaiBaru) => setState(() => isDark = nilaiBaru),
      ),
    );
  }
}

class DashboardUtama extends StatelessWidget {
  const DashboardUtama({
    required this.isDark,
    required this.onUbahTema,
    super.key,
  });

  final bool isDark;
  final ValueChanged<bool> onUbahTema;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Overview', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Semantics(
            label: 'Ubah ke mode gelap',
            child: Row(
              children: [
                Icon(isDark ? Icons.nightlight_round : Icons.wb_sunny, size: 20),
                const SizedBox(width: 8),
                CupertinoSwitch(
                  value: isDark,
                  onChanged: onUbahTema,
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const HeaderProfil(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 2. Menggunakan konstanta kWideBreakpoint
                final int jumlahKolom = constraints.maxWidth >= kWideBreakpoint ? 2 : 1;

                return GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: jumlahKolom,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: jumlahKolom == 1 ? 3.0 : 2.0,
                  children: const [
                    // 3. Menggunakan reusable widget Card
                    DashboardCard(title: 'IPK', value: '3.40', icon: Icons.star),
                    DashboardCard(title: 'SKS', value: '120', icon: Icons.menu_book),
                    DashboardCard(title: 'Kehadiran', value: '92%', icon: Icons.check_circle),
                    DashboardCard(title: 'Portofolio', value: 'Ready', icon: Icons.folder),
                    DashboardCard(title: 'Tugas Belum', value: '3', icon: Icons.warning),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderProfil extends StatelessWidget {
  const HeaderProfil({super.key});

  @override
  Widget build(BuildContext context) {
    // Mengekstrak theme ke dalam variabel lokal agar penulisan kode lebih bersih
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.onPrimaryContainer,
            child: Icon(
              Icons.person,
              size: 35,
              color: theme.colorScheme.primaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Muhammad Ihsan Rahmatullah',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIM: 244107020218 • Kelas: TI-3F',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Jurusan Teknologi Informasi',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 4. Widget Reusable: Bersih dari nilai hardcode
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // MENGGANTI Container MENJADI Card
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero, // Menghilangkan margin bawaan agar spacing grid konsisten
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}