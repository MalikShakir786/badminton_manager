import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/badminton_controller.dart';
import '../models/member_balance.dart';
import '../utils/app_theme.dart';
import 'member_detail_screen.dart';
import 'collections_screen.dart';
import 'matchmaking_screen.dart';
import 'history_screen.dart';
import 'widgets/add_collection_sheet.dart';
import 'widgets/add_member_sheet.dart';
import 'widgets/record_payment_sheet.dart';
import 'widgets/share_summary_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardHomeTab(
            onOpenMatchmaking: () => setState(() => _currentIndex = 1),
          ),
          const MatchmakingScreen(),
          const CollectionsScreen(),
          const HistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Money & Dues',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_tennis_outlined),
            selectedIcon: Icon(Icons.sports_tennis),
            label: 'Make Teams',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Shuttle Pool',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class _DashboardHomeTab extends StatelessWidget {
  final VoidCallback onOpenMatchmaking;

  const _DashboardHomeTab({required this.onOpenMatchmaking});

  @override
  Widget build(BuildContext context) {
    final BadmintonController controller = Get.find<BadmintonController>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sports_tennis,
                color: AppTheme.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Badminton Kitty',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF25D366)),
            tooltip: 'Share on WhatsApp',
            onPressed: () {
              Get.bottomSheet(
                const ShareSummarySheet(),
                isScrollControlled: true,
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'currency') {
                _showCurrencyDialog(context, controller);
              } else if (val == 'add_member') {
                Get.bottomSheet(
                  const AddMemberSheet(),
                  isScrollControlled: true,
                );
              } else if (val == 'reset') {
                Get.defaultDialog(
                  title: 'Reset Data?',
                  middleText:
                      'Restore sample badminton group data with players & collections?',
                  textConfirm: 'Reset',
                  textCancel: 'Cancel',
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                  onConfirm: () {
                    controller.resetAllData();
                    Get.back();
                  },
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_member',
                child: Row(
                  children: [
                    Icon(Icons.person_add_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Add Player'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'currency',
                child: Row(
                  children: [
                    Icon(Icons.currency_exchange, size: 20),
                    SizedBox(width: 8),
                    Text('Change Currency Symbol'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Restore Sample Data', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        final curr = controller.currencySymbol.value;
        final totalPending = controller.totalGroupPending;
        final totalCollected = controller.totalGroupCollected;
        final pendingCount = controller.pendingMembersCount;
        final settledCount = controller.settledMembersCount;
        final balances = controller.filteredMemberBalances;

        return RefreshIndicator(
          onRefresh: () async {
            controller.loadFromStorage();
          },
          child: CustomScrollView(
            slivers: [
              // Summary Cards Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Overview Bento Cards
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: totalPending > 0
                                    ? const Color(0xFFFFF7ED)
                                    : const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: totalPending > 0
                                      ? const Color(0xFFFDBA74)
                                      : const Color(0xFF86EFAC),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'PENDING DUE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          color: AppTheme.warningOrange,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.warningOrange
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.pending_actions,
                                          size: 16,
                                          color: AppTheme.warningOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$curr${totalPending.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.warningOrange,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$pendingCount players pending',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF86EFAC),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'TOTAL COLLECTED',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          color: AppTheme.successGreen,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreen
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.savings_outlined,
                                          size: 16,
                                          color: AppTheme.successGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$curr${totalCollected.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.successGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$settledCount players settled',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Cash in Kitty & Shuttle Stock Strip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet,
                                  size: 18,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Kitty Cash: $curr${controller.kittyBalanceRemaining.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.sports_tennis,
                                  size: 18,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Stock: ${controller.currentShuttleStock} Shuttle${controller.currentShuttleStock != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Highlight Quick Action Button: New 500 Shuttle Entry
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.bottomSheet(
                              const AddCollectionSheet(),
                              isScrollControlled: true,
                            );
                          },
                          icon: const Icon(Icons.add_circle, size: 22),
                          label: Text(
                            '🏸 Add Shuttle Collection (+ ${curr}500 to All)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quick Action Secondary Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Get.bottomSheet(
                                  const AddMemberSheet(),
                                  isScrollControlled: true,
                                );
                              },
                              icon: const Icon(Icons.person_add_alt_1, size: 18),
                              label: const Text('Add Player'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onOpenMatchmaking,
                              icon: const Icon(Icons.shuffle, size: 18, color: AppTheme.primaryGreen),
                              label: const Text('Match Making'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              Get.bottomSheet(
                                const ShareSummarySheet(),
                                isScrollControlled: true,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF25D366),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            child: const Icon(
                              Icons.share,
                              size: 18,
                              color: Color(0xFF25D366),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search Box
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search player name or phone...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: controller.searchQuery.value.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    controller.searchQuery.value = '';
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (val) => controller.searchQuery.value = val,
                      ),
                      const SizedBox(height: 12),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              controller,
                              id: 'all',
                              label: 'All Players (${controller.members.length})',
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              controller,
                              id: 'pending',
                              label: 'Has Dues ($pendingCount)',
                              badgeColor: AppTheme.warningOrange,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              controller,
                              id: 'settled',
                              label: 'Settled ($settledCount)',
                              badgeColor: AppTheme.successGreen,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Player List
              if (balances.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            controller.members.isEmpty
                                ? 'No players added yet!'
                                : 'No players match your filter.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (controller.members.isEmpty)
                            ElevatedButton.icon(
                              onPressed: () {
                                Get.bottomSheet(
                                  const AddMemberSheet(),
                                  isScrollControlled: true,
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Player'),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final b = balances[index];
                        return _buildPlayerCard(context, controller, b, curr);
                      },
                      childCount: balances.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.bottomSheet(
            const AddMemberSheet(),
            isScrollControlled: true,
          );
        },
        backgroundColor: AppTheme.primaryGreen,
        tooltip: 'Add Player',
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(
    BadmintonController controller, {
    required String id,
    required String label,
    Color? badgeColor,
  }) {
    final isSelected = controller.filterStatus.value == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
      ),
      avatar: badgeColor != null
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onSelected: (val) {
        if (val) {
          controller.filterStatus.value = id;
        }
      },
    );
  }

  Widget _buildPlayerCard(
    BuildContext context,
    BadmintonController controller,
    MemberBalance b,
    String curr,
  ) {
    final member = b.member;
    final hasDue = b.remainingDue > 0;
    final isChecked = b.isSettled;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Get.to(() => MemberDetailScreen(memberId: member.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(member.colorValue),
                    child: Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                member.skillBadge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          b.totalPaid > 0
                              ? 'Paid $curr${b.totalPaid.toStringAsFixed(0)} of $curr${b.totalOwed.toStringAsFixed(0)}'
                              : 'Total Owed: $curr${b.totalOwed.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Remaining Due Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isChecked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: AppTheme.successGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                b.remainingDue < 0
                                    ? '+$curr${b.remainingDue.abs().toStringAsFixed(0)}'
                                    : 'CLEARED',
                                style: const TextStyle(
                                  color: AppTheme.successGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            '$curr${b.remainingDue.toStringAsFixed(0)} Due',
                            style: const TextStyle(
                              color: AppTheme.warningOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Action Buttons Row: Quick Check vs Partial Payment
              Row(
                children: [
                  // One-Tap Check Button: User requirement: "and when we collect we make them check"
                  if (hasDue)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          controller.quickSettleMember(member.id);
                        },
                        icon: const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: AppTheme.successGreen,
                        ),
                        label: Text(
                          'Check / Settle ($curr${b.remainingDue.toStringAsFixed(0)})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successGreen,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppTheme.successGreen,
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: AppTheme.successGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Paid in full',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),

                  // Collect Partial / Custom Amount Button
                  // User requirement: "or we can get some amount and some amount remians in the remianings of that player"
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.bottomSheet(
                        RecordPaymentSheet(member: member),
                        isScrollControlled: true,
                      );
                    },
                    icon: const Icon(Icons.payment, size: 14),
                    label: const Text(
                      'Collect',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyDialog(
    BuildContext context,
    BadmintonController controller,
  ) {
    final currencies = ['₹', '\$', '€', '£', '₨', 'AED', 'RM', 'SGD'];

    Get.defaultDialog(
      title: 'Select Currency Symbol',
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: currencies.map((curr) {
          final isSelected = controller.currencySymbol.value == curr;
          return ChoiceChip(
            label: Text(
              curr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (val) {
              if (val) {
                controller.setCurrency(curr);
                Get.back();
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
