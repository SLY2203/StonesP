import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msu_dcs_alumni/main.dart';

void main() {
  testWidgets('MSU DCS Alumni app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MSUDCSAlumniApp());

    // Verify that the splash screen renders MSU branding and logo
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Department of Computer Science'), findsOneWidget);

    // Advance past splash delay
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
  });
}
