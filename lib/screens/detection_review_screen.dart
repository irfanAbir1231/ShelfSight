import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../theme/app_theme.dart';
import '../widgets/annotated_image.dart';
import '../widgets/app_widgets.dart';
import '../widgets/photo_image.dart';
import '../widgets/shell_widgets.dart';

const _slate = Color(0xFF64748B);

Color labelColor(String label) => switch (label) {
  'square' => AppColors.emerald,
  'other' => _slate,
  _ => AppColors.amber,
};

String labelName(String label) => switch (label) {
  'square' => 'Square',
  'other' => 'Other',
  _ => 'Uncertain',
};

String labelTag(String label) => switch (label) {
  'square' => 'SQUARE',
  'other' => 'OTHER',
  _ => '?',
};

/// Sales Officer bounding-box review. Labels are Square / Other / Uncertain
/// only; company names are never shown here.
class DetectionReviewScreen extends StatefulWidget {
  const DetectionReviewScreen({
    super.key,
    required this.storeName,
    required this.result,
  });
  final String storeName;
  final AnalysisResult result;

  @override
  State<DetectionReviewScreen> createState() => _DetectionReviewScreenState();
}

class _DetectionReviewScreenState extends State<DetectionReviewScreen> {
  int _photo = 0;
  String _filter = 'all';
  String? _selectedId;

  PhotoAnalysis get _current => widget.result.photos[_photo];

  int _count(String label) => label == 'all'
      ? _current.detections.length
      : _current.detections.where((d) => d.label == label).length;

  ProductDetection? get _selected {
    for (final d in _current.detections) {
      if (d.id == _selectedId) return d;
    }
    return null;
  }

  void _report() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report an issue',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text('What looks wrong with these detections?'),
            const SizedBox(height: 8),
            for (final t in const [
              'A product is missing a box',
              'A box is on the wrong product',
              'A Square product is not marked Square',
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                minVerticalPadding: 12,
                title: Text(t),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(sheet).pop();
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Thanks. Your report was recorded.'),
                      ),
                    );
                },
              ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final photo = _current;
    final path = photo.localPath;
    final boxes = [
      for (final d in photo.detections)
        if (_filter == 'all' || d.label == _filter)
          BoxOverlay(
            id: d.id,
            box: d.box,
            color: labelColor(d.label),
            tag: labelTag(d.label),
            selected: d.id == _selectedId,
          ),
    ];
    final sel = _selected;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: FixedHeaderScrollView(
        title: 'Review detections',
        subtitle: widget.storeName,
        showNavInset: false,
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          SliverToBoxAdapter(
            child: AnnotatedImage(
              image: path != null ? photoProvider(path) : null,
              fallback: const ShelfArtwork(radius: 0),
              boxes: boxes,
              onBoxTap: (id) => setState(() => _selectedId = id),
            ),
          ),
          pagePadding([
            const SizedBox(height: 12),
            if (widget.result.photos.length > 1) ...[
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < widget.result.photos.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('Photo ${i + 1}'),
                          selected: i == _photo,
                          onSelected: (_) => setState(() {
                            _photo = i;
                            _selectedId = null;
                          }),
                          showCheckmark: false,
                          selectedColor: AppColors.navy,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: i == _photo ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final f in const ['all', 'square', 'other', 'uncertain'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          '${f == 'all' ? 'All' : labelName(f)} ${_count(f)}',
                        ),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                        avatar: f == 'all'
                            ? null
                            : CircleAvatar(
                                radius: 6,
                                backgroundColor: labelColor(f),
                              ),
                        showCheckmark: false,
                        selectedColor: AppColors.mint,
                        side: BorderSide(
                          color: _filter == f
                              ? AppColors.emeraldDark
                              : AppColors.border,
                          width: _filter == f ? 2 : 1,
                        ),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_count('all')} products found · ${_count('square')} Square · '
              '${_count('other')} Other · ${_count('uncertain')} Uncertain',
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            SurfaceCard(
              child: sel == null
                  ? const Row(
                      children: [
                        Icon(Icons.touch_app_outlined, color: AppColors.inkMuted),
                        SizedBox(width: 10),
                        Expanded(child: Text('Tap a box to see product details')),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: labelColor(sel.label),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              labelName(sel.label),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(sel.confidence * 100).round()}% confidence',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sel.label == 'uncertain'
                              ? 'Not sure if this is Square. Check the label.'
                              : sel.label == 'square'
                              ? 'Square logo matched on this product.'
                              : 'Not recognised as a Square product.',
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Confirm detections',
              icon: Icons.check_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Detections confirmed.')),
                  );
              },
            ),
            Center(
              child: TextButton.icon(
                onPressed: _report,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: AppColors.inkMuted,
                ),
                icon: const Icon(Icons.flag_outlined),
                label: const Text(
                  'Report an issue',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
