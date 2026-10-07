import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week4_api/pages/paged_post_page.dart';

void main() {
  testWidgets('PagedPostPage smoke test', (WidgetTester tester) async {
    // 1. Jalankan widget dengan ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PagedPostPage(),
        ),
      ),
    );

    // 2. Gunakan pumpAndSettle untuk menunggu semua frame dan pemanggilan API selesai/stabil
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 3. Verifikasi widget berhasil dimuat
    expect(find.byType(Scaffold), findsOneWidget);
  });
}