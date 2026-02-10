// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter_test/flutter_test.dart';

import 'package:aman_enterprises/main.dart';

void main() {
  testWidgets('App starts with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AmanEnterprisesApp());

    // Verify that the app title is shown
    expect(find.text('Aman'), findsOneWidget);
    expect(find.text('Enterprises'), findsOneWidget);
  });
}
