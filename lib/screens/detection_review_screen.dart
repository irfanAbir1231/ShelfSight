import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

enum DetectionLabel { square, other, uncertain }

class DetectionReviewScreen extends StatefulWidget {
  const DetectionReviewScreen({super.key});

  @override
  State<DetectionReviewScreen> createState() => _DetectionReviewScreenState();
}

class _DetectionReviewScreenState extends State<DetectionReviewScreen> {
  String _filter = 'Uncertain';
  final List<DetectionLabel> _items = List.filled(7, DetectionLabel.uncertain);

  int get _remaining =>
      _items.where((item) => item == DetectionLabel.uncertain).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review detections'),
            Text(
              'Photo 1 of 3 • Left section',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          [
                            'All 126',
                            'Square 54',
                            'Other 65',
                            'Uncertain $_remaining',
                          ].map((label) {
                            final key = label.split(' ').first;
                            final selected = _filter == key;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(label),
                                selected: selected,
                                showCheckmark: false,
                                selectedColor: AppColors.navy,
                                labelStyle: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                                onSelected: (_) =>
                                    setState(() => _filter = key),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 360,
                    child: ShelfArtwork(
                      overlay: Stack(
                        children: [
                          const Positioned(
                            left: 22,
                            top: 54,
                            width: 92,
                            height: 90,
                            child: _ReviewBox(
                              index: 1,
                              label: 'Square 94%',
                              color: AppColors.emerald,
                            ),
                          ),
                          const Positioned(
                            right: 30,
                            top: 85,
                            width: 94,
                            height: 98,
                            child: _ReviewBox(
                              index: 2,
                              label: 'Other 91%',
                              color: Colors.white70,
                            ),
                          ),
                          const Positioned(
                            left: 126,
                            bottom: 65,
                            width: 104,
                            height: 93,
                            child: _ReviewBox(
                              index: 3,
                              label: 'Uncertain 61%',
                              color: AppColors.amber,
                              selected: true,
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xDD111827),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.touch_app_outlined,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tap a product box to review it',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.help_outline_rounded,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Detection #3',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      '61% confidence • logo partially visible',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const StatusPill(
                                label: 'UNCERTAIN',
                                color: Color(0xFFB45309),
                                background: Color(0xFFFEF3C7),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Classify this product',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.inkMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _classify(DetectionLabel.other),
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text('Other'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () =>
                                      _classify(DetectionLabel.square),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.emeraldDark,
                                  ),
                                  icon: const Icon(Icons.check_rounded),
                                  label: const Text('Square'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      '$_remaining uncertain detections remaining',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkMuted,
                      ),
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
                label: _remaining == 0
                    ? 'Save corrections'
                    : 'Save & continue later',
                icon: Icons.save_outlined,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _classify(DetectionLabel label) {
    final next = _items.indexOf(DetectionLabel.uncertain);
    if (next == -1) return;
    setState(() => _items[next] = label);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          label == DetectionLabel.square
              ? 'Marked as Square product'
              : 'Marked as other product',
        ),
        duration: const Duration(milliseconds: 700),
      ),
    );
  }
}

class _ReviewBox extends StatelessWidget {
  const _ReviewBox({
    required this.index,
    required this.label,
    required this.color,
    this.selected = false,
  });
  final int index;
  final String label;
  final Color color;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: color, width: selected ? 3 : 2),
      borderRadius: BorderRadius.circular(8),
      boxShadow: selected
          ? [BoxShadow(color: color.withValues(alpha: .35), blurRadius: 10)]
          : null,
    ),
    alignment: Alignment.topLeft,
    child: Transform.translate(
      offset: const Offset(-2, -21),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$index  $label',
          style: TextStyle(
            color: color == Colors.white70 ? AppColors.navy : Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ),
  );
}
