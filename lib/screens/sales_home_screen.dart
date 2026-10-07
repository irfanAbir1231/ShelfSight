import 'dart:async';

import 'package:flutter/material.dart';

import '../models/session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';
import '../widgets/street_map.dart';
import 'shop_details_screen.dart';
import 'visit_screens.dart';

enum _Phase { overview, locating, found }

/// Sales Officer home: map overview, camera fly-to, shop detection sheet,
/// geofence states and an assigned-shops list.
class SalesHomeScreen extends StatefulWidget {
  const SalesHomeScreen({super.key, required this.session});
  final UserSession session;

  @override
  State<SalesHomeScreen> createState() => _SalesHomeScreenState();
}

class _SalesHomeScreenState extends State<SalesHomeScreen> {
  final _mapKey = GlobalKey<StreetMapState>();
  final _sheet = DraggableScrollableController();
  final _search = TextEditingController();

  _Phase _phase = _Phase.overview;
  DemoLocation _loc = DemoLocation.insideShop;
  bool _listMode = false;
  bool _dismissed = false;
  String _query = '';
  Timer? _timer;

  double get _lat => DemoData.locationFor(_loc).$1;
  double get _lng => DemoData.locationFor(_loc).$2;

  /// Nearest assigned shop to the current GPS fix.
  Shop get _target {
    final sorted = [...DemoData.shops]
      ..sort(
        (a, b) => DemoData.distanceTo(a, _lat, _lng).compareTo(
          DemoData.distanceTo(b, _lat, _lng),
        ),
      );
    return sorted.first;
  }

  bool get _inside => DemoData.insideGeofence(_target, _lat, _lng);

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1100), _locate);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sheet.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    if (!mounted) return;
    setState(() => _phase = _Phase.locating);
    await _mapKey.currentState?.flyTo(_lat, _lng);
    if (mounted) setState(() => _phase = _Phase.found);
  }

  Future<void> _setLocation(DemoLocation loc) async {
    if (loc == _loc) return;
    setState(() {
      _loc = loc;
      _dismissed = false;
    });
    await _mapKey.currentState?.flyTo(
      _lat,
      _lng,
      scale: 1.6,
      duration: const Duration(milliseconds: 900),
    );
  }

  void _expandSheet() => _sheet.animateTo(
    .68,
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOut,
  );

  void _startVisit() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VisitOverviewScreen(shop: _target)),
    );
  }

  void _details(Shop s) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ShopDetailsScreen(shop: s)),
  );

  void _notMyShop() {
    setState(() {
      _dismissed = true;
      _listMode = true;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Pick your shop from the assigned list.')),
      );
  }

  void _directions() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Directions need a maps app, not connected in demo.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Set<String>>(
    valueListenable: visitedToday,
    builder: (context, done, _) => _buildBody(context, done.length),
  );

  Widget _buildBody(BuildContext context, int visited) {
    final top = ShelfSightHeader.totalHeight(context);
    final navH = FloatingGlassNav.totalHeight(context);
    final screenH = MediaQuery.sizeOf(context).height;
    final showSheet = _phase == _Phase.found && !_listMode && !_dismissed;
    return Stack(
      children: [
        Positioned.fill(
          child: StreetMap(
            key: _mapKey,
            shops: DemoData.shops,
            userLat: _lat,
            userLng: _lng,
            activeShopId: _phase == _Phase.found && _inside && !_dismissed
                ? _target.id
                : null,
            selectedShopId: _phase == _Phase.found && !_dismissed
                ? _target.id
                : null,
            topInset: top + 56,
            bottomInset: showSheet ? screenH * .36 : navH,
            onShopTap: _details,
          ),
        ),
        if (_listMode)
          Positioned.fill(
            child: _ShopList(
              top: top + 64,
              bottom: navH + 12,
              query: _query,
              controller: _search,
              onQuery: (v) => setState(() => _query = v),
              lat: _lat,
              lng: _lng,
              onOpen: _details,
            ),
          ),
        // Today progress + Map/List toggle.
        Positioned(
          left: 12,
          right: 12,
          top: top + 8,
          child: GlassSurface(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: .8),
            borderColor: Colors.white,
            blur: 16,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today · $visited of ${DemoData.shops.length} shops visited',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: visited / DemoData.shops.length,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            color: AppColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ModeToggle(
                    list: _listMode,
                    onChanged: (v) => setState(() => _listMode = v),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!_listMode) ...[
          Positioned(
            left: 12,
            top: top + 76,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10.5, color: AppColors.slate),
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: top + 76,
            child: Material(
              color: Colors.white,
              elevation: 3,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Recenter on my location',
                style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
                onPressed: () => _mapKey.currentState?.flyToUser(),
                icon: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
          if (_phase == _Phase.locating)
            Positioned(
              left: 0,
              right: 0,
              bottom: navH + 16,
              child: const Center(
                child: StatusPill(
                  label: 'Finding your location…',
                  icon: Icons.gps_fixed_rounded,
                  color: AppColors.ink,
                  background: Colors.white,
                ),
              ),
            ),
        ],
        if (showSheet)
          DraggableScrollableSheet(
            controller: _sheet,
            initialChildSize: .30,
            minChildSize: .30,
            maxChildSize: .68,
            snap: true,
            snapSizes: const [.30, .68],
            builder: (context, scroll) => _DetectionSheet(
              scroll: scroll,
              shop: _target,
              meters: DemoData.distanceTo(_target, _lat, _lng),
              inside: _inside,
              loc: _loc,
              navHeight: navH,
              onExpand: _expandSheet,
              onStart: _startVisit,
              onDetails: () => _details(_target),
              onNotMine: _notMyShop,
              onDirections: _directions,
              onLocation: _setLocation,
            ),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ShelfSightHeader(
            title: 'Good morning, ${widget.session.firstName}',
            subtitle: '${DemoData.shops.length} assigned shops',
            unreadDot: true,
          ),
        ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.list, required this.onChanged});
  final bool list;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, IconData icon, bool selected, bool toList) =>
        Semantics(
          button: true,
          selected: selected,
          label: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(toList),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.navy : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? Colors.white : AppColors.ink,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            seg('Map', Icons.map_outlined, !list, false),
            seg('List', Icons.view_list_rounded, list, true),
          ],
        ),
      ),
    );
  }
}

