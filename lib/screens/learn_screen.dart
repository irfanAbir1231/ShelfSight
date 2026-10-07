import 'package:flutter/material.dart';

import '../models/coaching.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';
import 'coaching_player_screens.dart';

/// Sales coaching library: recommended, popular and completed modules.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  void _open(BuildContext context, CoachingModule m) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => AudioPlayerScreen(module: m)));

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, double>>(
      valueListenable: coachingProgress,
      builder: (context, progress, _) {
        final recommended = coachingModules.first;
        final completed = [
          for (final m in coachingModules)
            if ((progress[m.id] ?? 0) >= 1) m,
        ];
        final popular = [
          for (final m in coachingModules.skip(1))
            if ((progress[m.id] ?? 0) < 1) m,
        ];
        return FixedHeaderScrollView(
          title: 'Sales coaching',
          subtitle: 'Learn from proven field conversations',
          slivers: [
            pagePadding([
              const SectionTitle(title: 'Recommended for this visit'),
              const SizedBox(height: 8),
              _Recommended(
                module: recommended,
                progress: progress[recommended.id] ?? 0,
                onPlay: () => _open(context, recommended),
              ),
              const SizedBox(height: 22),
              const SectionTitle(title: 'Popular modules'),
              const SizedBox(height: 8),
              for (final m in popular)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ModuleRow(
                    module: m,
                    progress: progress[m.id] ?? 0,
                    onTap: () => _open(context, m),
                  ),
                ),
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 12),
                const SectionTitle(title: 'Completed modules'),
                const SizedBox(height: 8),
                for (final m in completed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ModuleRow(
                      module: m,
                      progress: 1,
                      onTap: () => _open(context, m),
                    ),
                  ),
              ],
            ]),
          ],
        );
      },
    );
  }
}

class _Recommended extends StatelessWidget {
  const _Recommended({
    required this.module,
    required this.progress,
    required this.onPlay,
  });
  final CoachingModule module;
  final double progress;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusPill(label: 'Top performer', icon: Icons.workspace_premium_rounded),
              StatusPill(
                label: 'Bengali audio',
                icon: Icons.translate_rounded,
                color: Colors.white,
                background: Color(0xFF22324F),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            module.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${module.durationLabel} · ${module.summary}',
            style: const TextStyle(color: Color(0xFFB6C2D4), height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    color: AppColors.emerald,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: progress > 0 ? 'Continue listening' : 'Play',
            icon: Icons.play_arrow_rounded,
            backgroundColor: AppColors.emerald,
            foregroundColor: AppColors.navy,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.module,
    required this.progress,
    required this.onTap,
  });
  final CoachingModule module;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = progress >= 1;
    return SurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: done ? AppColors.mint : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.play_arrow_rounded,
              color: AppColors.emeraldDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    height: 1.25,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  done
                      ? '${module.durationLabel} · Completed'
                      : '${module.durationLabel} · Bengali audio',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}
