import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/coaching.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/onboarding_widgets.dart';
import '../widgets/shell_widgets.dart';
import 'app_shell.dart';

/// Simulated audio playback. Swap the timer for a real audio player (no
/// download is offered; streaming only).
class PlaybackController extends ChangeNotifier {
  PlaybackController(this.module)
    : position = ((coachingProgress.value[module.id] ?? 0) < 1
          ? (coachingProgress.value[module.id] ?? 0) * module.seconds
          : 0).toDouble();

  final CoachingModule module;
  double position; // seconds
  bool playing = false;
  double speed = 1;
  Timer? _timer;

  static const speeds = [1.0, 1.25, 1.5, .75];

  double get fraction => position / module.seconds;

  void toggle() {
    playing = !playing;
    _timer?.cancel();
    if (playing) {
      _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        position = math.min(
          module.seconds.toDouble(),
          position + .25 * speed,
        );
        if (position >= module.seconds) {
          playing = false;
          _timer?.cancel();
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void seekBy(double seconds) => seekTo(position + seconds);

  void seekTo(double seconds) {
    position = seconds.clamp(0, module.seconds.toDouble());
    notifyListeners();
  }

  void cycleSpeed() {
    speed = speeds[(speeds.indexOf(speed) + 1) % speeds.length];
    notifyListeners();
  }

  void saveProgress() => setCoachingProgress(
    module.id,
    (coachingProgress.value[module.id] ?? 0) >= 1 ? 1 : fraction,
  );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

String _clock(double s) {
  final t = s.round();
  return '${(t ~/ 60).toString().padLeft(2, '0')}:'
      '${(t % 60).toString().padLeft(2, '0')}';
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key, required this.module});
  final CoachingModule module;

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late final PlaybackController _p = PlaybackController(widget.module);

  @override
  void dispose() {
    _p.saveProgress();
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.module;
    return RoleNavScaffold(
      activeTab: 2,
      body: FixedHeaderScrollView(
        title: 'Coaching',
        subtitle: m.durationLabel,
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            AspectRatio(
              aspectRatio: 1.35,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: AppColors.navy),
                    const ShelfPattern(opacity: .08, rows: 4),
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(
                          Icons.headphones_rounded,
                          size: 44,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              m.title,
              style: const TextStyle(
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: -.4,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Top Performer Demo Voice',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                StatusPill(
                  label: 'Approved training voice',
                  icon: Icons.verified_user_outlined,
                ),
                StatusPill(
                  label: 'Bengali audio',
                  icon: Icons.translate_rounded,
                  color: AppColors.ink,
                  background: AppColors.surfaceAlt,
                ),
              ],
            ),
            const SizedBox(height: 18),
            ListenableBuilder(
              listenable: _p,
              builder: (context, _) => Column(
                children: [
                  _Waveform(
                    fraction: _p.fraction,
                    onSeek: (f) => _p.seekTo(f * m.seconds),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _clock(_p.position),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(_clock(m.seconds.toDouble())),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SpeedButton(
                        label: '${_p.speed}x',
                        onTap: _p.cycleSpeed,
                      ),
                      IconButton(
                        tooltip: 'Back 15 seconds',
                        onPressed: () => _p.seekBy(-15),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(56, 56),
                        ),
                        icon: const Icon(Icons.replay_rounded, size: 32),
                      ),
                      Semantics(
                        button: true,
                        label: _p.playing ? 'Pause' : 'Play',
                        child: GestureDetector(
                          onTap: _p.toggle,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: AppColors.navy,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _p.playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Forward 15 seconds',
                        onPressed: () => _p.seekBy(15),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(56, 56),
                        ),
                        icon: const Icon(Icons.forward_rounded, size: 32),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TranscriptScreen(playback: _p),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(56, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          foregroundColor: AppColors.navy,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Icon(Icons.notes_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Mark complete',
              icon: Icons.check_rounded,
              backgroundColor: AppColors.emeraldDark,
              onPressed: () {
                setCoachingProgress(m.id, 1);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Module marked complete.')),
                  );
                Navigator.of(context).pop();
              },
            ),
          ]),
        ],
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Playback speed $label',
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 52, minHeight: 48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
    ),
  );
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.fraction, required this.onSeek});
  final double fraction;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => GestureDetector(
        onTapDown: (d) => onSeek((d.localPosition.dx / c.maxWidth).clamp(0, 1)),
        onHorizontalDragUpdate: (d) =>
            onSeek((d.localPosition.dx / c.maxWidth).clamp(0, 1)),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: CustomPaint(painter: _WavePainter(fraction)),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.fraction);
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    const bar = 4.0, gap = 3.0;
    final n = (size.width / (bar + gap)).floor();
    final rng = math.Random(9);
    for (var i = 0; i < n; i++) {
      final h = 10 + rng.nextDouble() * (size.height - 14);
      final x = i * (bar + gap);
      final played = (i + .5) / n <= fraction;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - h) / 2, bar, h),
          const Radius.circular(2),
        ),
        Paint()..color = played ? AppColors.emeraldDark : AppColors.border,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.fraction != fraction;
}

/// Bengali transcript with the four conversation stages highlighted.
class TranscriptScreen extends StatelessWidget {
  const TranscriptScreen({super.key, required this.playback});
  final PlaybackController playback;

  static const _stageColors = {
    'Opening': Color(0xFF475569),
    'Product value': AppColors.emeraldDark,
    'Low-risk proposal': Color(0xFF0B1426),
    'Closing question': Color(0xFF92580A),
  };

  @override
  Widget build(BuildContext context) {
    return RoleNavScaffold(
      activeTab: 2,
      body: FixedHeaderScrollView(
        title: 'Transcript',
        subtitle: playback.module.title,
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            ListenableBuilder(
              listenable: playback,
              builder: (context, _) {
                var current = 0;
                for (var i = 0; i < soapVisibilityTranscript.length; i++) {
                  if (playback.fraction >=
                      soapVisibilityTranscript[i].startFraction) {
                    current = i;
                  }
                }
                return Column(
                  children: [
                    for (var i = 0; i < soapVisibilityTranscript.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _Line(
                          line: soapVisibilityTranscript[i],
                          color: _stageColors[soapVisibilityTranscript[i].stage]!,
                          active: playback.playing && i == current,
                          onTap: () => playback.seekTo(
                            soapVisibilityTranscript[i].startFraction *
                                playback.module.seconds,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.inkMuted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Training content provides examples. Sales claims must '
                      'remain accurate and respectful.',
                      style: TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.line,
    required this.color,
    required this.active,
    required this.onTap,
  });
  final TranscriptLine line;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shop = line.speaker == 'Shopkeeper';
    return SurfaceCard(
      onTap: onTap,
      color: active ? AppColors.mint : Colors.white,
      borderColor: active ? AppColors.emeraldDark : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                shop ? Icons.storefront_rounded : Icons.person_rounded,
                size: 18,
                color: AppColors.inkMuted,
              ),
              const SizedBox(width: 6),
              Text(
                line.speaker,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              if (!shop)
                StatusPill(
                  label: line.stage,
                  color: color,
                  background: color.withValues(alpha: .1),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            line.text,
            style: const TextStyle(
              fontSize: 17,
              height: 1.6,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