class _DetectionSheet extends StatelessWidget {
  const _DetectionSheet({
    required this.scroll,
    required this.shop,
    required this.meters,
    required this.inside,
    required this.loc,
    required this.navHeight,
    required this.onExpand,
    required this.onStart,
    required this.onDetails,
    required this.onNotMine,
    required this.onDirections,
    required this.onLocation,
  });

  final ScrollController scroll;
  final Shop shop;
  final double meters;
  final bool inside;
  final DemoLocation loc;
  final double navHeight;
  final VoidCallback onExpand;
  final VoidCallback onStart;
  final VoidCallback onDetails;
  final VoidCallback onNotMine;
  final VoidCallback onDirections;
  final ValueChanged<DemoLocation> onLocation;

  @override
  Widget build(BuildContext context) {
    final distance = formatDistance(meters);
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x330B1426),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: GlassSurface(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        color: Colors.white.withValues(alpha: .86),
        borderColor: Colors.white,
        blur: 26,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(18, 10, 18, navHeight + 16),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: onExpand,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: inside ? AppColors.emerald : AppColors.amberSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      inside
                          ? Icons.my_location_rounded
                          : Icons.near_me_outlined,
                      color: inside ? AppColors.navy : AppColors.amberText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inside
                              ? 'We found your current shop'
                              : 'Nearest assigned shop',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        Text(
                          shop.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.3,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$distance away',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: inside
                          ? AppColors.emeraldDark
                          : AppColors.amberText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              shop.address,
              style: const TextStyle(fontSize: 14.5, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (inside)
                  const StatusPill(
                    label: 'Inside shop area',
                    icon: Icons.check_circle_rounded,
                  )
                else
                  const StatusPill(
                    label: 'You are outside the shop area',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.amberText,
                    background: AppColors.amberSoft,
                  ),
                StatusPill(
                  label: distance,
                  icon: Icons.straighten_rounded,
                  color: AppColors.ink,
                  background: AppColors.surfaceAlt,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Last visit: ${shop.lastVisit}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Start shop visit',
              icon: Icons.play_arrow_rounded,
              onPressed: inside ? onStart : null,
            ),
            if (!inside) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.amberText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Move within ${DemoData.geofenceMeters.round()} meters of the shop to begin',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.amberText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: inside ? onDetails : onDirections,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy, width: 1.5),
                  shape: const StadiumBorder(),
                ),
                icon: Icon(
                  inside ? Icons.storefront_outlined : Icons.directions_rounded,
                ),
                label: Text(
                  inside ? 'View shop details' : 'Get directions',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: onNotMine,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: AppColors.inkMuted,
                ),
                child: const Text(
                  'This is not my shop',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            _DemoLocationOption(loc: loc, onChanged: onLocation),
          ],
        ),
      ),
    );
  }
}

