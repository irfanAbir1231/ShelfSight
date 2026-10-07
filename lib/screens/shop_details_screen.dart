import 'package:flutter/material.dart';

import '../models/session.dart';
import '../theme/app_theme.dart';
import '../widgets/shell_widgets.dart';
import 'app_shell.dart';

class ShopDetailsScreen extends StatelessWidget {
  const ShopDetailsScreen({super.key, required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return RoleNavScaffold(
      activeTab: 0,
      body: FixedHeaderScrollView(
        title: 'Shop details',
        subtitle: shop.name,
        onBack: () => Navigator.of(context).pop(),
        slivers: [
          pagePadding([
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(shop.address),
                  const SizedBox(height: 14),
                  _Row(Icons.history_rounded, 'Last visit', shop.lastVisit),
                  _Row(
                    Icons.pie_chart_outline_rounded,
                    'Previous Square soap share',
                    shop.squareShare == null ? 'None yet' : '${shop.squareShare}%',
                  ),
                  _Row(Icons.flag_outlined, 'Target share', '50%'),
                  _Row(
                    Icons.radar_rounded,
                    'Visit area',
                    '${DemoData.geofenceMeters.round()} m around the shop',
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

class _Row extends StatelessWidget {
  const _Row(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.inkMuted),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    ),
  );
}
