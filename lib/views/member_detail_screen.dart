import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/badminton_controller.dart';
import '../models/member.dart';
import '../models/member_balance.dart';
import '../utils/app_theme.dart';
import 'widgets/record_payment_sheet.dart';

class MemberDetailScreen extends StatelessWidget {
  final String memberId;

  const MemberDetailScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    final BadmintonController controller = Get.find<BadmintonController>();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Obx(() {
      final member = controller.members.firstWhereOrNull((m) => m.id == memberId);
      if (member == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Player Details')),
          body: const Center(child: Text('Player not found')),
        );
      }

      final balance = controller.getBalanceForMember(memberId);
      final payments = controller.getPaymentsForMember(memberId);
      final memberCollections = controller.getCollectionsForMember(memberId);
      final curr = controller.currencySymbol.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(member.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Player',
              onPressed: () => _showEditMemberDialog(context, controller, member),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete Player',
              onPressed: () => _confirmDeleteMember(context, controller, member),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Player Profile Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(member.colorValue),
                        child: Text(
                          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            if (member.phone.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  member.phone,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _buildStatusPill(balance),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    member.skillBadge,
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Financial Metrics
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Owed',
                      amount: '$curr${balance.totalOwed.toStringAsFixed(0)}',
                      subtitle: 'from ${memberCollections.length} collections',
                      color: Colors.blue.shade700,
                      icon: Icons.receipt_long,
                      bgColor: Colors.blue.shade50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Paid',
                      amount: '$curr${balance.totalPaid.toStringAsFixed(0)}',
                      subtitle: 'in ${payments.length} payments',
                      color: AppTheme.successGreen,
                      icon: Icons.payments_outlined,
                      bgColor: Colors.green.shade50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Remaining Due Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: balance.remainingDue > 0
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: balance.remainingDue > 0
                        ? Colors.orange.shade300
                        : Colors.green.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance.remainingDue > 0
                              ? 'REMAINING DUE'
                              : 'BALANCE STATUS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: balance.remainingDue > 0
                                ? AppTheme.warningOrange
                                : AppTheme.successGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          balance.remainingDue > 0
                              ? '$curr${balance.remainingDue.toStringAsFixed(0)}'
                              : balance.remainingDue < 0
                                  ? 'Advance $curr${balance.remainingDue.abs().toStringAsFixed(0)}'
                                  : 'All Cleared (${curr}0)',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: balance.remainingDue > 0
                                ? AppTheme.warningOrange
                                : AppTheme.successGreen,
                          ),
                        ),
                      ],
                    ),
                    if (balance.remainingDue > 0)
                      ElevatedButton.icon(
                        onPressed: () => controller.quickSettleMember(member.id),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Check / Settle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.bottomSheet(
                          RecordPaymentSheet(member: member),
                          isScrollControlled: true,
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Record Payment'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Payments History Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    '${payments.length} transactions',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (payments.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No payments recorded yet',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, idx) {
                    final p = payments[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_downward,
                            color: AppTheme.successGreen,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '+$curr${p.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.successGreen,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${p.paymentMethod} • ${dateFormat.format(p.date)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (p.notes.isNotEmpty)
                              Text(
                                p.notes,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: Colors.grey.shade400,
                          onPressed: () {
                            Get.defaultDialog(
                              title: 'Delete Payment?',
                              middleText:
                                  'Remove this payment of $curr${p.amount.toStringAsFixed(0)}? Balance will be updated.',
                              textConfirm: 'Delete',
                              textCancel: 'Cancel',
                              confirmTextColor: Colors.white,
                              buttonColor: Colors.red,
                              onConfirm: () {
                                Get.back();
                                controller.deletePayment(p.id);
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Shuttle Collections Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Shuttle Collections Included',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    '${memberCollections.length} collections',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (memberCollections.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Not included in any shuttle collections yet.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: memberCollections.length,
                  itemBuilder: (context, idx) {
                    final c = memberCollections[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sports_tennis,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          c.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${c.shuttleBrand} • ${DateFormat('dd MMM yyyy').format(c.createdAt)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '$curr${c.amountPerMember.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatusPill(MemberBalance balance) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (balance.status) {
      case MemberPaymentStatus.settled:
        bg = Colors.green.shade100;
        fg = AppTheme.successGreen;
        label = 'PAID IN FULL';
        icon = Icons.check_circle;
        break;
      case MemberPaymentStatus.partial:
        bg = Colors.orange.shade100;
        fg = AppTheme.warningOrange;
        label = 'PARTIALLY PAID';
        icon = Icons.timelapse;
        break;
      case MemberPaymentStatus.unpaid:
        bg = Colors.red.shade100;
        fg = AppTheme.pendingRed;
        label = 'DUE / UNPAID';
        icon = Icons.error_outline;
        break;
      case MemberPaymentStatus.credit:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        label = 'ADVANCE CREDIT';
        icon = Icons.credit_card;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required String subtitle,
    required Color color,
    required IconData icon,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditMemberDialog(
    BuildContext context,
    BadmintonController controller,
    Member member,
  ) {
    final nameCtrl = TextEditingController(text: member.name);
    final phoneCtrl = TextEditingController(text: member.phone);
    int selectedSkill = member.skillLevel;

    Get.defaultDialog(
      title: 'Edit Player',
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Player Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 14),
              const Text(
                'Skill Level (For Matchmaking):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: selectedSkill,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(
                    value: Member.skillPlayGood,
                    child: Text('🟢 Play Good'),
                  ),
                  DropdownMenuItem(
                    value: Member.skillPlayMedium,
                    child: Text('🔵 Play Medium'),
                  ),
                  DropdownMenuItem(
                    value: Member.skillPlayLess,
                    child: Text('🟡 Play Less'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selectedSkill = val);
                  }
                },
              ),
            ],
          );
        },
      ),
      textConfirm: 'Save',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppTheme.primaryGreen,
      onConfirm: () {
        if (nameCtrl.text.trim().isNotEmpty) {
          Get.back();
          controller.updateMember(
            member.copyWith(
              name: nameCtrl.text.trim(),
              phone: phoneCtrl.text.trim(),
              skillLevel: selectedSkill,
            ),
          );
        }
      },
    );
  }

  void _confirmDeleteMember(
    BuildContext context,
    BadmintonController controller,
    Member member,
  ) {
    Get.defaultDialog(
      title: 'Remove Player?',
      middleText:
          'Are you sure you want to remove ${member.name} from the group? Their past records will be removed.',
      textConfirm: 'Remove',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back(); // close dialog
        Get.back(); // leave detail screen
        controller.deleteMember(member.id);
      },
    );
  }
}
