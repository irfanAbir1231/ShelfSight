import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../models/audit_flow.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/share_ring.dart';
import '../widgets/shell_widgets.dart';
import 'detection_review_screen.dart';
import 'recommendation_screen.dart';
import 'visit_screens.dart';

/// Square share target for Soap (demo).
const squareTargetShare = 50.0;

/// Sales Officer result summary. Shows Square data only: competitor company
/// percentages are never shown on Sales Officer screens.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.storeName,
    required this.result,
    this.imagePaths = const [],
  });
  final String storeName;
  final AnalysisResult result;
  final List<String> imagePaths;

  @override
  Widget build(BuildContext context) {
    final s = result.summary;
    final share = s.squareShare.clamp(0, 100).toDouble();
    final gap = squareTargetShare - share;
    final onTarget = gap <= 0;
    ActiveVisit.current?.step.value = 2;
    AuditFlow.current?.result = result;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: FixedHeaderScrollView(
        title: 'Soap result',
        subtitle: storeName,
        showNavInset: false,
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            SurfaceCard(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
              child: Column(
                children: [
                  ShareRing(
                    value: share,
                    label: 'Square shelf share',
                    target: squareTargetShare,
                  ),
                  const SizedBox(height: 14),
                  StatusPill(
                    label: onTarget ? 'On target' : 'Below target',
                    icon: onTarget
                        ? Icons.check_circle_rounded
                        : Icons.trending_down_rounded,
                    color: onTarget
                        ? AppColors.emeraldDark
                        : const Color(0xFF92580A),
                    background: onTarget ? AppColors.mint : AppColors.amberSoft,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Stat('Total facings', '${s.totalFacings}'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat('Square facings', '${s.squareFacings}'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat('Uncertain', '${s.uncertainFacings}'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    'Target share',
                    '${squareTargetShare.round()}%',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    onTarget ? 'Above target' : 'Gap to target',
                    '${gap.abs().round()} pts',
                    highlight: !onTarget,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Review detections',
              icon: Icons.fact_check_outlined,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetectionReviewScreen(
                    storeName: storeName,
                    result: result,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RecommendationScreen(
                      storeName: storeName,
                      share: share,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy, width: 1.5),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Continue visit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.send_outlined, size: 18, color: AppColors.inkMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Detailed competitor information has been sent to your '
                    'Territory Officer.',
                    style: TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    color: highlight ? AppColors.amberSoft : Colors.white,
    borderColor: highlight ? AppColors.amber : AppColors.border,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          style: const TextStyle(fontSize: 12.5, height: 1.25),
        ),
      ],
    ),
  );
}
