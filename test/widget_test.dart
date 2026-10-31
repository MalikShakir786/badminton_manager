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
    controller.members.clear();
    controller.collections.clear();
    controller.payments.clear();
    controller.shuttlePurchases.clear();
    controller.selectedPresentMemberIds.clear();

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
    controller.members.clear();
    controller.selectedPresentMemberIds.clear();
    controller.autoGraspForRemainder.value = false; // test pure resting rotation

    controller.addMember(name: 'Good Player 1', skillLevel: Member.skillPlayGood);
    controller.addMember(name: 'Good Player 2', skillLevel: Member.skillPlayGood);
    controller.addMember(name: 'Med Player 1', skillLevel: Member.skillPlayMedium);
    controller.addMember(name: 'Med Player 2', skillLevel: Member.skillPlayMedium);
    controller.addMember(name: 'Less Player 1', skillLevel: Member.skillPlayLess);
    controller.addMember(name: 'Less Player 2', skillLevel: Member.skillPlayLess);
    expect(controller.members.length, equals(6));

    // 1. Test 4 players on 1 court
    final p1 = controller.members[0];
    final p2 = controller.members[1];
    final p3 = controller.members[4];
    final p4 = controller.members[5];

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

    // 4. Test Next Round rotation: Resting players play next round
    controller.generateBalancedMatches(isNextRound: true, showNotice: false);
    final roundNext = controller.currentMatchRound.value;
    expect(roundNext!.roundNumber, equals(2));

    final activeInNext = roundNext.matches.first.teamA.players + roundNext.matches.first.teamB.players;
    final activeInNextIds = activeInNext.map((m) => m.id).toList();
    for (var restedId in restedNames) {
      expect(activeInNextIds.contains(restedId), isTrue);
    }

    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('Grasp player workflow: 15 players with 3 courts full and 3 remaining grasp 1 player for Court 4', (WidgetTester tester) async {
    final controller = BadmintonController();
    Get.put(controller);
    controller.members.clear();
    controller.selectedPresentMemberIds.clear();
    controller.autoGraspForRemainder.value = true;

    // Add exactly 15 players as in user request:
    // "like we are 15 players and 3 courts are full but 3 remaining also make their match and single person will grasp one from the others players playing the game"
    for (int i = 1; i <= 15; i++) {
      controller.addMember(name: 'Player $i', skillLevel: (i % 3) + 1);
    }
    expect(controller.members.length, equals(15));
    expect(controller.selectedPresentMemberIds.length, equals(15));

    // Generate matches
    controller.generateBalancedMatches(isNextRound: false, showNotice: false);
    final round = controller.currentMatchRound.value;
    expect(round, isNotNull);

    // 3 courts full (12 players) + 1 extra court (3 remaining + 1 grasped player) = 4 COURTS TOTAL!
    expect(round!.matches.length, equals(4));
    // No players sitting resting because 1 player was grasped!
    expect(round.restingPlayers.isEmpty, isTrue);

    // Check Court 4 has borrowed player
    final court4 = round.matches[3];
    expect(court4.courtNumber, equals(4));
    expect(court4.hasBorrowedPlayer, isTrue);
    expect(court4.borrowedPlayerIds.length, equals(1));
    expect(court4.borrowedCourtNote, contains('Grasped'));

    // Check WhatsApp output marks the grasped player
    final text = controller.generateMatchWhatsAppText();
    expect(text.contains('COURT 4'), isTrue);
    expect(text.contains('Playing Double Duty'), isTrue);

    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('Tournament Semi-Final and Final: 3 teams with random Bye to final and 2 playing Semi-Final', (WidgetTester tester) async {
    final controller = BadmintonController();
    Get.put(controller);
    controller.members.clear();
    controller.selectedPresentMemberIds.clear();
    controller.tournamentState.value = null;

    // 6 players = 3 teams of 2
    for (int i = 1; i <= 6; i++) {
      controller.addMember(name: 'P$i', skillLevel: 2);
    }

    // Start Tournament with 3 teams
    // "if 3 teams in semi final make a random match from 3 with 2 and 1 moves to final"
    controller.startTournament();

    final tState = controller.tournamentState.value;
    expect(tState, isNotNull);
    expect(tState!.allTeams.length, equals(3));
    expect(tState.currentStage, equals('Semi-Finals'));

    // Verify 1 team has a BYE straight to Grand Final
    expect(tState.byeTeam, isNotNull);
    // Verify only 1 match (between the other 2 teams) in Semi-Finals
    expect(tState.matches.length, equals(1));
    final sfMatch = tState.matches.first;
    expect(sfMatch.stageName, equals('Semi-Final'));

    // Play Semi-Final: Pick Team A as winner
    controller.markTournamentMatchWinner(sfMatch.id, sfMatch.teamA.name);

    final finalState = controller.tournamentState.value;
    expect(finalState!.currentStage, equals('Grand Final'));
    expect(finalState.matches.length, equals(1));

    final finalMatch = finalState.matches.first;
    expect(finalMatch.stageName, equals('Grand Final'));
    // The Final is between the SF Winner and the Bye team!
    expect(finalMatch.teamA.name, equals(sfMatch.teamA.name));
    expect(finalMatch.teamB.name, equals(tState.byeTeam!.name));

    // Play Grand Final: Team A wins!
    controller.markTournamentMatchWinner(finalMatch.id, finalMatch.teamA.name);

    final completedState = controller.tournamentState.value;
    expect(completedState!.currentStage, equals('Completed'));
    expect(completedState.champion, isNotNull);
    expect(completedState.champion!.name, equals(finalMatch.teamA.name));
    expect(completedState.runnerUp, isNotNull);
    expect(completedState.runnerUp!.name, equals(tState.byeTeam!.name));

    // Verify Tournament WhatsApp Summary
    final waText = controller.generateTournamentWhatsAppText();
    expect(waText.contains('TOURNAMENT CHAMPIONS'), isTrue);
    expect(waText.contains(finalMatch.teamA.name), isTrue);

    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('Shuttle purchase deduction and stock tracking workflow', (WidgetTester tester) async {
    final controller = BadmintonController();
    Get.put(controller);
    controller.members.clear();
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
    controller.members.clear();
    controller.collections.clear();
    controller.payments.clear();
    controller.shuttlePurchases.clear();
    controller.shuttlesUsed.value = 0;

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
