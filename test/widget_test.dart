import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsight/main.dart';

Future<void> signIn(WidgetTester tester, String id) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ShelfSightApp());
  await tester.pump(const Duration(milliseconds: 2300));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.enterText(find.byType(EditableText).at(0), id);
  await tester.enterText(find.byType(EditableText).at(1), 'shelf123');
  await tester.tap(find.text('Sign in').last);
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(const Duration(milliseconds: 600));
  expect(find.text('Find your current shop'), findsOneWidget);
  await tester.tap(find.text('Not now'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('splash opens login and rejects bad credentials', (tester) async {
    await tester.pumpWidget(const ShelfSightApp());
    expect(find.text('Retail visibility, measured'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('SO-1001'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(0), 'SO-1001');
    await tester.enterText(find.byType(EditableText).at(1), 'wrong');
    await tester.tap(find.text('Sign in').last);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Employee ID or password is incorrect'), findsOneWidget);
  });

  testWidgets('sales officer: home, detection, start visit, categories', (
    tester,
  ) async {
    await signIn(tester, 'SO-1001');
    expect(find.text('Good morning, Arif'), findsOneWidget);
    expect(find.text('5 assigned shops'), findsOneWidget);
    expect(find.text('Visits'), findsOneWidget);
    expect(find.text('Alerts'), findsNothing);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    expect(find.textContaining('0 of 5 shops visited'), findsOneWidget);

    // Camera fly-to finishes, detection sheet shows.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('We found your current shop'), findsOneWidget);
    expect(find.text('Samson Center Demo Outlet'), findsOneWidget);

    await tester.drag(find.text('We found your current shop'), const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Start shop visit'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Visit active'), findsOneWidget);
    await tester.tap(find.text('Select product category'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Choose a product category'), findsOneWidget);
    await tester.tap(find.text('Shampoo'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Analysis coming soon'), findsOneWidget);
  });

  testWidgets('territory officer: dashboard, alert, audit summary', (
    tester,
  ) async {
    await signIn(tester, 'TO-2001');
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Good morning, Nadia'), findsOneWidget);
    expect(find.text('Gulshan Territory'), findsOneWidget);
    expect(find.text('Alerts'), findsWidgets);
    expect(find.text('Team'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.text('8 points below target'), findsOneWidget);

    await tester.tap(find.text('Competitive shelf update').first);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Audit summary'), findsOneWidget);
    expect(find.text('Below target'), findsOneWidget);
    await tester.drag(find.text('Company breakdown'), const Offset(0, -300));
    await tester.pump();
    expect(find.text('Unilever'), findsOneWidget);
    expect(find.text('35%'), findsOneWidget);
  });
}
