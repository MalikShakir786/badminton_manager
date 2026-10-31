import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:badminton_manager/controllers/badminton_controller.dart';
import 'package:badminton_manager/models/member_balance.dart';
import 'package:badminton_manager/views/dashboard_screen.dart';
import 'package:badminton_manager/utils/app_theme.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.testMode = true;
  });

  testWidgets('Badminton Kitty App workflow: Add Member, Add 500 Collection, Partial Payment & Check', (WidgetTester tester) async {
    final controller = BadmintonController();
    Get.put(controller);

    // Initial sample data should be loaded
    expect(controller.members.isNotEmpty, isTrue);

    // 1. Add new member
    final initialCount = controller.members.length;
    controller.addMember(name: 'Test Player', phone: '1234567890');
    expect(controller.members.length, equals(initialCount + 1));
    final newMember = controller.members.last;

    // 2. Add a new 500 collection entry
    // "whenever we enter a new entry like we have to collect new 500 then we add the new 500 entry and it added to all membvers remainings"
    controller.addNewCollection(
      title: 'New Shuttles Test Pool',
      amountPerMember: 500,
      targetMemberIds: [newMember.id],
    );

    // Check balance for new member: owed 500, paid 0, remaining 500
    MemberBalance balance1 = controller.getBalanceForMember(newMember.id);
    expect(balance1.totalOwed, equals(500.0));
    expect(balance1.totalPaid, equals(0.0));
    expect(balance1.remainingDue, equals(500.0));
    expect(balance1.status, equals(MemberPaymentStatus.unpaid));

    // 3. Partial payment test: player pays 200, 300 remains
    // "or we can get some amount and some amount remians in the remianings of that player"
    controller.recordPayment(
      memberId: newMember.id,
      amount: 200,
      notes: 'Partial payment 200',
    );

    MemberBalance balance2 = controller.getBalanceForMember(newMember.id);
    expect(balance2.totalPaid, equals(200.0));
    expect(balance2.remainingDue, equals(300.0));
    expect(balance2.status, equals(MemberPaymentStatus.partial));

    // 4. One-tap Check / Settle remaining due
    // "and when we collect we make them check"
    controller.quickSettleMember(newMember.id);

    MemberBalance balance3 = controller.getBalanceForMember(newMember.id);
    expect(balance3.totalPaid, equals(500.0));
    expect(balance3.remainingDue, equals(0.0));
    expect(balance3.isSettled, isTrue);
    expect(balance3.status, equals(MemberPaymentStatus.settled));

    // 5. Overpayment / Advance credit test
    controller.recordPayment(
      memberId: newMember.id,
      amount: 100,
      notes: 'Extra advance for next time',
    );
    MemberBalance balanceCredit = controller.getBalanceForMember(newMember.id);
    expect(balanceCredit.totalPaid, equals(600.0));
    expect(balanceCredit.remainingDue, equals(-100.0));
    expect(balanceCredit.status, equals(MemberPaymentStatus.credit));

    // 6. Test WhatsApp summary generation
    final summary = controller.generateShareableSummary();
    expect(summary.contains('BADMINTON CLUB - SHUTTLE COLLECTION REPORT'), isTrue);
    expect(summary.contains('Test Player'), isTrue);

    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('Dashboard UI renders correctly with players and buttons', (WidgetTester tester) async {
    final controller = BadmintonController();
    Get.put(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: const DashboardScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & UI Elements
    expect(find.text('Badminton Kitty'), findsOneWidget);
    expect(find.text('PENDING DUE'), findsOneWidget);
    expect(find.text('TOTAL COLLECTED'), findsOneWidget);

    // Verify Action button for 500 shuttle entry
    expect(find.textContaining('Add Shuttle Collection (+ ₹500 to All)'), findsOneWidget);

    // Verify Navigation Bar items
    expect(find.text('Players & Dues'), findsOneWidget);
    expect(find.text('Collections'), findsOneWidget);
    expect(find.text('Ledger'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
  });
}
