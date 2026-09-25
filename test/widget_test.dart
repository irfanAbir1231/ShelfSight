// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:shelfsight/main.dart';

void main() {
  testWidgets(
    'shows branded loading then opens dashboard without authentication',
    (tester) async {
      await tester.pumpWidget(const ShelfSightApp());
      expect(find.text('ShelfSight'), findsOneWidget);
      expect(find.text('Preparing your workspace'), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);

      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pumpAndSettle();

      expect(find.text('Start a new store visit'), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
    },
  );
}
