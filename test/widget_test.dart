import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ganesh_auto_parts/src/screens/home_page.dart';

void main() {
  testWidgets('app starts and shows home menu', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomePage())),
    );

    // Allow frames to settle
    await tester.pumpAndSettle();

    // Check if Quick Stats section is displayed
    expect(find.text('Quick Stats'), findsOneWidget);
    
    // Check if main menu items are displayed (may appear in stats too)
    expect(find.text('Items'), findsWidgets);
    expect(find.text('Customers'), findsWidgets);
    expect(find.text('Invoices'), findsWidgets);
    expect(find.text('Reports'), findsOneWidget);
  });
}
