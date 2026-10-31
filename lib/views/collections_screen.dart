import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/badminton_controller.dart';
import '../models/collection_event.dart';
import '../models/shuttle_purchase.dart';
import '../utils/app_theme.dart';
import 'widgets/add_collection_sheet.dart';
import 'widgets/add_shuttle_purchase_sheet.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  int _selectedTabIndex = 0; // 0: Shuttle Purchases & Stock, 1: Money Collections

  @override
  Widget build(BuildContext context) {
    final BadmintonController controller = Get.find<BadmintonController>();
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shuttles & Kitty Fund'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined,
                color: AppTheme.primaryGreen),
            tooltip: 'Buy Shuttles',
            onPressed: () {
              Get.bottomSheet(
                const AddShuttlePurchaseSheet(),
                isScrollControlled: true,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen),
            tooltip: 'Add Collection',
            onPressed: () {
              Get.bottomSheet(
                const AddCollectionSheet(),
                isScrollControlled: true,
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        final curr = controller.currencySymbol.value;
        final totalCollected = controller.totalGroupCollected;
        final totalSpent = controller.totalSpentOnShuttles;
        final remainingKitty = controller.kittyBalanceRemaining;
        final currentStock = controller.currentShuttleStock;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top Balance & Stock Overview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen,
                    const Color(0xFF064E2B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'KITTY CASH IN HAND',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          remainingKitty >= 0
                              ? 'Fund Available'
                              : 'Overspent',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$curr${remainingKitty.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Collected',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          Text(
                            '$curr${totalCollected.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(height: 24, width: 1, color: Colors.white24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Spent on Shuttles',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          Text(
                            '-$curr${totalSpent.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFFFFCDD2),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(height: 24, width: 1, color: Colors.white24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shuttle Stock',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          Text(
                            '$currentStock Shuttle${currentStock != 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Color(0xFFC8E6C9),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Stock Quick Use Banner (e.g. at the court when using a shuttle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: currentStock > 0
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: currentStock > 0
                      ? Colors.green.shade200
                      : Colors.orange.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sports_tennis,
                    color: currentStock > 0
                        ? AppTheme.primaryGreen
                        : Colors.orange.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      currentStock > 0
                          ? '$currentStock shuttle(s) ready for games'
                          : 'No shuttles in stock! Please buy shuttles.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: currentStock > 0
                            ? AppTheme.primaryGreen
                            : Colors.orange.shade900,
                      ),
                    ),
                  ),
                  if (currentStock > 0)
                    ElevatedButton(
                      onPressed: () => controller.useShuttle(count: 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '-1 Shuttle Used',
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Two Quick Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.bottomSheet(
                        const AddShuttlePurchaseSheet(),
                        isScrollControlled: true,
                      );
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: const Text('Buy Shuttles'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.bottomSheet(
                        const AddCollectionSheet(),
                        isScrollControlled: true,
                      );
                    },
                    icon: const Icon(Icons.add_circle, size: 18),
                    label: const Text('Collect Money'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Switcher: Purchases & Stock vs Money Collections
            SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  label: Text('🛒 Purchases (${controller.shuttlePurchases.length})'),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('💰 Collections (${controller.collections.length})'),
                ),
              ],
              selected: {_selectedTabIndex},
              onSelectionChanged: (val) {
                setState(() => _selectedTabIndex = val.first);
              },
            ),
            const SizedBox(height: 14),

            // Tab 0: Shuttle Purchases (Deductions & Stock)
            if (_selectedTabIndex == 0) ...[
              if (controller.shuttlePurchases.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text(
                            'No Shuttle Purchases Recorded',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'When you buy shuttles from the store, tap "Buy Shuttles" above to deduct the money and add stock!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...controller.shuttlePurchases.map(
                  (purchase) => _buildPurchaseCard(
                    context,
                    controller,
                    purchase,
                    curr,
                    dateFormat,
                  ),
                ),
            ],

            // Tab 1: Money Collections (From Players)
            if (_selectedTabIndex == 1) ...[
              if (controller.collections.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No collection entries yet.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                )
              else
                ...controller.collections.map(
                  (col) => _buildCollectionCard(
                    context,
                    controller,
                    col,
                    curr,
                    dateFormat,
                  ),
                ),
            ],
            const SizedBox(height: 40),
          ],
        );
      }),
    );
  }

  Widget _buildPurchaseCard(
    BuildContext context,
    BadmintonController controller,
    ShuttlePurchase p,
    String curr,
    DateFormat dateFormat,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shopping_cart,
            color: Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          p.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '${p.quantity} shuttle(s) • ${dateFormat.format(p.date)}${p.notes.isNotEmpty ? " • ${p.notes}" : ""}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '-$curr${p.totalCost.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.grey.shade400,
              onPressed: () {
                Get.defaultDialog(
                  title: 'Delete Purchase?',
                  middleText:
                      'Remove this purchase of $curr${p.totalCost.toStringAsFixed(0)}? Money will be returned to kitty.',
                  textConfirm: 'Delete',
                  textCancel: 'Cancel',
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                  onConfirm: () {
                    controller.deleteShuttlePurchase(p.id);
                    Get.back();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionCard(
    BuildContext context,
    BadmintonController controller,
    CollectionEvent col,
    String curr,
    DateFormat dateFormat,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.sports_tennis,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
        ),
        title: Text(
          col.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '$curr${col.amountPerMember.toStringAsFixed(0)}/player • ${col.targetMemberIds.length} players • ${dateFormat.format(col.createdAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+$curr${col.totalTargetAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.primaryGreen,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.grey.shade400,
              onPressed: () {
                Get.defaultDialog(
                  title: 'Delete Collection?',
                  middleText:
                      'Remove this collection and deduct $curr${col.amountPerMember.toStringAsFixed(0)} from dues?',
                  textConfirm: 'Delete',
                  textCancel: 'Cancel',
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                  onConfirm: () {
                    controller.deleteCollection(col.id);
                    Get.back();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
