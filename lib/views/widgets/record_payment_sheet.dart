import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/badminton_controller.dart';
import '../../models/member.dart';
import '../../models/member_balance.dart';
import '../../utils/app_theme.dart';

class RecordPaymentSheet extends StatefulWidget {
  final Member member;

  const RecordPaymentSheet({super.key, required this.member});

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final BadmintonController controller = Get.find<BadmintonController>();
  late TextEditingController _amountController;
  final TextEditingController _notesController = TextEditingController();

  String _paymentMethod = 'UPI / Online';
  final List<String> _methods = ['UPI / Online', 'Cash', 'Bank Transfer', 'Other'];

  late MemberBalance _currentBalance;

  @override
  void initState() {
    super.initState();
    _currentBalance = controller.getBalanceForMember(widget.member.id);
    final defaultAmount = _currentBalance.remainingDue > 0
        ? _currentBalance.remainingDue.toStringAsFixed(0)
        : '500';
    _amountController = TextEditingController(text: defaultAmount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitPayment(double amount) {
    if (amount <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Please enter a payment amount greater than 0',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    controller.recordPayment(
      memberId: widget.member.id,
      amount: amount,
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim(),
    );

    Get.back();
  }

  void _markFullPayment() {
    controller.quickSettleMember(widget.member.id, method: _paymentMethod);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final curr = controller.currencySymbol.value;
    _currentBalance = controller.getBalanceForMember(widget.member.id);

    final enteredAmount = double.tryParse(_amountController.text) ?? 0.0;
    final calculatedRemaining = _currentBalance.remainingDue - enteredAmount;

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
            // Drag handle
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

            // Member Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(widget.member.colorValue),
                  child: Text(
                    widget.member.name.isNotEmpty
                        ? widget.member.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.member.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      if (widget.member.phone.isNotEmpty)
                        Text(
                          widget.member.phone,
                          style: TextStyle(
                            fontSize: 12,
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
            const SizedBox(height: 16),

            // Balance Status Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _currentBalance.remainingDue > 0
                    ? Colors.orange.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _currentBalance.remainingDue > 0
                      ? Colors.orange.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Owed: $curr${_currentBalance.totalOwed.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Total Paid: $curr${_currentBalance.totalPaid.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Current Remaining',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        _currentBalance.remainingDue > 0
                            ? '$curr${_currentBalance.remainingDue.toStringAsFixed(0)}'
                            : 'Fully Cleared ✅',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _currentBalance.remainingDue > 0
                              ? AppTheme.warningOrange
                              : AppTheme.successGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // If player has remaining dues, offer ONE-TAP CHECK button!
            if (_currentBalance.remainingDue > 0) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _markFullPayment,
                  icon: const Icon(Icons.check_circle_outline, size: 22),
                  label: Text(
                    'Check & Settle Full ($curr${_currentBalance.remainingDue.toStringAsFixed(0)})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'OR RECORD PARTIAL PAYMENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Custom Amount Input
            Text(
              'Payment Amount ($curr)',
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
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    curr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: 'Enter amount paid',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // Quick Chips
            Wrap(
              spacing: 8,
              children: [
                if (_currentBalance.remainingDue > 0)
                  ActionChip(
                    label: Text('Full Due ($curr${_currentBalance.remainingDue.toStringAsFixed(0)})'),
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    onPressed: () {
                      setState(() {
                        _amountController.text =
                            _currentBalance.remainingDue.toStringAsFixed(0);
                      });
                    },
                  ),
                if (_currentBalance.remainingDue > 100)
                  ActionChip(
                    label: Text(
                        'Half ($curr${(_currentBalance.remainingDue / 2).toStringAsFixed(0)})'),
                    onPressed: () {
                      setState(() {
                        _amountController.text =
                            (_currentBalance.remainingDue / 2)
                                .toStringAsFixed(0);
                      });
                    },
                  ),
                ActionChip(
                  label: Text('${curr}100'),
                  onPressed: () => setState(() => _amountController.text = '100'),
                ),
                ActionChip(
                  label: Text('${curr}200'),
                  onPressed: () => setState(() => _amountController.text = '200'),
                ),
                ActionChip(
                  label: Text('${curr}500'),
                  onPressed: () => setState(() => _amountController.text = '500'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Live Remaining Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    calculatedRemaining <= 0
                        ? Icons.check_circle
                        : Icons.pending_actions,
                    size: 20,
                    color: calculatedRemaining <= 0
                        ? AppTheme.successGreen
                        : AppTheme.warningOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      calculatedRemaining == 0
                          ? 'This payment will fully clear all dues!'
                          : calculatedRemaining > 0
                              ? 'After this payment, remaining due will be $curr${calculatedRemaining.toStringAsFixed(0)}.'
                              : 'Player will have an advance credit of $curr${calculatedRemaining.abs().toStringAsFixed(0)}.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: calculatedRemaining <= 0
                            ? AppTheme.successGreen
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Method Selector
            const Text(
              'Payment Mode',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _methods.map((method) {
                final isSelected = _paymentMethod == method;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _paymentMethod = method),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            method.split(' ').first,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Notes
            const Text(
              'Notes (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'e.g. Paid cash at court, GPay ref #1234',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _submitPayment(enteredAmount),
                child: Text(
                  'Record Payment of $curr${enteredAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
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
