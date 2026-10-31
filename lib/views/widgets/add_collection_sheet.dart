import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/badminton_controller.dart';
import '../../utils/app_theme.dart';

class AddCollectionSheet extends StatefulWidget {
  const AddCollectionSheet({super.key});

  @override
  State<AddCollectionSheet> createState() => _AddCollectionSheetState();
}

class _AddCollectionSheetState extends State<AddCollectionSheet> {
  final BadmintonController controller = Get.find<BadmintonController>();
  final TextEditingController _amountController = TextEditingController(text: '500');
  final TextEditingController _titleController =
      TextEditingController(text: 'New Shuttles Purchase');
  final TextEditingController _notesController = TextEditingController();

  String _shuttleBrand = 'Yonex Mavis 350';
  late Set<String> _selectedMemberIds;

  final List<String> _popularShuttles = [
    'Yonex Mavis 350 (Nylon)',
    'Yonex AS-30 (Feather)',
    'Yonex AS-2 (Feather)',
    'Li-Ning Champ',
    'Victor Champion',
    'Other / Custom',
  ];

  final List<double> _presetAmounts = [200, 300, 500, 750, 1000];

  @override
  void initState() {
    super.initState();
    _selectedMemberIds = controller.members
        .where((m) => m.isActive)
        .map((m) => m.id)
        .toSet();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Please enter a valid collection amount per player.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      Get.snackbar(
        'Title Required',
        'Please give a name to this collection entry (e.g. New Shuttles).',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      Get.snackbar(
        'Select Members',
        'Please select at least one player for this collection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    controller.addNewCollection(
      title: _titleController.text.trim(),
      amountPerMember: amount,
      targetMemberIds: _selectedMemberIds.toList(),
      notes: _notesController.text.trim(),
      shuttleBrand: _shuttleBrand,
    );

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final curr = controller.currencySymbol.value;
    final double currentAmount = double.tryParse(_amountController.text) ?? 0.0;
    final double totalEstimated = currentAmount * _selectedMemberIds.length;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_tennis,
                    color: AppTheme.primaryGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Shuttle Collection',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'This will add the amount to players\' remaining dues',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount Input
            Text(
              'Amount per Player ($curr)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    curr,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '500',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),

            // Preset Amount Chips
            Wrap(
              spacing: 8,
              children: _presetAmounts.map((amt) {
                final isSelected =
                    double.tryParse(_amountController.text) == amt;
                return ChoiceChip(
                  label: Text('$curr${amt.toStringAsFixed(0)}'),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryGreen : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _amountController.text = amt.toStringAsFixed(0);
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Collection Title / Reason
            const Text(
              'Collection Title / Reason',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. New Shuttles Yonex Mavis 350',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Shuttle Type / Brand
            const Text(
              'Shuttlecock Brand / Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _popularShuttles.contains(_shuttleBrand)
                  ? _shuttleBrand
                  : _popularShuttles.first,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.sports_baseball_outlined),
              ),
              items: _popularShuttles.map((brand) {
                return DropdownMenuItem(
                  value: brand,
                  child: Text(brand),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _shuttleBrand = val);
                }
              },
            ),
            const SizedBox(height: 16),

            // Member Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Players Included (${_selectedMemberIds.length}/${controller.members.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedMemberIds.length ==
                          controller.members.length) {
                        _selectedMemberIds.clear();
                      } else {
                        _selectedMemberIds =
                            controller.members.map((m) => m.id).toSet();
                      }
                    });
                  },
                  child: Text(
                    _selectedMemberIds.length == controller.members.length
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: controller.members.length,
                separatorBuilder: (context, sepIndex) => Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, idx) {
                  final m = controller.members[idx];
                  final isChecked = _selectedMemberIds.contains(m.id);
                  return CheckboxListTile(
                    dense: true,
                    title: Text(
                      m.name,
                      style: TextStyle(
                        fontWeight:
                            isChecked ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    value: isChecked,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedMemberIds.add(m.id);
                        } else {
                          _selectedMemberIds.remove(m.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Calculation Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Adding $curr${currentAmount.toStringAsFixed(0)} to ${_selectedMemberIds.length} players will increase group dues by $curr${totalEstimated.toStringAsFixed(0)}.',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add_circle_outline, size: 22),
                label: Text(
                  'Add Collection (+$curr${currentAmount.toStringAsFixed(0)} to All)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