/// Subtle testing-only control for simulating GPS.
class _DemoLocationOption extends StatelessWidget {
  const _DemoLocationOption({required this.loc, required this.onChanged});
  final DemoLocation loc;
  final ValueChanged<DemoLocation> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, size: 16, color: AppColors.inkMuted),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Demo location · testing only',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          SegmentedButton<DemoLocation>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(48, 40),
              textStyle: const TextStyle(fontSize: 12.5),
              selectedBackgroundColor: AppColors.navy,
              selectedForegroundColor: Colors.white,
            ),
            segments: const [
              ButtonSegment(
                value: DemoLocation.insideShop,
                label: Text('At shop'),
              ),
              ButtonSegment(
                value: DemoLocation.outsideShop,
                label: Text('Away'),
              ),
            ],
            selected: {loc},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ],
      ),
    );
  }
}

class _ShopList extends StatelessWidget {
  const _ShopList({
    required this.top,
    required this.bottom,
    required this.query,
    required this.controller,
    required this.onQuery,
    required this.lat,
    required this.lng,
    required this.onOpen,
  });
  final double top;
  final double bottom;
  final String query;
  final TextEditingController controller;
  final ValueChanged<String> onQuery;
  final double lat;
  final double lng;
  final ValueChanged<Shop> onOpen;

  @override
  Widget build(BuildContext context) {
    final shops =
        DemoData.shops
            .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
            .toList()
          ..sort(
            (a, b) => DemoData.distanceTo(a, lat, lng).compareTo(
              DemoData.distanceTo(b, lat, lng),
            ),
          );
    return ColoredBox(
      color: AppColors.canvas,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, top, 16, bottom),
        children: [
          TextField(
            controller: controller,
            onChanged: onQuery,
            decoration: const InputDecoration(
              hintText: 'Search assigned shops',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          if (shops.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('No shops match your search.')),
            ),
          for (final s in shops)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ShopCard(
                shop: s,
                meters: DemoData.distanceTo(s, lat, lng),
                onTap: () => onOpen(s),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.shop,
    required this.meters,
    required this.onTap,
  });
  final Shop shop;
  final double meters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final here = meters <= DemoData.geofenceMeters;
    final done = visitedToday.value.contains(shop.id);
    final String status;
    final IconData icon;
    if (done) {
      status = 'Visited today';
      icon = Icons.check_circle_rounded;
    } else if (here) {
      status = 'Ready to visit';
      icon = Icons.play_circle_outline_rounded;
    } else {
      status = '${formatDistance(meters)} away';
      icon = Icons.near_me_outlined;
    }
    return SurfaceCard(
      onTap: onTap,
      borderColor: here ? AppColors.emeraldDark : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shop.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (here)
                const StatusPill(
                  label: 'You are here',
                  icon: Icons.my_location_rounded,
                  color: AppColors.navy,
                  background: AppColors.emerald,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            shop.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusPill(
                label: status,
                icon: icon,
                color: here || done ? AppColors.emeraldDark : AppColors.ink,
                background: here || done ? AppColors.mint : AppColors.surfaceAlt,
              ),
              StatusPill(
                label: done ? 'Soap audited' : 'Soap pending',
                icon: Icons.clean_hands_rounded,
                color: AppColors.ink,
                background: AppColors.surfaceAlt,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
