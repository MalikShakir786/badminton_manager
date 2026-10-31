import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/badminton_controller.dart';
import '../models/collection_event.dart';
import '../utils/app_theme.dart';
import 'widgets/add_collection_sheet.dart';

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BadmintonController controller = Get.find<BadmintonController>();
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shuttle Collections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen),
            tooltip: 'Add New Collection',
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
        if (controller.collections.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'No Shuttle Collections Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap below when you need to buy new shuttles\nand collect money from players!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.bottomSheet(
                      const AddCollectionSheet(),
                      isScrollControlled: true,
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add 500 Shuttle Entry'),
                ),
              ],
            ),
          );
        }

        final curr = controller.currencySymbol.value;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.collections.length,
          itemBuilder: (context, idx) {
            final col = controller.collections[idx];
            return _buildCollectionCard(context, controller, col, curr, dateFormat);
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.bottomSheet(
            const AddCollectionSheet(),
            isScrollControlled: true,
          );
        },
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.sports_tennis, color: Colors.white),
        label: const Text(
          'Add Collection',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    // Get list of target players
    final targetPlayers = controller.members
        .where((m) => col.targetMemberIds.contains(m.id))
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_tennis,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        col.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${col.shuttleBrand} • ${dateFormat.format(col.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'delete') {
                      Get.defaultDialog(
                        title: 'Delete Collection?',
                        middleText:
                            'This will remove this collection and deduct $curr${col.amountPerMember.toStringAsFixed(0)} from members\' dues.',
                        textConfirm: 'Delete',
                        textCancel: 'Cancel',
                        confirmTextColor: Colors.white,
                        buttonColor: Colors.red,
                        onConfirm: () {
                          controller.deleteCollection(col.id);
                          Get.back();
                        },
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Per Player',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      Text(
                        '$curr${col.amountPerMember.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  Container(height: 30, width: 1, color: Colors.grey.shade300),
                  Column(
                    children: [
                      const Text(
                        'Players',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      Text(
                        '${col.targetMemberIds.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  Container(height: 30, width: 1, color: Colors.grey.shade300),
                  Column(
                    children: [
                      const Text(
                        'Total Pool',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      Text(
                        '$curr${col.totalTargetAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (col.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Note: ${col.notes}',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                'Included Players (${targetPlayers.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: targetPlayers.map((player) {
                    final balance = controller.getBalanceForMember(player.id);
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: Color(player.colorValue),
                        child: Text(
                          player.name.isNotEmpty
                              ? player.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      label: Text(
                        '${player.name} (${balance.isSettled ? "Paid ✅" : "Due $curr${balance.remainingDue.toStringAsFixed(0)}"})',
                        style: TextStyle(
                          fontSize: 12,
                          color: balance.isSettled
                              ? AppTheme.successGreen
                              : AppTheme.warningOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: balance.isSettled
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      side: BorderSide(
                        color: balance.isSettled
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
