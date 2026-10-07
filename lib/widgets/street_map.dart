import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/session.dart';
import '../theme/app_theme.dart';

/// Offline OpenStreetMap-style street map (painted) for the Gulshan demo.
/// Swap [StreetMap] for flutter_map + OSM tiles in production; the marker
/// widgets and [MapProjection] can stay the same.
abstract final class MapProjection {
  static const width = 2400.0;
  static const height = 2200.0;
  static const _lat0 = 23.766, _lat1 = 23.800;
  static const _lng0 = 90.395, _lng1 = 90.430;

  static Offset project(double lat, double lng) => Offset(
    (lng - _lng0) / (_lng1 - _lng0) * width,
    (1 - (lat - _lat0) / (_lat1 - _lat0)) * height,
  );
}

class MapOfficer {
  const MapOfficer(this.initials, this.lat, this.lng);
  final String initials;
  final double lat;
  final double lng;
}

class StreetMap extends StatefulWidget {
  const StreetMap({
    super.key,
    required this.shops,
    required this.userLat,
    required this.userLng,
    required this.onShopTap,
    this.activeShopId,
    this.selectedShopId,
    this.topInset = 0,
    this.bottomInset = 0,
    this.shopColors = const {},
    this.showUser = true,
    this.officers = const [],
  });

  final List<Shop> shops;
  final double userLat;
  final double userLng;

  /// Shop shown as the larger emerald "detected" pin.
  final String? activeShopId;
  final String? selectedShopId;
  final ValueChanged<Shop> onShopTap;

  /// Pin fill overrides by shop id (e.g. Territory share status colors).
  final Map<String, Color> shopColors;
  final bool showUser;

  /// Sales Officers currently on a visit (Territory map only).
  final List<MapOfficer> officers;

  /// Space covered by glass chrome; the camera centers in the remaining area.
  final double topInset;
  final double bottomInset;

  @override
  State<StreetMap> createState() => StreetMapState();
}

class StreetMapState extends State<StreetMap> with TickerProviderStateMixin {
  final _controller = TransformationController();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();
  late final AnimationController _camera = AnimationController(vsync: this);
  Size _viewport = Size.zero;

  static const overviewScale = .26;
  static const closeScale = 2.0;

  @override
  void dispose() {
    _controller.dispose();
    _pulse.dispose();
    _camera.dispose();
    super.dispose();
  }

  double get _scale => _controller.value.getMaxScaleOnAxis();

  Offset get _center => Offset(
    _viewport.width / 2,
    widget.topInset +
        (_viewport.height - widget.topInset - widget.bottomInset) / 2,
  );

