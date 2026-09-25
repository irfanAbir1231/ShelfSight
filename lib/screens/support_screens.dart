import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _unreadOnly = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Mark all read')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: !_unreadOnly,
                showCheckmark: false,
                onSelected: (_) => setState(() => _unreadOnly = false),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Unread 3'),
                selected: _unreadOnly,
                showCheckmark: false,
                onSelected: (_) => setState(() => _unreadOnly = true),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _NoticeCard(
            icon: Icons.rate_review_outlined,
            title: 'Audit needs review',
            body: '7 uncertain products in Meena Bazar need classification.',
            time: '8 min ago',
            color: AppColors.amber,
            unread: true,
          ),
          const SizedBox(height: 10),
          const _NoticeCard(
            icon: Icons.cloud_done_outlined,
            title: 'Audit synced',
            body: 'Shwapno Super Shop was uploaded successfully.',
            time: '34 min ago',
            color: AppColors.emerald,
            unread: true,
          ),
          const SizedBox(height: 10),
          const _NoticeCard(
            icon: Icons.trending_up_rounded,
            title: 'Share improved',
            body: 'Gulshan route gained 5.8% Square-facing share this week.',
            time: '2 hours ago',
            color: Color(0xFF38BDF8),
            unread: true,
          ),
          if (!_unreadOnly) ...[
            const SizedBox(height: 10),
            const _NoticeCard(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Daily target complete',
              body: 'All 6 scheduled stores were visited yesterday.',
              time: 'Yesterday',
              color: AppColors.inkMuted,
            ),
          ],
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.color,
    this.unread = false,
  });
  final IconData icon;
  final String title;
  final String body;
  final String time;
  final Color color;
  final bool unread;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (unread)
                      const Icon(
                        Icons.circle,
                        size: 9,
                        color: AppColors.emerald,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.inkMuted,
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

class SyncCenterScreen extends StatefulWidget {
  const SyncCenterScreen({super.key});
  @override
  State<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends State<SyncCenterScreen> {
  bool _retrying = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sync center')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.wifi_rounded, color: AppColors.emeraldDark, size: 28),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Online and ready',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                    Text(
                      'Last successful sync • just now',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(
              child: _SyncStat(value: '0', label: 'Pending'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _SyncStat(value: '1', label: 'Needs retry', warning: true),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _SyncStat(value: '24', label: 'Synced'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionTitle(title: 'Upload queue'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(
                  width: 62,
                  height: 62,
                  child: ShelfArtwork(radius: 14),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prince Bazar',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '3 photos • 18.4 MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      SizedBox(height: 7),
                      StatusPill(
                        label: 'UPLOAD FAILED',
                        color: Color(0xFFB45309),
                        background: Color(0xFFFEF3C7),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => setState(() => _retrying = !_retrying),
                  icon: _retrying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: _retrying ? 'Retrying upload...' : 'Retry failed uploads',
          icon: Icons.sync_rounded,
          onPressed: _retrying ? null : () => setState(() => _retrying = true),
        ),
      ],
    ),
  );
}

class _SyncStat extends StatelessWidget {
  const _SyncStat({
    required this.value,
    required this.label,
    this.warning = false,
  });
  final String value;
  final String label;
  final bool warning;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: warning ? const Color(0xFFB45309) : AppColors.navy,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.inkMuted),
          ),
        ],
      ),
    ),
  );
}

class ReportFiltersScreen extends StatefulWidget {
  const ReportFiltersScreen({super.key});
  @override
  State<ReportFiltersScreen> createState() => _ReportFiltersScreenState();
}

