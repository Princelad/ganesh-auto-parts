import 'package:flutter_test/flutter_test.dart';
import 'package:ganesh_auto_parts/main.dart' as app;

void main() {
  testWidgets('app starts and shows welcome text', (WidgetTester tester) async {
    await tester.pumpWidget(const app.MyApp());

    // Allow frames to settle
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Ganesh Auto Parts'), findsOneWidget);
  });
}
