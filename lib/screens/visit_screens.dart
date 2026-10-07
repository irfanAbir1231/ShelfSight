import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';
import '../widgets/street_map.dart';
import 'app_shell.dart';
import 'capture_screen.dart';
import 'review_screen.dart';

/// The visit in progress. One at a time; later screens advance [step].
class ActiveVisit {
  ActiveVisit(this.shop) : startedAt = DateTime.now();
  final Shop shop;
  final DateTime startedAt;
  final ValueNotifier<int> step = ValueNotifier(0);
  static ActiveVisit? current;
}

String formatClock(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
}

const _steps = [
  ('Select category', Icons.category_outlined),
  ('Capture shelf', Icons.photo_camera_outlined),
  ('Review result', Icons.fact_check_outlined),
  ('Complete visit', Icons.flag_outlined),
];

/// Visit screen 1: overview of the active shop visit.
class VisitOverviewScreen extends StatefulWidget {
  const VisitOverviewScreen({super.key, required this.shop});
  final Shop shop;

  @override
  State<VisitOverviewScreen> createState() => _VisitOverviewScreenState();
}

class _VisitOverviewScreenState extends State<VisitOverviewScreen> {
  late final ActiveVisit _visit;
  final _mapKey = GlobalKey<StreetMapState>();
  Timer? _tick;
  bool _paused = false;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _visit = ActiveVisit.current?.shop.id == widget.shop.id
        ? ActiveVisit.current!
        : (ActiveVisit.current = ActiveVisit(widget.shop));
    _elapsed = DateTime.now().difference(_visit.startedAt);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused && mounted) {
        setState(() => _elapsed += const Duration(seconds: 1));
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      final s = widget.shop;
      _mapKey.currentState?.flyTo(
        s.lat,
        s.lng,
        scale: 1.7,
        duration: const Duration(milliseconds: 1),
      );
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String get _timer {
    final m = _elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final (lat, lng) = DemoData.locationFor(DemoLocation.insideShop);
    return RoleNavScaffold(
      activeTab: 0,
      body: FixedHeaderScrollView(
        title: _paused ? 'Visit paused' : 'Visit active',
        subtitle: 'Started ${formatClock(_visit.startedAt)}',
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: SizedBox(
                      height: 130,
                      child: Stack(
                        children: [
                          IgnorePointer(
                            child: StreetMap(
                              key: _mapKey,
                              shops: [shop],
                              userLat: lat,
                              userLng: lng,
                              activeShopId: shop.id,
                              onShopTap: (_) {},
                            ),
                          ),
                          const Positioned(
                            left: 8,
                            bottom: 6,
                            child: Text(
                              '© OpenStreetMap contributors',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const StatusPill(
                                label: 'Location verified',
                                icon: Icons.verified_rounded,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _timer,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.5,
                                color: AppColors.ink,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            Text(
                              _paused ? 'Paused' : 'Visit time',
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle(title: 'Visit progress'),
            const SizedBox(height: 8),
            ValueListenableBuilder<int>(
              valueListenable: _visit.step,
              builder: (context, step, _) => SurfaceCard(
                child: Column(
                  children: [
                    for (var i = 0; i < _steps.length; i++)
                      _StepRow(
                        index: i,
                        label: _steps[i].$1,
                        state: i < step
                            ? _StepState.done
                            : i == step
                            ? _StepState.current
                            : _StepState.upcoming,
                        last: i == _steps.length - 1,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Select product category',
              icon: Icons.category_rounded,
              onPressed: _paused
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategorySelectionScreen(shop: shop),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _paused = !_paused),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy, width: 1.5),
                  shape: const StadiumBorder(),
                ),
                icon: Icon(
                  _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                ),
                label: Text(
                  _paused ? 'Resume visit' : 'Pause visit',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const SectionTitle(title: 'Shop information'),
            const SizedBox(height: 8),
            SurfaceCard(
              child: Column(
                children: [
                  _Info(Icons.place_outlined, 'Address', shop.address),
                  _Info(
                    Icons.pie_chart_outline_rounded,
                    'Previous Square soap share',
                    '${shop.squareShare ?? 32}%',
                  ),
                  const _Info(
                    Icons.event_available_outlined,
                    'Last audit',
                    '3 Oct 2026',
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

enum _StepState { done, current, upcoming }

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.label,
    required this.state,
    required this.last,
  });
  final int index;
  final String label;
  final _StepState state;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final done = state == _StepState.done;
    final current = state == _StepState.current;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? AppColors.emeraldDark
                  : current
                  ? AppColors.navy
                  : AppColors.surfaceAlt,
            ),
            child: done
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: current ? Colors.white : AppColors.inkMuted,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                color: state == _StepState.upcoming
                    ? AppColors.inkMuted
                    : AppColors.ink,
              ),
            ),
          ),
          if (current) const StatusPill(label: 'Next'),
          if (done)
            const Text(
              'Done',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.emeraldDark,
              ),
            ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.inkMuted),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

const _categoryIcons = {
  'Soap': Icons.clean_hands_rounded,
  'Shampoo': Icons.water_drop_outlined,
  'Toothpaste': Icons.brush_outlined,
  'Detergent': Icons.local_laundry_service_outlined,
  'Dishwashing Liquid': Icons.wash_outlined,
  'Toilet Cleaner': Icons.cleaning_services_outlined,
};

/// Visit screens 2 + 3: category list and the "coming soon" sheet.
class CategorySelectionScreen extends StatelessWidget {
  const CategorySelectionScreen({super.key, required this.shop});
  final Shop shop;

  void _open(BuildContext context, ProductCategory c) {
    if (c.active) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SoapInstructionsScreen(shop: shop),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheet) => _ComingSoonSheet(
        category: c,
        onSoap: () {
          Navigator.of(sheet).pop();
          _open(context, productCategories.first);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleNavScaffold(
      activeTab: 0,
      body: FixedHeaderScrollView(
        title: 'Choose a product category',
        subtitle: 'Select the shelf you want to audit',
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            for (final c in productCategories)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: c.active
                    ? _SoapCard(onTap: () => _open(context, c))
                    : _InactiveCard(
                        category: c,
                        onTap: () => _open(context, c),
                      ),
              ),
          ]),
        ],
      ),
    );
  }
}

class _SoapCard extends StatelessWidget {
  const _SoapCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    padding: const EdgeInsets.all(18),
    color: AppColors.mint,
    borderColor: AppColors.emeraldDark,
    child: Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.emeraldDark,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.clean_hands_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Soap',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(width: 8),
                  StatusPill(
                    label: 'Active',
                    icon: Icons.check_circle_rounded,
                    color: Colors.white,
                    background: AppColors.emeraldDark,
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Shelf analysis available',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF065F46),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Last audit: 3 Oct · Square share 32%',
                style: TextStyle(fontSize: 13.5, color: Color(0xFF065F46)),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, size: 30, color: AppColors.ink),
      ],
    ),
  );
}

class _InactiveCard extends StatelessWidget {
  const _InactiveCard({required this.category, required this.onTap});
  final ProductCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    color: AppColors.surfaceAlt,
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _categoryIcons[category.name],
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Coming soon · Model preparation pending',
                style: TextStyle(fontSize: 13.5),
              ),
            ],
          ),
        ),
        const Icon(Icons.schedule_rounded, color: AppColors.inkMuted),
      ],
    ),
  );
}

