import 'member.dart';

enum MemberPaymentStatus {
  settled, // Paid in full (₹0 due)
  partial, // Partially paid (remaining > 0 and paid > 0)
  unpaid,  // No payment made yet towards dues
  credit,  // Paid extra / advance
}

class MemberBalance {
  final Member member;
  final double totalOwed;
  final double totalPaid;

  MemberBalance({
    required this.member,
    required this.totalOwed,
    required this.totalPaid,
  });

  double get remainingDue => totalOwed - totalPaid;

  MemberPaymentStatus get status {
    if (remainingDue == 0) {
      return MemberPaymentStatus.settled;
    } else if (remainingDue < 0) {
      return MemberPaymentStatus.credit;
    } else if (totalPaid > 0) {
      return MemberPaymentStatus.partial;
    } else {
      return MemberPaymentStatus.unpaid;
    }
  }

  bool get isSettled => remainingDue <= 0;
  bool get hasPendingDue => remainingDue > 0;
}

