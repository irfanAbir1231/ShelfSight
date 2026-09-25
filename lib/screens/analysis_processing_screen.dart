import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../services/analysis_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'result_screen.dart';

class AnalysisProcessingScreen extends StatefulWidget {
  const AnalysisProcessingScreen({
    super.key,
    required this.storeName,
    required this.imagePaths,
  });
  final String storeName;
  final List<String> imagePaths;

  @override
  State<AnalysisProcessingScreen> createState() =>
      _AnalysisProcessingScreenState();
}

class _AnalysisProcessingScreenState extends State<AnalysisProcessingScreen> {
  final AnalysisApi _api = AnalysisApi();
  AnalysisResult? _result;
  String? _error;
  int _activeStep = 0;

  static const _steps = [
    (
      'Uploading photos',
      'Sending full-quality shelf images',
      Icons.cloud_upload_outlined,
    ),
    (
      'Detecting products',
      'Finding visible product facings',
      Icons.center_focus_strong_rounded,
    ),
    (
      'Identifying Square',
      'Checking Square logo evidence',
      Icons.auto_awesome_rounded,
    ),
    (
      'Calculating share',
      'Building the final audit result',
      Icons.donut_large_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _result = null;
      _error = null;
      _activeStep = 0;
    });
    try {
      final future = _api.analyze(widget.imagePaths);
      for (var step = 1; step < _steps.length; step++) {
        await Future<void>.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;
        setState(() => _activeStep = step);
      }
      final result = await future;
      if (!mounted) return;
      setState(() {
        _result = result;
        _activeStep = _steps.length;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _result != null;
    final failed = _error != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Analyzing shelf')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.mint
                      : failed
                      ? const Color(0xFFFEE2E2)
                      : AppColors.navy,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22111827),
                      blurRadius: 30,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        size: 58,
                        color: AppColors.emeraldDark,
                      )
                    : failed
                    ? const Icon(
                        Icons.cloud_off_rounded,
                        size: 50,
                        color: AppColors.red,
                      )
                    : const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                          color: AppColors.emerald,
                          backgroundColor: Color(0xFF334155),
                        ),
                      ),
              ),
              const SizedBox(height: 28),
              Text(
                done
                    ? 'Analysis complete'
                    : failed
                    ? 'Analysis could not finish'
                    : 'AI is reviewing your shelf',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                failed
                    ? _error!
                    : '${widget.imagePaths.length} photos from ${widget.storeName}',
                style: TextStyle(
                  color: failed ? AppColors.red : AppColors.inkMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: List.generate(_steps.length, (index) {
                      final step = _steps[index];
                      final complete = done || index < _activeStep;
                      final active = !done && !failed && index == _activeStep;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _steps.length - 1 ? 0 : 18,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: complete
                                    ? AppColors.mint
                                    : active
                                    ? AppColors.navy
                                    : AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                complete ? Icons.check_rounded : step.$3,
                                size: 19,
                                color: complete
                                    ? AppColors.emeraldDark
                                    : active
                                    ? Colors.white
                                    : AppColors.inkMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.$1,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: active || complete
                                          ? AppColors.navy
                                          : AppColors.inkMuted,
                                    ),
                                  ),
                                  Text(
                                    step.$2,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (active)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.emerald,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const Spacer(),
              if (failed)
                PrimaryButton(
                  label: 'Retry analysis',
                  icon: Icons.refresh_rounded,
                  onPressed: _startAnalysis,
                )
              else
                PrimaryButton(
                  label: done ? 'View results' : 'Analysis in progress',
                  icon: done
                      ? Icons.arrow_forward_rounded
                      : Icons.hourglass_top_rounded,
                  onPressed: done
                      ? () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => ResultScreen(
                              storeName: widget.storeName,
                              imagePaths: widget.imagePaths,
                              result: _result!,
                            ),
                          ),
                        )
                      : null,
                ),
              const SizedBox(height: 8),
              Text(
                failed
                    ? 'Server: ${AnalysisApi.baseUrl}'
                    : 'Keep this screen open until analysis completes',
                style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
