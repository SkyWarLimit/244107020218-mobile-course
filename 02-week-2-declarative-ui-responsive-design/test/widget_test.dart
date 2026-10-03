import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week_2/main.dart'; 

void main() {
  testWidgets('Dashboard satu kolom di layar sempit', (tester) async {
    // Simulasi ukuran HP
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DashboardApp());

    // Mencari ukuran DashboardCard pertama
    final width = tester.getSize(find.byType(DashboardCard).first).width;
    
    // Karena lebar layar 400, kartu (1 kolom) harus kurang dari 700
    expect(width, lessThan(700)); 
  });

  testWidgets('Dashboard dua kolom di layar lebar', (tester) async {
    // Simulasi ukuran Desktop/Tablet
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DashboardApp());

    // Mencari ukuran DashboardCard pertama
    final width = tester.getSize(find.byType(DashboardCard).first).width;
    
    // Karena layar 1200 dibagi 2 kolom, lebarnya pasti di atas 500
    expect(width, greaterThan(500)); 
  });
}