class _ReportFiltersScreenState extends State<ReportFiltersScreen> {
  String _period = 'Last 30 days';
  String _area = 'All areas';
  final Set<String> _categories = {'All categories'};
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Report filters'),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            _period = 'Last 30 days';
            _area = 'All areas';
            _categories
              ..clear()
              ..add('All categories');
          }),
          child: const Text('Reset'),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                const Text(
                  'DATE RANGE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkMuted,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 10),
                ...['Last 7 days', 'Last 30 days', 'This quarter'].map(
                  (item) => ListTile(
                    onTap: () => setState(() => _period = item),
                    leading: Icon(
                      _period == item
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: _period == item
                          ? AppColors.emeraldDark
                          : AppColors.inkMuted,
                    ),
                    title: Text(
                      item,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _area,
                  decoration: const InputDecoration(
                    labelText: 'Area',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items:
                      ['All areas', 'Gulshan & Banani', 'Dhanmondi', 'Mirpur']
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _area = value!),
                ),
                const SizedBox(height: 22),
                const Text(
                  'CATEGORIES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkMuted,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                            'All categories',
                            'Food & Beverage',
                            'Personal Care',
                            'Household',
                          ]
                          .map(
                            (item) => FilterChip(
                              label: Text(item),
                              selected: _categories.contains(item),
                              onSelected: (selected) => setState(() {
                                if (item == 'All categories') {
                                  _categories
                                    ..clear()
                                    ..add(item);
                                } else {
                                  _categories.remove('All categories');
                                  selected
                                      ? _categories.add(item)
                                      : _categories.remove(item);
                                }
                              }),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Export report as PDF'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: PrimaryButton(
              label: 'Apply filters',
              icon: Icons.check_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    ),
  );
}

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});
  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final Map<String, bool> _permissions = {
    'Camera': true,
    'Location': true,
    'Photos & media': false,
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('App permissions')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const Text(
          'ShelfSight uses these permissions only while capturing and saving store audits.',
          style: TextStyle(color: AppColors.inkMuted, height: 1.45),
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: _permissions.entries
                .map(
                  (entry) => SwitchListTile.adaptive(
                    value: entry.value,
                    onChanged: (value) =>
                        setState(() => _permissions[entry.key] = value),
                    secondary: Icon(
                      entry.key == 'Camera'
                          ? Icons.camera_alt_outlined
                          : entry.key == 'Location'
                          ? Icons.location_on_outlined
                          : Icons.photo_library_outlined,
                    ),
                    title: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(entry.value ? 'Allowed' : 'Not allowed'),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 18),
        const StatusPill(
          label:
              'Changes shown here are UI-only until native permission handling is connected',
          icon: Icons.info_outline_rounded,
          color: AppColors.inkMuted,
          background: AppColors.surfaceAlt,
        ),
      ],
    ),
  );
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help & support')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Search help topics',
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle(title: 'Common questions'),
        const SizedBox(height: 10),
        const Card(
          child: Column(
            children: [
              ExpansionTile(
                title: Text(
                  'How should I capture a shelf?',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'Stand straight in front of the shelf, avoid glare, and capture one section at a time.',
                      style: TextStyle(color: AppColors.inkMuted),
                    ),
                  ),
                ],
              ),
              Divider(height: 1),
              ExpansionTile(
                title: Text(
                  'Why is a product uncertain?',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'The logo may be hidden, blurred, or too small. Review the item and classify it manually.',
                      style: TextStyle(color: AppColors.inkMuted),
                    ),
                  ),
                ],
              ),
              Divider(height: 1),
              ExpansionTile(
                title: Text(
                  'Can I work without internet?',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'Drafts can be saved locally and uploaded later from Sync Center.',
                      style: TextStyle(color: AppColors.inkMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Contact support',
          icon: Icons.chat_bubble_outline_rounded,
          onPressed: () {},
        ),
      ],
    ),
  );
}

class ShelfViewerScreen extends StatelessWidget {
  const ShelfViewerScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050B14),
    appBar: AppBar(
      backgroundColor: const Color(0xFF050B14),
      foregroundColor: Colors.white,
      title: const Text('Shelf photo', style: TextStyle(color: Colors.white)),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.download_outlined)),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: .8,
              maxScale: 5,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: ShelfArtwork(radius: 20),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: _ViewerMetric(value: '126', label: 'Facings'),
                ),
                Expanded(
                  child: _ViewerMetric(value: '54', label: 'Square'),
                ),
                Expanded(
                  child: _ViewerMetric(value: '7', label: 'Uncertain'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ViewerMetric extends StatelessWidget {
  const _ViewerMetric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    ],
  );
}
