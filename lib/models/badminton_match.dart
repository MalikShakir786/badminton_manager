import 'member.dart';

class BadmintonTeam {
  final String name;
  final List<Member> players;

  BadmintonTeam({
    required this.name,
    required this.players,
  });

  int get totalSkill => players.fold(0, (sum, m) => sum + m.skillLevel);

  double get averageSkill =>
      players.isEmpty ? 0 : totalSkill / players.length;

  String get playerNames => players.map((m) => m.name).join(' & ');
}

class BadmintonMatch {
  final int courtNumber;
  final BadmintonTeam teamA;
  final BadmintonTeam teamB;

  BadmintonMatch({
    required this.courtNumber,
    required this.teamA,
    required this.teamB,
  });

  int get skillDifference => (teamA.totalSkill - teamB.totalSkill).abs();

  bool get isPerfectMatch => skillDifference == 0;
  bool get isBalanced => skillDifference <= 1;

  String get balanceRatingText {
    if (skillDifference == 0) {
      return 'Perfect Match (Equal)';
    } else if (skillDifference == 1) {
      return 'Balanced (Fair)';
    } else {
      return 'Slight Difference';
    }
  }
}

class MatchRound {
  final int roundNumber;
  final List<BadmintonMatch> matches;
  final List<Member> restingPlayers;

  MatchRound({
    required this.roundNumber,
    required this.matches,
    this.restingPlayers = const [],
  });
}

