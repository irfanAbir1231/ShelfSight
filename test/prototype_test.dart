import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsight/main.dart';

Future<void> settle(WidgetTester tester, [int ms = 700]) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  for (var i = 0; i < 8 && f.evaluate().isEmpty; i++) {
    final scrollables = find.byType(CustomScrollView);
    if (scrollables.evaluate().isEmpty) break;
    await tester.drag(scrollables.last, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 300));
  }
  expect(f, findsWidgets, reason: 'missing "$text"');
  await tester.ensureVisible(f.first);
  // Keep taps clear of the floating nav bar.
  if (tester.getCenter(f.first).dy > 690) {
    final scrollables = find.byType(CustomScrollView);
    if (scrollables.evaluate().isNotEmpty) {
      await tester.drag(scrollables.last, const Offset(0, -220));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }
  await tester.tap(f.first);
  await settle(tester);
}

Future<void> signIn(WidgetTester tester, String id) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ShelfSightApp());
  await settle(tester, 2400);
  await tester.enterText(find.byType(EditableText).at(0), id);
  await tester.enterText(find.byType(EditableText).at(1), 'shelf123');
  await tapText(tester, 'Sign in');
  await settle(tester, 1000);
  await tapText(tester, 'Not now');
}

void main() {
  testWidgets('Sales Officer prototype: login to completed visit', (
    tester,
  ) async {
    await signIn(tester, 'SO-1001');
    await settle(tester, 5000); // camera fly-to, detection sheet
    expect(find.text('We found your current shop'), findsOneWidget);

    await tester.drag(
      find.text('We found your current shop'),
      const Offset(0, -400),
    );
    await settle(tester);
    await tapText(tester, 'Start shop visit');
    expect(find.text('Visit active'), findsOneWidget);
    await tapText(tester, 'Select product category');
    await tapText(tester, 'Soap');
    expect(find.text('Capture the Soap shelf'), findsOneWidget);
    await tapText(tester, 'Open camera');

    // No camera in tests: use the bundled demo photo.
    expect(find.text('Soap shelf capture'), findsOneWidget);
    await settle(tester, 7000); // camera init times out in tests
    await tapText(tester, 'Use demo shelf photo · testing only');
    await tapText(tester, 'Review photo');
    expect(find.text('Review photos'), findsOneWidget);
    await tapText(tester, 'Analyze Soap shelf');
    expect(find.text('Analyzing Soap shelf'), findsOneWidget);
    await settle(tester, 5000);

    expect(find.text('Soap result'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.textContaining('Unilever'), findsNothing);
    await tapText(tester, 'Review detections');
    expect(find.text('Confirm detections'), findsOneWidget);
    await tapText(tester, 'Confirm detections');
    await tapText(tester, 'Continue visit');
    expect(find.text('Recommended next action'), findsOneWidget);
    await tapText(tester, 'Complete visit');
    expect(find.text('Territory Officer notified'), findsOneWidget);
    await tapText(tester, 'Return to home');
    expect(find.textContaining('1 of 5 shops visited'), findsOneWidget);
  });

  testWidgets('Territory Officer prototype: alert to coaching assignment', (
    tester,
  ) async {
    await signIn(tester, 'TO-2001');
    await settle(tester, 1000);
    await tapText(tester, 'Competitive shelf update');
    expect(find.text('Audit summary'), findsOneWidget);
    await tapText(tester, 'Full brand breakdown');
    expect(find.text('Brand breakdown'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    await tapText(tester, 'View annotated image');
    expect(find.text('Annotated image'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    await tapText(tester, 'Recommended follow-up');
    expect(
      find.textContaining('10 percentage points below'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pageBack();
    await settle(tester);

    await tapText(tester, 'Team');
    expect(find.text('Gulshan · 4 Sales Officers'), findsOneWidget);
    await tapText(tester, 'Arif Rahman');
    await tapText(tester, 'Assign coaching');
    await tapText(tester, 'Assign module');
    expect(find.text('Module assigned'), findsOneWidget);
  });
}
