import 'package:flutter/material.dart';

import '../models/session.dart';
import '../models/territory_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/shell_widgets.dart';
import '../widgets/street_map.dart';
import 'app_shell.dart';

/// Territory map: shop markers colored by Square share status, plus officers
/// currently on a visit. Map/List toggle and a shop summary sheet.
class TerritoryMapScreen extends StatefulWidget {
  const TerritoryMapScreen({super.key});

  @override
  State<TerritoryMapScreen> createState() => _TerritoryMapScreenState();
}

class _TerritoryMapScreenState extends State<TerritoryMapScreen> {
  bool _list = false;
  Shop? _selected;

  @override
  Widget build(BuildContext context) {
    final top = ShelfSightHeader.totalHeight(context);
    final navH = FloatingGlassNav.totalHeight(context);
    final colors = {
      for (final s in DemoData.shops)
        s.id: statusForShare(territoryShopShares[s.id] ?? 0).color,
    };
    final mapOfficers = [
      for (final v in activeOfficerVisits)
        MapOfficer(
          v.officer.split(' ').map((p) => p[0]).join(),
          DemoData.byId(v.shopId)!.lat,
          DemoData.byId(v.shopId)!.lng,
        ),
    ];
    return RoleNavScaffold(
      activeTab: 0,
      body: Stack(
        children: [
          Positioned.fill(
            child: _list
                ? _ShopList(
                    top: top + 64,
                    bottom: navH + 12,
                    onOpen: (s) => setState(() {
                      _list = false;
                      _selected = s;
                    }),
                  )
                : StreetMap(
                    shops: DemoData.shops,
                    userLat: DemoData.samson.lat,
                    userLng: DemoData.samson.lng,
                    showUser: false,
                    shopColors: colors,
                    officers: mapOfficers,
                    selectedShopId: _selected?.id,
                    topInset: top + 56,
                    bottomInset: _selected == null ? navH : 280,
                    onShopTap: (s) => setState(() => _selected = s),
                  ),
          ),
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
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(
                      child: _Seg(
                        label: 'Map',
                        icon: Icons.map_outlined,
                        selected: !_list,
                        onTap: () => setState(() => _list = false),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _Seg(
                        label: 'List',
                        icon: Icons.view_list_rounded,
                        selected: _list,
                        onTap: () => setState(() => _list = true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!_list) ...[
            Positioned(
              left: 12,
              top: top + 70,
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
              top: top + 70,
              child: const _Legend(),
            ),
            if (_selected != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: navH + 4,
                child: _ShopSheet(
                  shop: _selected!,
                  onClose: () => setState(() => _selected = null),
                ),
              ),
          ],
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ShelfSightHeader(
              title: 'Territory map',
              subtitle: 'Gulshan · Square share status',
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : AppColors.ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in ShareStatus.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.icon, size: 14, color: s.color),
                  const SizedBox(width: 6),
                  Text(
                    s.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_pin_circle_rounded, size: 14, color: AppColors.emeraldDark),
                SizedBox(width: 6),
                Text(
                  'Officer on visit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ShopSheet extends StatelessWidget {
  const _ShopSheet({required this.shop, required this.onClose});
  final Shop shop;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final share = territoryShopShares[shop.id] ?? 0;
    final st = statusForShare(share);
    final visit = activeOfficerVisits
        .where((v) => v.shopId == shop.id)
        .firstOrNull;
    return GlassSurface(
      borderRadius: BorderRadius.circular(22),
      color: Colors.white.withValues(alpha: .9),
      borderColor: Colors.white,
      blur: 24,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    shop.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(shop.address, style: const TextStyle(fontSize: 13.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                StatusPill(
                  label: 'Square $share% · ${st.label}',
                  icon: st.icon,
                  color: st.textColor,
                  background: st.softColor,
                ),
                if (visit != null)
                  StatusPill(
                    label: '${visit.officer} since ${visit.since}',
                    icon: Icons.person_pin_circle_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Last visit: ${shop.lastVisit}'),
          ],
        ),
      ),
    );
  }
}

class _ShopList extends StatelessWidget {
  const _ShopList({
    required this.top,
    required this.bottom,
    required this.onOpen,
  });
  final double top;
  final double bottom;
  final ValueChanged<Shop> onOpen;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.canvas,
    child: ListView(
      padding: EdgeInsets.fromLTRB(16, top, 16, bottom),
      children: [
        for (final s in DemoData.shops)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SurfaceCard(
              onTap: () => onOpen(s),
              child: Row(
                children: [
                  Icon(
                    statusForShare(territoryShopShares[s.id] ?? 0).icon,
                    color: statusForShare(territoryShopShares[s.id] ?? 0).color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          statusForShare(territoryShopShares[s.id] ?? 0).label,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${territoryShopShares[s.id]}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
