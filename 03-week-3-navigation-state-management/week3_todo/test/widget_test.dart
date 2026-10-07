import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/main.dart';

void main() {
  testWidgets('menambah tugas baru', (tester) async {
    // 1. Muat aplikasi
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle(); // Tunggu GoRouter selesai routing awal

    expect(find.text('Belum ada tugas'), findsOneWidget);

    // 2. Klik tombol tambah (FAB)
    await tester.tap(find.byIcon(Icons.add));
    
    // BAGIAN PENTING: Tunggu animasi pop-up dialog selesai dirender
    await tester.pumpAndSettle(); 

    // 3. Ketik teks dan simpan
    await tester.enterText(find.byType(TextField), 'Kerjakan PR minggu 3');
    await tester.tap(find.text('Tambah'));
    
    // Tunggu animasi dialog tertutup
    await tester.pumpAndSettle(); 

    // 4. Verifikasi teks muncul di daftar
    expect(find.text('Kerjakan PR minggu 3'), findsOneWidget);
  });
}