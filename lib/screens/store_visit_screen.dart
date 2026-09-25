import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'capture_screen.dart';

class StoreVisitScreen extends StatefulWidget {
  const StoreVisitScreen({super.key});
  @override
  State<StoreVisitScreen> createState() => _StoreVisitScreenState();
}

class _StoreVisitScreenState extends State<StoreVisitScreen> {
  final _storeController = TextEditingController(text: 'Shwapno Super Shop');
  String _visitType = 'Scheduled visit';
  final Set<String> _categories = {'Food & Beverage'};

  @override
  void dispose() {
    _storeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New store visit'),
            SizedBox(height: 2),
            Text(
              'Step 1 of 3  •  Store details',
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  const _StepBar(active: 0),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: AppColors.emeraldDark,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Location verified',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emeraldDark,
                                ),
                              ),
                            ),
                            StatusPill(label: '± 8 m'),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Road 11, Block D, Banani, Dhaka',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.emeraldDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select store',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _storeController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search_rounded),
                              hintText: 'Search assigned store',
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'NEARBY STORES',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.inkMuted,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('Shwapno Banani'),
                                  selected: true,
                                  onSelected: (_) => _storeController.text =
                                      'Shwapno Super Shop',
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Meena Bazar'),
                                  selected: false,
                                  onSelected: (_) =>
                                      _storeController.text = 'Meena Bazar',
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Agora'),
                                  selected: false,
                                  onSelected: (_) => _storeController.text =
                                      'Agora Superstore',
                                ),
                              ],
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
                        children: [
                          const _ReadOnlyInfo(
                            icon: Icons.tag_rounded,
                            label: 'Outlet ID',
                            value: 'OUT-98214',
                          ),
                          const Divider(height: 28),
                          const _ReadOnlyInfo(
                            icon: Icons.storefront_outlined,
                            label: 'Outlet type',
                            value: 'Supermarket / Modern trade',
                          ),
                          const Divider(height: 28),
                          DropdownButtonFormField<String>(
                            initialValue: _visitType,
                            decoration: const InputDecoration(
                              labelText: 'Visit type',
                              prefixIcon: Icon(Icons.event_available_outlined),
                            ),
                            items:
                                const [
                                      'Scheduled visit',
                                      'Follow-up visit',
                                      'Unplanned visit',
                                    ]
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) =>
                                setState(() => _visitType = value!),
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
                          const Text(
                            'Audit category',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Select the shelf sections you plan to capture.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                [
                                  'Food & Beverage',
                                  'Personal Care',
                                  'Household Care',
                                  'Pharmacy',
                                ].map((item) {
                                  final selected = _categories.contains(item);
                                  return FilterChip(
                                    label: Text(item),
                                    selected: selected,
                                    onSelected: (value) => setState(
                                      () => value
                                          ? _categories.add(item)
                                          : _categories.remove(item),
                                    ),
                                    selectedColor: AppColors.navy,
                                    checkmarkColor: Colors.white,
                                    labelStyle: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AppColors.navy,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Visit note (optional)',
                      hintText: 'Add shelf, promotion, or competitor notes...',
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
                label: 'Continue to shelf capture',
                onPressed: _categories.isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CaptureScreen(storeName: _storeController.text),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.active});
  final int active;
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(3, (index) {
      final labels = ['Store', 'Capture', 'Review'];
      final selected = index == active;
      return Expanded(
        child: Container(
          margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${index + 1}  ${labels[index]}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.inkMuted,
            ),
          ),
        ),
      );
    }),
  );
}

class _ReadOnlyInfo extends StatelessWidget {
  const _ReadOnlyInfo({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppColors.inkMuted),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    ],
  );
}
