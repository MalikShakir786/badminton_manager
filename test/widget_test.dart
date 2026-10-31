import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:badminton_manager/controllers/badminton_controller.dart';
import 'package:badminton_manager/models/member.dart';
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

    // Initial state should be completely clean (no dummy data)
    expect(controller.members.isEmpty, isTrue);

    // 1. Add new member with 3-tier skill level (3: Good, 2: Medium, 1: Less)
    controller.addMember(name: 'Test Player', phone: '1234567890', skillLevel: Member.skillPlayGood);
    expect(controller.members.length, equals(1));
    final newMember = controller.members.last;
    expect(newMember.skillLevel, equals(Member.skillPlayGood));
    expect(newMember.skillBadge, equals('Play Good 🟢'));

    // 2. Add a new 500 collection entry
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

  testWidgets('Balanced Matchmaking with 3 skill levels (Good, Medium, Less) and resting rotation', (WidgetTester tester) async {
    final controller = BadmintonController();
    Get.put(controller);

    // Setup 6 players: 2 Good (3), 2 Medium (2), 2 Less (1)
    controller.addMember(name: 'Good Player 1', skillLevel: Member.skillPlayGood);
    controller.addMember(name: 'Good Player 2', skillLevel: Member.skillPlayGood);
    controller.addMember(name: 'Med Player 1', skillLevel: Member.skillPlayMedium);
    controller.addMember(name: 'Med Player 2', skillLevel: Member.skillPlayMedium);
    controller.addMember(name: 'Less Player 1', skillLevel: Member.skillPlayLess);
    controller.addMember(name: 'Less Player 2', skillLevel: Member.skillPlayLess);
    expect(controller.members.length, equals(6));

    // 1. Test 4 players on 1 court: Good (3) + Good (3) + Less (1) + Less (1)
    final p1 = controller.members[0]; // Good (3)
    final p2 = controller.members[1]; // Good (3)
    final p3 = controller.members[4]; // Less (1)
    final p4 = controller.members[5]; // Less (1)

    // Select only these 4 players present (others absent via checkboxes)
    controller.selectedPresentMemberIds.assignAll([p1.id, p2.id, p3.id, p4.id]);

    controller.generateBalancedMatches(isNextRound: false, showNotice: false);
    final round1 = controller.currentMatchRound.value;
    expect(round1, isNotNull);
    expect(round1!.matches.length, equals(1));
    expect(round1.restingPlayers.isEmpty, isTrue);

    final match = round1.matches.first;
    expect(match.teamA.players.length, equals(2));
    expect(match.teamB.players.length, equals(2));

    // (Good + Less = 4) vs (Good + Less = 4) -> Diff = 0
    expect(match.teamA.totalSkill, equals(4));
    expect(match.teamB.totalSkill, equals(4));
    expect(match.skillDifference, equals(0));
    expect(match.isPerfectMatch, isTrue);

    // 2. Test cycleMemberSkillLevel: Good(3) -> Medium(2) -> Less(1) -> Good(3)
    controller.cycleMemberSkillLevel(p1.id);
    expect(controller.members.firstWhere((m) => m.id == p1.id).skillLevel, equals(Member.skillPlayMedium));

    controller.cycleMemberSkillLevel(p1.id);
    expect(controller.members.firstWhere((m) => m.id == p1.id).skillLevel, equals(Member.skillPlayLess));

    controller.cycleMemberSkillLevel(p1.id);
    expect(controller.members.firstWhere((m) => m.id == p1.id).skillLevel, equals(Member.skillPlayGood));

    // 3. Test with all 6 players (4 playing on Court 1, 2 resting)
    controller.selectedPresentMemberIds.assignAll(controller.members.map((m) => m.id));

    controller.generateBalancedMatches(isNextRound: false, showNotice: false);
    final round6p = controller.currentMatchRound.value;
    expect(round6p!.matches.length, equals(1));
    expect(round6p.restingPlayers.length, equals(2));

    final restedNames = round6p.restingPlayers.map((m) => m.id).toList();

    // 4. Test Next Round / Set rotation: Resting players MUST play in the next round
    controller.generateBalancedMatches(isNextRound: true, showNotice: false);
    final roundNext = controller.currentMatchRound.value;
    expect(roundNext!.roundNumber, equals(2));

    // Verify both previously rested players are now on court playing
    final activeInNext = roundNext.matches.first.teamA.players + roundNext.matches.first.teamB.players;
    final activeInNextIds = activeInNext.map((m) => m.id).toList();
    for (var restedId in restedNames) {
      expect(activeInNextIds.contains(restedId), isTrue);
    }

    // 5. Test WhatsApp Lineup Text
    final lineupText = controller.generateMatchWhatsAppText();
    expect(lineupText.contains('BADMINTON TEAMS'), isTrue);
    expect(lineupText.contains('COURT 1'), isTrue);
    expect(lineupText.contains('Team 1'), isTrue);
    expect(lineupText.contains('Team 2'), isTrue);

    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('Shuttle purchase deduction and stock tracking workflow', (WidgetTester tester) async {
    final controller = BadmintonController();
    Get.put(controller);

    controller.payments.clear();
    controller.shuttlePurchases.clear();
    controller.shuttlesUsed.value = 0;

    // 1. Simulate collected 1000 from members
    controller.recordPayment(memberId: 'm1', amount: 500);
    controller.recordPayment(memberId: 'm2', amount: 500);
    expect(controller.totalGroupCollected, equals(1000.0));
    expect(controller.kittyBalanceRemaining, equals(1000.0));
    expect(controller.currentShuttleStock, equals(0));

    // 2. Buy 2 shuttles for 700
    // 700 is deducted from collected 1000 -> remaining kitty is 300!
    controller.recordShuttlePurchase(
      title: 'Yonex Mavis 350',
      quantity: 2,
      totalCost: 700.0,
    );

    expect(controller.totalSpentOnShuttles, equals(700.0));
    expect(controller.kittyBalanceRemaining, equals(300.0));
    expect(controller.totalShuttlesStockBought, equals(2));
    expect(controller.currentShuttleStock, equals(2));

    // 3. Open/use 1 shuttle on court
    controller.useShuttle(count: 1);
    expect(controller.currentShuttleStock, equals(1));

    // 4. Test WhatsApp report includes kitty balance and stock
    final report = controller.generateShareableSummary();
    expect(report.contains('Spent on Shuttles: ₹700'), isTrue);
    expect(report.contains('Kitty Cash Remaining: ₹300'), isTrue);
    expect(report.contains('Shuttle Stock: 1 Shuttle(s)'), isTrue);

    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('Dashboard UI renders correctly with empty and populated states', (WidgetTester tester) async {
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

    // Verify Navigation Bar items
    expect(find.text('Money & Dues'), findsOneWidget);
    expect(find.text('Make Teams'), findsWidgets);
    expect(find.text('Shuttle Pool'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
  });
}
