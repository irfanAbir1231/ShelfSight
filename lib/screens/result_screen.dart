import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../services/analysis_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'detection_review_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.storeName,
    required this.imagePaths,
    required this.result,
  });
  final String storeName;
  final List<String> imagePaths;
  final AnalysisResult result;
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _submitted = false;
  final AnalysisApi _api = AnalysisApi();

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _SuccessView(
        storeName: widget.storeName,
        share: widget.result.summary.squareShare,
      );
    }
    final summary = widget.result.summary;
    final share = summary.squareShare.clamp(0, 100);
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis result')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.storeName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.imagePaths.length} shelf photos analyzed',
                              style: const TextStyle(color: AppColors.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      const StatusPill(
                        label: 'READY',
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'SQUARE FACING SHARE',
                          style: TextStyle(
                            color: Color(0xFFA7F3D0),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 208,
                          height: 208,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: CircularProgressIndicator(
                                  value: share / 100,
                                  strokeWidth: 17,
                                  backgroundColor: Color(0xFF334155),
                                  valueColor: AlwaysStoppedAnimation(
                                    AppColors.emerald,
                                  ),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Container(
                                width: 156,
                                height: 156,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF182337),
                                  shape: BoxShape.circle,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${share.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 46,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -2,
                                      ),
                                    ),
                                    Text(
                                      'of visible facings',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Square products represent ${summary.squareFacings} of ${summary.totalFacings} valid product facings.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .75),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ResultMetric(
                          label: 'Total facings',
                          value: '${summary.totalFacings}',
                          color: AppColors.navy,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _ResultMetric(
                          label: 'Square',
                          value: '${summary.squareFacings}',
                          color: AppColors.emeraldDark,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _ResultMetric(
                          label: 'Uncertain',
                          value: '${summary.uncertainFacings}',
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionTitle(
                    title: 'Detection preview',
                    action: 'Review all',
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DetectionReviewScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (widget.result.photos.isNotEmpty)
                            Image.network(
                              _api.artifactUrl(
                                widget.result.photos.first.annotatedImage,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const ShelfArtwork(radius: 0),
                            )
                          else
                            const ShelfArtwork(radius: 0),
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xD9111827),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Tap Review all to correct uncertain items',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (summary.uncertainFacings > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFB45309),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${summary.uncertainFacings} detections have low confidence. Review them before final submission for the most accurate share.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: PrimaryButton(
                label: 'Submit audit',
                icon: Icons.check_rounded,
                onPressed: () => setState(() => _submitted = true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.storeName, required this.share});
  final String storeName;
  final double share;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 54,
                color: AppColors.emeraldDark,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Audit submitted',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              '$storeName has been saved with a ${share.toStringAsFixed(1)}% Square product-facing share.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 22),
            const StatusPill(
              label: 'Synced successfully',
              icon: Icons.cloud_done_outlined,
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Back to dashboard',
              icon: Icons.home_outlined,
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        ),
      ),
    ),
  );
}