class _ComingSoonSheet extends StatelessWidget {
  const _ComingSoonSheet({required this.category, required this.onSoap});
  final ProductCategory category;
  final VoidCallback onSoap;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _categoryIcons[category.name],
              size: 32,
              color: AppColors.emeraldDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            category.name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Analysis coming soon',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This category is prepared in the system, but its detection model '
            'has not been trained yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Continue with Soap',
            icon: Icons.clean_hands_rounded,
            onPressed: onSoap,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: AppColors.inkMuted,
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Visit screen 4: how to capture the Soap shelf.
class SoapInstructionsScreen extends StatelessWidget {
  const SoapInstructionsScreen({super.key, required this.shop});
  final Shop shop;

  void _camera(BuildContext context) {
    ActiveVisit.current?.step.value = 1;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CaptureScreen(storeName: shop.name)),
    );
  }

  Future<void> _gallery(BuildContext context) async {
    final photos = await ImagePicker().pickMultiImage(
      imageQuality: 88,
      maxWidth: 2400,
    );
    if (photos.isEmpty || !context.mounted) return;
    ActiveVisit.current?.step.value = 1;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          storeName: shop.name,
          imagePaths: photos.map((p) => p.path).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleNavScaffold(
      activeTab: 0,
      body: FixedHeaderScrollView(
        title: 'Capture the Soap shelf',
        subtitle: shop.name,
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Example(
                    good: true,
                    caption: 'Full shelf, front-facing, sharp',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _Example(
                    good: false,
                    caption: 'Glare, blur or cut-off rows',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SurfaceCard(
              child: Column(
                children: [
                  _Tip(
                    Icons.crop_free_rounded,
                    'Capture the full shelf section',
                  ),
                  _Tip(
                    Icons.view_module_outlined,
                    'Keep products front-facing',
                  ),
                  _Tip(
                    Icons.light_mode_outlined,
                    'Avoid glare and motion blur',
                  ),
                  _Tip(
                    Icons.photo_library_outlined,
                    'Take multiple photos for wide shelves',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const SurfaceCard(
              color: AppColors.mint,
              borderColor: AppColors.emeraldDark,
              child: Row(
                children: [
                  Icon(Icons.track_changes_rounded, color: AppColors.emeraldDark),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detected target: Square products and visible '
                      'competitor soap brands',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF065F46),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.inkMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Competitive data will be shared only with the Territory Officer',
                    style: TextStyle(fontSize: 13.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Open camera',
              icon: Icons.photo_camera_rounded,
              onPressed: () => _camera(context),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _gallery(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy, width: 1.5),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text(
                  'Choose from gallery',
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

class _Tip extends StatelessWidget {
  const _Tip(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, color: AppColors.emeraldDark),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Example extends StatelessWidget {
  const _Example({required this.good, required this.caption});
  final bool good;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final color = good ? AppColors.emeraldDark : const Color(0xFF92580A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.25,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (good)
                const ShelfArtwork(radius: 16)
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ImageFiltered(
                        imageFilter: ColorFilter.mode(
                          Colors.white.withValues(alpha: .15),
                          BlendMode.srcOver,
                        ),
                        child: const ShelfArtwork(radius: 0),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xCCFFFFFF), Color(0x00FFFFFF)],
                            stops: [0, .55],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    good ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: color,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          good ? 'Good' : 'Avoid',
          style: TextStyle(fontWeight: FontWeight.w800, color: color),
        ),
        Text(caption, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