  Matrix4 _matrixFor(Offset mapPoint, double scale) {
    final c = _center;
    return Matrix4.identity()
      ..translateByDouble(
        c.dx - mapPoint.dx * scale,
        c.dy - mapPoint.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  /// Wide Gulshan overview (no animation).
  void showOverview() {
    if (_viewport == Size.zero) return;
    _camera.stop();
    final pts = [
      for (final s in widget.shops) MapProjection.project(s.lat, s.lng),
      MapProjection.project(widget.userLat, widget.userLng),
    ];
    var minX = pts.first.dx, maxX = pts.first.dx;
    var minY = pts.first.dy, maxY = pts.first.dy;
    for (final p in pts) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    _controller.value = _matrixFor(
      Offset((minX + maxX) / 2, (minY + maxY) / 2),
      overviewScale,
    );
  }

  /// Animated camera move to a lat/lng.
  Future<void> flyTo(
    double lat,
    double lng, {
    double scale = closeScale,
    Duration duration = const Duration(milliseconds: 1500),
  }) async {
    if (_viewport == Size.zero) return;
    final from = _controller.value.clone();
    final to = _matrixFor(MapProjection.project(lat, lng), scale);
    final fs = from.getMaxScaleOnAxis();
    final ft = from.getTranslation();
    final tt = to.getTranslation();
    _camera
      ..stop()
      ..duration = duration
      ..reset();
    void tick() {
      final t = Curves.easeInOutCubic.transform(_camera.value);
      final s = fs * math.pow(scale / fs, t).toDouble();
      _controller.value = Matrix4.identity()
        ..translateByDouble(
          ft.x + (tt.x - ft.x) * t,
          ft.y + (tt.y - ft.y) * t,
          0,
          1,
        )
        ..scaleByDouble(s, s, 1, 1);
    }

    _camera.addListener(tick);
    try {
      await _camera.forward().orCancel;
    } on TickerCanceled {
      // Interrupted by another camera move or dispose.
    } finally {
      _camera.removeListener(tick);
    }
  }

  void flyToUser() => flyTo(widget.userLat, widget.userLng);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final first = _viewport == Size.zero;
        _viewport = constraints.biggest;
        if (first) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) showOverview();
          });
        }
        final user = MapProjection.project(widget.userLat, widget.userLng);
        return Semantics(
          label: 'Street map showing your location and assigned shops',
          child: InteractiveViewer(
            transformationController: _controller,
            constrained: false,
            minScale: .2,
            maxScale: 2.6,
            boundaryMargin: const EdgeInsets.all(600),
            child: SizedBox(
              width: MapProjection.width,
              height: MapProjection.height,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final k = 1 / _scale;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned.fill(
                        child: CustomPaint(painter: _StreetPainter()),
                      ),
                      for (final shop in widget.shops)
                        if (shop.id != widget.activeShopId)
                          _pin(shop, k, detected: false),
                      for (final shop in widget.shops)
                        if (shop.id == widget.activeShopId)
                          _pin(shop, k, detected: true),
                      for (final o in widget.officers) _officer(o, k),
                      if (widget.showUser)
                        Positioned(
                          left: user.dx - 40 * k,
                          top: user.dy - 40 * k,
                          child: IgnorePointer(
                            child: _PulsingDot(animation: _pulse, k: k),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _officer(MapOfficer o, double k) {
    final p = MapProjection.project(o.lat, o.lng);
    final d = 30.0 * k;
    return Positioned(
      left: p.dx + 14 * k,
      top: p.dy - d - 6 * k,
      width: d,
      height: d,
      child: IgnorePointer(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.emerald,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5 * k),
          ),
          child: Text(
            o.initials,
            style: TextStyle(
              fontSize: 11 * k,
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
            ),
          ),
        ),
      ),
    );
  }

  Widget _pin(Shop shop, double k, {required bool detected}) {
    final p = MapProjection.project(shop.lat, shop.lng);
    final selected = widget.selectedShopId == shop.id;
    final s = (detected ? 38.0 : 28.0) * k;
    final tip = s * math.sqrt2 / 2;
    final box = s * math.sqrt2 + 8 * k;
    final fill =
        widget.shopColors[shop.id] ??
        (detected ? AppColors.emerald : AppColors.navy);
    final iconColor = fill == AppColors.emerald ? AppColors.navy : Colors.white;
    return Positioned(
      left: p.dx - box / 2,
      top: p.dy - tip - box / 2,
      width: box,
      height: box,
      child: Semantics(
        button: true,
        label: detected
            ? '${shop.name}, detected shop'
            : '${shop.name}, assigned shop',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onShopTap(shop),
          child: Center(
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(s / 2),
                    topRight: Radius.circular(s / 2),
                    bottomRight: Radius.circular(s / 2),
                  ),
                  border: Border.all(
                    color: selected ? AppColors.emeraldDark : Colors.white,
                    width: (detected || selected ? 3 : 2) * k,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x550B1426),
                      blurRadius: 8 * k,
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Icon(
                    Icons.storefront_rounded,
                    size: (detected ? 21 : 15) * k,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatelessWidget {
  const _PulsingDot({required this.animation, required this.k});
  final Animation<double> animation;
  final double k;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80 * k,
      height: 80 * k,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          Widget ring(double t) => Container(
            width: (22 + 52 * t) * k,
            height: (22 + 52 * t) * k,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.emerald.withValues(alpha: .34 * (1 - t)),
            ),
          );
          return Stack(
            alignment: Alignment.center,
            children: [
              ring(animation.value),
              ring((animation.value + .5) % 1),
              Container(
                width: 22 * k,
                height: 22 * k,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald,
                  border: Border.all(color: Colors.white, width: 3.5 * k),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x660B1426),
                      blurRadius: 6 * k,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StreetPainter extends CustomPainter {
  const _StreetPainter();

  static const _land = Color(0xFFF2EFE9);
  static const _block = Color(0xFFE6E1D8);
  static const _building = Color(0xFFD9D3C7);
  static const _park = Color(0xFFCDEBB0);
  static const _water = Color(0xFFAAD3DF);
  static const _casing = Color(0xFFC9C4BA);
  static const _minor = Colors.white;
  static const _major = Color(0xFFFCE9A6);
  static const _majorCasing = Color(0xFFE0B64C);

  static const _verticalMinor = [
    90.0, 230.0, 380.0, 520.0, 660.0, 810.0, 960.0,
  ];
  static const _horizontalMinor = [
    80.0, 210.0, 340.0, 470.0, 610.0, 750.0, 880.0,
  ];

  @override
  void paint(Canvas canvas, Size full) {
    // Designed in a 1100x1000 space, scaled to the full map canvas.
    canvas.scale(full.width / 1100, full.height / 1000);
    const size = Size(1100, 1000);
    canvas.drawRect(Offset.zero & size, Paint()..color = _land);

    final lake = Path()
      ..moveTo(size.width, 120)
      ..cubicTo(1010, 150, 990, 260, 1030, 340)
      ..cubicTo(1060, 400, 1040, 470, size.width, 500)
      ..lineTo(size.width, 120)
      ..close();
    canvas.drawPath(lake, Paint()..color = _water);

    final rng = math.Random(11);
    final xs = [0.0, ..._verticalMinor, size.width];
    final ys = [0.0, ..._horizontalMinor, size.height];
    for (var i = 0; i < xs.length - 1; i++) {
      for (var j = 0; j < ys.length - 1; j++) {
        final r = Rect.fromLTRB(
          xs[i] + 8,
          ys[j] + 8,
          xs[i + 1] - 8,
          ys[j + 1] - 8,
        );
        if (r.width < 20 || r.height < 20) continue;
        final isPark = (i == 3 && j == 3) || (i == 1 && j == 5);
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)),
          Paint()..color = isPark ? _park : _block,
        );
        if (isPark) continue;
        for (var k = 0; k < 7; k++) {
          final bw = 22 + rng.nextDouble() * 34;
          final bh = 18 + rng.nextDouble() * 30;
          final bx =
              r.left + 6 + rng.nextDouble() * math.max(1, r.width - bw - 12);
          final by =
              r.top + 6 + rng.nextDouble() * math.max(1, r.height - bh - 12);
          canvas.drawRect(
            Rect.fromLTWH(bx, by, bw, bh),
            Paint()..color = _building,
          );
        }
      }
    }

    void roads(Paint paint, double w) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round;
      for (final x in _verticalMinor) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (final y in _horizontalMinor) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }

    roads(Paint()..color = _casing, 14);
    roads(Paint()..color = _minor, 11);

    final major = Path()
      ..moveTo(0, 560)
      ..cubicTo(260, 520, 520, 600, 760, 470)
      ..cubicTo(900, 395, 1010, 420, size.width, 410);
    for (final (w, c) in [(24.0, _majorCasing), (19.0, _major)]) {
      canvas.drawPath(
        major,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..color = c,
      );
    }
    final major2 = Path()
      ..moveTo(520, 0)
      ..cubicTo(500, 250, 560, 420, 520, size.height);
    for (final (w, c) in [(22.0, _majorCasing), (17.0, _major)]) {
      canvas.drawPath(
        major2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = c,
      );
    }

    _label(canvas, 'Gulshan Avenue', const Offset(130, 520), -.06);
    _label(canvas, 'Road 126', const Offset(560, 322), 0);
    _label(canvas, 'Road 27', const Offset(110, 735), 0);
    _label(canvas, 'Gulshan', const Offset(250, 400), 0, big: true);
    _label(
      canvas,
      'Gulshan Lake',
      const Offset(940, 300),
      -math.pi / 2.4,
      color: const Color(0xFF4A89A0),
    );
    _label(
      canvas,
      'Gulshan Park',
      const Offset(535, 500),
      0,
      color: const Color(0xFF5C8A3A),
    );
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at,
    double angle, {
    bool big = false,
    Color color = const Color(0xFF6B6558),
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: big ? 20 : 12,
          fontWeight: big ? FontWeight.w600 : FontWeight.w500,
          color: color,
          letterSpacing: big ? 1.2 : .2,
          shadows: const [
            Shadow(color: Colors.white, blurRadius: 3),
            Shadow(color: Colors.white, blurRadius: 3),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
