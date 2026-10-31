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

    // 1. Add new member with skill level
    final initialCount = controller.members.length;
    controller.addMember(name: 'Test Player', phone: '1234567890', skillLevel: 3);
    expect(controller.members.length, equals(initialCount + 1));
    final newMember = controller.members.last;
    expect(newMember.skillLevel, equals(3));

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

  testWidgets('Balanced Matchmaking in sets of 2 with attendance checkboxes and resting rotation', (WidgetTester tester) async {
    final controller = BadmintonController();
    Get.put(controller);

    // Initial 8 sample members loaded
    expect(controller.members.length, greaterThanOrEqualTo(8));

    // 1. Test with 4 players: 2 Good Players (2) + 2 Regular Players (1)
    final p1 = controller.members.firstWhere((m) => m.skillLevel == 2);
    final p2 = controller.members.where((m) => m.skillLevel == 2).skip(1).first;
    final p3 = controller.members.firstWhere((m) => m.skillLevel == 1);
    final p4 = controller.members.where((m) => m.skillLevel == 1).skip(1).first;

    // Select only these 4 players present (others absent via checkboxes)
    controller.selectedPresentMemberIds.assignAll([p1.id, p2.id, p3.id, p4.id]);

    controller.generateBalancedMatches(isNextRound: false, showNotice: false);
    final round1 = controller.currentMatchRound.value;
    expect(round1, isNotNull);
    expect(round1!.matches.length, equals(1));
    expect(round1.restingPlayers.isEmpty, isTrue);

    final match = round1.matches.first;
    // Verify each team has a set of 2 players
    expect(match.teamA.players.length, equals(2));
    expect(match.teamB.players.length, equals(2));

    // (Good + Regular = 3) vs (Good + Regular = 3)
    // Team A and Team B should be perfectly balanced with difference 0!
    expect(match.teamA.totalSkill, equals(3));
    expect(match.teamB.totalSkill, equals(3));
    expect(match.skillDifference, equals(0));
    expect(match.isPerfectMatch, isTrue);

    // 2. Test with 6 players (4 playing on Court 1, 2 resting)
    final sixPlayerIds = controller.members.take(6).map((m) => m.id).toList();
    controller.selectedPresentMemberIds.assignAll(sixPlayerIds);

    controller.generateBalancedMatches(isNextRound: false, showNotice: false);
    final round6p = controller.currentMatchRound.value;
    expect(round6p!.matches.length, equals(1));
    expect(round6p.restingPlayers.length, equals(2));

    final restedNames = round6p.restingPlayers.map((m) => m.id).toList();

    // 3. Test Next Round / Set rotation: Resting players MUST play in the next round
    controller.generateBalancedMatches(isNextRound: true, showNotice: false);
    final roundNext = controller.currentMatchRound.value;
    expect(roundNext!.roundNumber, equals(2));

    // Verify both previously rested players are now on court playing
    final activeInNext = roundNext.matches.first.teamA.players + roundNext.matches.first.teamB.players;
    final activeInNextIds = activeInNext.map((m) => m.id).toList();
    for (var restedId in restedNames) {
      expect(activeInNextIds.contains(restedId), isTrue);
    }

    // 4. Test WhatsApp Lineup Text
    final lineupText = controller.generateMatchWhatsAppText();
    expect(lineupText.contains('BADMINTON TEAMS'), isTrue);
    expect(lineupText.contains('COURT 1'), isTrue);
    expect(lineupText.contains('Team 1'), isTrue);
    expect(lineupText.contains('Team 2'), isTrue);

    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('Dashboard UI renders correctly with players, matchmaking navigation and buttons', (WidgetTester tester) async {
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
    expect(find.text('Money & Dues'), findsOneWidget);
    expect(find.text('Make Teams'), findsWidgets);
    expect(find.text('Shuttle Pool'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
  });
}
