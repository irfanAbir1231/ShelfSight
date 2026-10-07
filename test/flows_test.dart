import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsight/models/analysis_result.dart';
import 'package:shelfsight/models/coaching.dart';
import 'package:shelfsight/models/session.dart';
import 'package:shelfsight/screens/coaching_player_screens.dart';
import 'package:shelfsight/screens/detection_review_screen.dart';
import 'package:shelfsight/screens/result_screen.dart';
import 'package:shelfsight/screens/system_states.dart';
import 'package:shelfsight/theme/app_theme.dart';

AnalysisResult demoResult() {
  const quality = ImageQuality(acceptable: true, warnings: []);
  ProductDetection d(int i, String label) => ProductDetection(
    id: 'p$i',
    label: label,
    confidence: .9,
    box: NormalizedBox(
      x: (i % 10) * .09,
      y: (i ~/ 10) * .4 + .1,
      width: .08,
      height: .3,
    ),
  );
  final labels = [
    ...List.filled(8, 'square'),
    ...List.filled(11, 'other'),
    'uncertain',
  ];
  return AnalysisResult(
    auditId: 'a',
    summary: const AnalysisSummary(
      totalFacings: 20,
      squareFacings: 8,
      otherFacings: 11,
      uncertainFacings: 1,
      squareShare: 40,
    ),
    photos: [
      PhotoAnalysis(
        filename: 'x.jpg',
        annotatedImage: '',
        quality: quality,
        detections: [for (var i = 0; i < labels.length; i++) d(i, labels[i])],
      ),
    ],
    warnings: const [],
    engine: 'test',
  );
}

Widget host(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void main() {
  setUp(() => currentSession.value = DemoAuth.signIn('SO-1001', 'shelf123'));

  testWidgets('sales result shows Square data and no competitor shares', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(ResultScreen(storeName: 'Samson Center Demo Outlet', result: demoResult())),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('Square shelf share'), findsOneWidget);
    expect(find.text('Below target'), findsOneWidget);
    expect(find.text('Gap to target'), findsOneWidget);
    expect(find.text('10 pts'), findsOneWidget);
    for (final competitor in ['Unilever', 'Reckitt', 'Keya', 'Lux', 'Dettol']) {
      expect(find.textContaining(competitor), findsNothing);
    }
  });

  testWidgets('detection review filters and shows Square/Other/Uncertain', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(DetectionReviewScreen(storeName: 'Samson', result: demoResult())),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('All 20'), findsOneWidget);
    expect(find.textContaining('Square 8'), findsOneWidget);
    expect(find.textContaining('1 Uncertain'), findsOneWidget);
    await tester.tap(find.textContaining('Square 8'));
    await tester.pump();
    expect(find.text('Confirm detections'), findsOneWidget);
  });

  testWidgets('coaching player plays and hides download', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(AudioPlayerScreen(module: coachingModules.first)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Improving Soap Shelf Visibility'), findsOneWidget);
    expect(find.text('Approved training voice'), findsOneWidget);
    expect(find.textContaining('ownload'), findsNothing);
    await tester.tap(find.byTooltip('Forward 15 seconds'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Play'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel('Pause'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Pause'));
    await tester.pump();
  });

  testWidgets('system states: expired, offline, location denied', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(const SessionExpiredScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Your session has expired'), findsOneWidget);
    expect(find.text('Sign in again'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);

    await tester.pumpWidget(host(const OfflineStateScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Retry connection'), findsOneWidget);
    expect(find.textContaining('upload when'), findsOneWidget);

    await tester.pumpWidget(host(const LocationDeniedScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('View shops without location'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Location needed'), findsWidgets);
  });
}
