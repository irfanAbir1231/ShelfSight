import 'dart:async';

import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../models/audit_flow.dart';
import '../models/demo_result.dart';
import '../services/analysis_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';
import 'low_quality_screen.dart';
import 'result_screen.dart';

enum _Mode { running, failed }

/// Analysis in progress (screen 4) and its timeout state (screen 5).
class AnalysisProcessingScreen extends StatefulWidget {
  const AnalysisProcessingScreen({super.key, required this.storeName});
  final String storeName;

  @override
  State<AnalysisProcessingScreen> createState() =>
      _AnalysisProcessingScreenState();
}

class _AnalysisProcessingScreenState extends State<AnalysisProcessingScreen> {
  static const _stages = [
    ('Uploading photos', Icons.cloud_upload_outlined),
    ('Detecting soap products', Icons.center_focus_strong_rounded),
    ('Identifying Square products', Icons.auto_awesome_rounded),
    ('Calculating shelf share', Icons.donut_large_rounded),
  ];

  /// After this long without a result we show the friendly timeout state.
  static const _softTimeout = Duration(seconds: 150);

  final _api = AnalysisApi();
  late final AuditFlow _flow = AuditFlow.forShop(widget.storeName);
  _Mode _mode = _Mode.running;
  int _completed = 0; // stages with a real completion signal
  int _active = 0;
  int _run = 0; // generation counter; stale runs are ignored
  Timer? _cursor;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _run++;
    _cursor?.cancel();
    _timeout?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final run = ++_run;
    setState(() {
      _mode = _Mode.running;
      _completed = 0;
      _active = 0;
    });
    _cursor?.cancel();
    _timeout?.cancel();
    // The active stage cursor only shows activity; checkmarks are set by
    // real events (server reachable, response received).
    _cursor = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted && run == _run && _completed >= 1 && _active < 3) {
        setState(() => _active++);
      }
    });
    _timeout = Timer(_softTimeout, () {
      if (mounted && run == _run) _fail();
    });
    try {
      void ready() {
        if (mounted && run == _run) {
          setState(() {
            _completed = 1;
            _active = 1;
          });
        }
      }

      final paths = _flow.photos.value;
      final AnalysisResult result;
      if (paths.every(isDemoPhoto)) {
        // Bundled demo photos: simulate the stages without a server.
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        ready();
        await Future<void>.delayed(const Duration(milliseconds: 2400));
        result = buildDemoResult(paths);
      } else {
        result = await _api.analyze(paths, onServerReady: ready);
      }
      if (!mounted || run != _run) return;
      _cursor?.cancel();
      _timeout?.cancel();
      setState(() {
        _completed = 4;
        _active = 4;
      });
      final withPaths = result.withLocalPaths(_flow.photos.value);
      _flow.result = withPaths;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted && run == _run) _finish(withPaths);
    } on AnalysisApiException {
      if (mounted && run == _run) _fail();
    } catch (_) {
      if (mounted && run == _run) _fail();
    }
  }

  void _fail() {
    _cursor?.cancel();
    _timeout?.cancel();
    _run++; // ignore any late result; photos stay in the flow
    setState(() => _mode = _Mode.failed);
  }

  void _finish(AnalysisResult result) {
    final bad = result.lowQualityIndexes;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => bad.isEmpty
            ? ResultScreen(storeName: widget.storeName, result: result)
            : LowQualityScreen(storeName: widget.storeName, result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final failed = _mode == _Mode.failed;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: FixedHeaderScrollView(
        title: failed ? 'Analysis paused' : 'Analyzing Soap shelf',
        subtitle: widget.storeName,
        showNavInset: false,
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            if (failed) _timeoutBody(context) else _progressBody(context),
          ]),
        ],
      ),
    );
  }

  Widget _progressBody(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: AppColors.emerald,
                  backgroundColor: AppColors.border,
                ),
              ),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.emerald,
                  size: 40,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SurfaceCard(
          child: Column(
            children: [
              for (var i = 0; i < _stages.length; i++)
                _StageRow(
                  label: _stages[i].$1,
                  icon: _stages[i].$2,
                  done: i < _completed,
                  active: i == _active && i >= _completed && _completed < 4,
                  last: i == _stages.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: AppColors.inkMuted),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'The server may need a moment to wake up',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const PrimaryButton(
          label: 'Analysis in progress',
          icon: Icons.hourglass_top_rounded,
          onPressed: null,
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            foregroundColor: AppColors.inkMuted,
          ),
          child: const Text(
            'Cancel and return to photos',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _timeoutBody(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: AppColors.amberSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.hourglass_bottom_rounded,
            size: 56,
            color: AppColors.amberText,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Analysis is taking longer than expected',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            height: 1.25,
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'The analysis service may still be waking up. Your photos are safe.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15.5, height: 1.45),
        ),
        const SizedBox(height: 14),
        StatusPill(
          label: '${_flow.photos.value.length} photos saved on this phone',
          icon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Retry analysis',
          icon: Icons.refresh_rounded,
          onPressed: _start,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: AppColors.navy, width: 1.5),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Return to review',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.label,
    required this.icon,
    required this.done,
    required this.active,
    required this.last,
  });
  final String label;
  final IconData icon;
  final bool done;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: done
                ? const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.emeraldDark,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, size: 19, color: Colors.white),
                  )
                : active
                ? const Padding(
                    padding: EdgeInsets.all(4),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.emeraldDark,
                    ),
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: active || done ? FontWeight.w800 : FontWeight.w600,
                color: done || active ? AppColors.ink : AppColors.inkMuted,
              ),
            ),
          ),
          if (done)
            const Text(
              'Done',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.emeraldDark,
              ),
            )
          else if (active)
            const Text('Working…', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
