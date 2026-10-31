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
  final List<String> borrowedPlayerIds; // Players playing double duty (grasped from another court)
  final String? borrowedCourtNote; // e.g. "Grasped from Court 1 to complete 4th game"

  BadmintonMatch({
    required this.courtNumber,
    required this.teamA,
    required this.teamB,
    this.borrowedPlayerIds = const [],
    this.borrowedCourtNote,
  });

  bool get hasBorrowedPlayer => borrowedPlayerIds.isNotEmpty;
  bool isPlayerBorrowed(String memberId) => borrowedPlayerIds.contains(memberId);

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

// MARK: - Tournament Mode Models (Knockout, Semi-Finals, Grand Final)

class TournamentMatch {
  final String id;
  final String stageName; // 'Quarter-Final', 'Semi-Final', 'Grand Final'
  final int matchIndex;
  final BadmintonTeam teamA;
  final BadmintonTeam teamB;
  final String? winnerTeamName; // Name of winning team

  TournamentMatch({
    required this.id,
    required this.stageName,
    this.matchIndex = 1,
    required this.teamA,
    required this.teamB,
    this.winnerTeamName,
  });

  bool get isCompleted => winnerTeamName != null;

  BadmintonTeam? get winnerTeam {
    if (winnerTeamName == null) return null;
    return teamA.name == winnerTeamName ? teamA : teamB;
  }

  TournamentMatch copyWith({
    String? id,
    String? stageName,
    int? matchIndex,
    BadmintonTeam? teamA,
    BadmintonTeam? teamB,
    String? winnerTeamName,
  }) {
    return TournamentMatch(
      id: id ?? this.id,
      stageName: stageName ?? this.stageName,
      matchIndex: matchIndex ?? this.matchIndex,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      winnerTeamName: winnerTeamName,
    );
  }
}

class TournamentState {
  final List<BadmintonTeam> allTeams;
  final String currentStage; // 'Quarter-Finals', 'Semi-Finals', 'Grand Final', 'Completed'
  final List<TournamentMatch> matches;
  final BadmintonTeam? byeTeam; // In 3-team Semi-Final: 1 team gets Bye straight to Final!
  final BadmintonTeam? champion;
  final BadmintonTeam? runnerUp;

  TournamentState({
    required this.allTeams,
    required this.currentStage,
    required this.matches,
    this.byeTeam,
    this.champion,
    this.runnerUp,
  });

  bool get isAllMatchesCompleted =>
      matches.isNotEmpty && matches.every((m) => m.isCompleted);

  bool get isFinished => currentStage == 'Completed' && champion != null;
}


