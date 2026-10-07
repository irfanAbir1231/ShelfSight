import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/audit_flow.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';
import 'analysis_processing_screen.dart';
import 'capture_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.storeName});
  final String storeName;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _picker = ImagePicker();
  late final AuditFlow _flow = AuditFlow.forShop(widget.storeName);
  int _index = 0;
  final _checks = <String, bool>{
    'Shelf visible': true,
    'Image sharp': true,
    'Products front-facing': true,
  };

  List<String> get _photos => _flow.photos.value;

  @override
  void initState() {
    super.initState();
    _flow.photos.addListener(_changed);
  }

  @override
  void dispose() {
    _flow.photos.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {
      if (_index >= _photos.length) _index = (_photos.length - 1).clamp(0, 99);
    });
  }

  Future<void> _replace(ImageSource source) async {
    final shot = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2400,
    );
    if (shot != null && _index < _photos.length) {
      _flow.replaceAt(_index, shot.path);
    }
  }

  void _delete() {
    if (_photos.isEmpty) return;
    _flow.removeAt(_index);
    if (_photos.isEmpty && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    if (photos.isEmpty) return const Scaffold();
    final allGood = _checks.values.every((v) => v);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: FixedHeaderScrollView(
        title: 'Review photos',
        subtitle: '${widget.storeName} · Soap',
        showNavInset: false,
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(photos[_index]),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ShelfArtwork(radius: 20),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: StatusPill(
                      label: 'Photo ${_index + 1} of ${photos.length}',
                      icon: Icons.photo_outlined,
                      color: Colors.white,
                      background: AppColors.navy.withValues(alpha: .78),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => Semantics(
                  button: true,
                  selected: i == _index,
                  label: 'Photo ${i + 1}',
                  child: GestureDetector(
                    onTap: () => setState(() => _index = i),
                    child: Container(
                      width: 68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: i == _index
                              ? AppColors.emeraldDark
                              : AppColors.border,
                          width: i == _index ? 3 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(
                          File(photos[i]),
                          fit: BoxFit.cover,
                          cacheWidth: 180,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: AppColors.surfaceAlt),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Action(
                    icon: Icons.photo_camera_outlined,
                    label: 'Retake',
                    onTap: () => _replace(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Action(
                    icon: Icons.photo_library_outlined,
                    label: 'Replace',
                    onTap: () => _replace(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Action(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    onTap: _delete,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionTitle(title: 'Quality check'),
            const SizedBox(height: 8),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  for (final e in _checks.entries)
                    CheckboxListTile(
                      value: e.value,
                      onChanged: (v) =>
                          setState(() => _checks[e.key] = v ?? false),
                      activeColor: AppColors.emeraldDark,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),
                      title: Text(
                        e.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!allGood) ...[
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFF92580A),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Consider retaking this photo for a more accurate count.',
                      style: TextStyle(color: Color(0xFF92580A)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CaptureScreen(
                      storeName: widget.storeName,
                      returnToReview: true,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy, width: 1.5),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text(
                  'Add another photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Analyze Soap shelf',
              icon: Icons.auto_awesome_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AnalysisProcessingScreen(storeName: widget.storeName),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Square results will appear here. Competitor details will be '
              'sent to your Territory Officer.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.4),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.border),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        maxLines: 1,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
  );
}
