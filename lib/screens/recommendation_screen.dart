import 'package:flutter/material.dart';

import '../models/coaching.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';
import 'app_shell.dart';
import 'coaching_player_screens.dart';
import 'result_screen.dart';
import 'visit_completed_screen.dart';

/// Sales recommendation: next action and talking points. No sales-outcome
/// promises.
class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({
    super.key,
    required this.storeName,
    required this.share,
  });
  final String storeName;
  final double share;

  @override
  Widget build(BuildContext context) {
    return RoleNavScaffold(
      activeTab: 0,
      body: FixedHeaderScrollView(
        title: 'Recommended next action',
        subtitle: storeName,
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            SurfaceCard(
              child: Column(
                children: [
                  _Bar(
                    label: 'Square share',
                    value: share,
                    color: AppColors.emeraldDark,
                  ),
                  const SizedBox(height: 12),
                  const _Bar(
                    label: 'Target',
                    value: squareTargetShare,
                    color: AppColors.navy,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SurfaceCard(
              color: AppColors.mint,
              borderColor: AppColors.emeraldDark,
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: AppColors.emeraldDark),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ask the shopkeeper for stronger Meril and Sepnil '
                      'visibility in the main eye-level section.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emeraldDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle(title: 'Suggested talking points'),
            const SizedBox(height: 8),
            const SurfaceCard(
              child: Column(
                children: [
                  _Point(1, 'Start with a small additional order'),
                  _Point(2, 'Move Square products to eye level'),
                  _Point(3, 'Keep fast-moving items front-facing'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'These are suggestions. Results depend on the shop and are not '
              'guaranteed.',
              style: TextStyle(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Listen to coaching',
              icon: Icons.headphones_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AudioPlayerScreen(module: coachingModules.first),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VisitCompletedScreen(
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
                  'Complete visit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            '${value.round()}%',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          value: value / 100,
          minHeight: 10,
          backgroundColor: AppColors.surfaceAlt,
          color: color,
        ),
      ),
    ],
  );
}

class _Point extends StatelessWidget {
  const _Point(this.n, this.text);
  final int n;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.navy,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$n',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}
