import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/badminton_controller.dart';
import '../../utils/app_theme.dart';

class AddShuttlePurchaseSheet extends StatefulWidget {
  const AddShuttlePurchaseSheet({super.key});

  @override
  State<AddShuttlePurchaseSheet> createState() =>
      _AddShuttlePurchaseSheetState();
}

class _AddShuttlePurchaseSheetState extends State<AddShuttlePurchaseSheet> {
  final BadmintonController controller = Get.find<BadmintonController>();
  final TextEditingController _titleController =
      TextEditingController(text: 'Yonex Mavis 350');
  final TextEditingController _costController =
      TextEditingController(text: '700');
  final TextEditingController _notesController = TextEditingController();
  int _quantity = 2;

  final List<String> _commonShuttles = [
    'Yonex Mavis 350 (Nylon)',
    'Yonex AS-30 (Feather)',
    'Yonex AS-2 (Feather)',
    'Li-Ning Champ',
    'Other Shuttles',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final cost = double.tryParse(_costController.text.trim());
    if (cost == null || cost <= 0) {
      Get.snackbar(
        'Invalid Price',
        'Please enter how much money you paid for the shuttles.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    controller.recordShuttlePurchase(
      title: _titleController.text.trim(),
      quantity: _quantity,
      totalCost: cost,
      notes: _notesController.text.trim(),
    );

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final curr = controller.currencySymbol.value;
    final totalCollected = controller.totalGroupCollected;
    final enteredCost = double.tryParse(_costController.text) ?? 0.0;
    final remainingAfter = controller.kittyBalanceRemaining - enteredCost;

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
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buy Shuttles (Add Stock)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Deducts cost from collected money & adds stock',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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

            // Shuttle Name / Brand
            const Text(
              'Shuttlecock Brand / Name',
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
                hintText: 'e.g. Yonex Mavis 350',
                prefixIcon: Icon(Icons.sports_tennis),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _commonShuttles.map((shuttle) {
                return ActionChip(
                  label: Text(shuttle.split(' (').first),
                  onPressed: () =>
                      setState(() => _titleController.text = shuttle),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Quantity (How many shuttles bought)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Number of Shuttles Bought',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Cost Paid
            Text(
              'Total Price Paid ($curr)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _costController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    curr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '700',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),

            // Live Money Deduction Breakdown Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Money Collected:'),
                      Text(
                        '$curr${totalCollected.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Spent on this Purchase:'),
                      Text(
                        '-$curr${enteredCost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cash Remaining in Kitty:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$curr${remainingAfter.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: remainingAfter >= 0
                              ? AppTheme.successGreen
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Optional Note
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Note (e.g. Bought from sports shop)',
                prefixIcon: Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check, size: 20),
                label: Text(
                  'Record Purchase (-$curr${enteredCost.toStringAsFixed(0)})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

