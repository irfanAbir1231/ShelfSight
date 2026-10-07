import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../models/audit_flow.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/photo_image.dart';
import '../widgets/shell_widgets.dart';
import 'capture_screen.dart';
import 'result_screen.dart';

/// Warning state after analysis: one or more photos failed the quality check.
/// Amber styling, never red.
class LowQualityScreen extends StatelessWidget {
  const LowQualityScreen({
    super.key,
    required this.storeName,
    required this.result,
  });
  final String storeName;
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final flow = AuditFlow.forShop(storeName);
    final bad = result.lowQualityIndexes;
    final remaining = result.photos.length - bad.length;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: FixedHeaderScrollView(
        title: 'Photo check',
        subtitle: storeName,
        showNavInset: false,
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.amberSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.amber),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.amberText,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bad.length == 1
                              ? 'One photo needs attention'
                              : '${bad.length} photos need attention',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.amberDeep,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'A clearer photo gives a more accurate shelf count.',
                          style: TextStyle(color: AppColors.amberDeep),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final i in bad)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SurfaceCard(
                  borderColor: AppColors.amber,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 92,
                          height: 92,
                          child: _thumb(result.photos[i]),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Photo ${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            for (final w in result.photos[i].quality.warnings)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 18,
                                      color: AppColors.amberText,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        friendlyQualityReason(w),
                                        style: const TextStyle(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            PrimaryButton(
              label: 'Retake photo',
              icon: Icons.photo_camera_rounded,
              onPressed: () {
                final nav = Navigator.of(context);
                for (final i in bad.reversed) {
                  if (i < flow.photos.value.length) flow.removeAt(i);
                }
                nav.pop();
                nav.push(
                  MaterialPageRoute(
                    builder: (_) =>
                        CaptureScreen(storeName: storeName, returnToReview: true),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: remaining == 0
                    ? null
                    : () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => ResultScreen(
                            storeName: storeName,
                            result: result.keeping({
                              for (var i = 0; i < result.photos.length; i++)
                                if (!bad.contains(i)) i,
                            }),
                          ),
                        ),
                      ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: BorderSide(
                    color: remaining == 0 ? AppColors.border : AppColors.navy,
                    width: 1.5,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Continue with remaining photos ($remaining)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (remaining == 0)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Every photo needs attention. Retake to continue.',
                  textAlign: TextAlign.center,
                ),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _thumb(PhotoAnalysis p) {
    final path = p.localPath;
    if (path == null) return const ShelfArtwork(radius: 0);
    return Image(
      image: photoProvider(path, cacheWidth: 240),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ShelfArtwork(radius: 0),
    );
  }
}
