import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsight/main.dart';

Future<void> signIn(WidgetTester tester, String id) async {
  await tester.pumpWidget(const ShelfSightApp());
  await tester.pump(const Duration(milliseconds: 1800));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(EditableText).at(0), id);
  await tester.enterText(find.byType(EditableText).at(1), 'shelf123');
  await tester.tap(find.text('Sign in').last);
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('splash opens login and rejects bad credentials', (tester) async {
    await tester.pumpWidget(const ShelfSightApp());
    expect(find.text('Preparing your workspace'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    expect(find.text('Employee ID'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(0), 'SO-1042');
    await tester.enterText(find.byType(EditableText).at(1), 'wrong');
    await tester.tap(find.text('Sign in').last);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Employee ID or password is incorrect.'), findsOneWidget);
  });

  testWidgets('sales officer sees map home and sales nav', (tester) async {
    await signIn(tester, 'SO-1042');
    expect(find.text('Visits'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Alerts'), findsNothing);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    expect(find.text('Soap'), findsOneWidget);
    expect(find.textContaining('Shop detected · GPS'), findsOneWidget);
  });

  testWidgets('territory officer sees dashboard with company shares', (
    tester,
  ) async {
    await signIn(tester, 'TO-2001');
    expect(find.text('Alerts'), findsWidgets);
    expect(find.text('Team'), findsOneWidget);
    expect(find.text('Unilever'), findsOneWidget);
    expect(find.text('Reckitt'), findsOneWidget);
  });
}
