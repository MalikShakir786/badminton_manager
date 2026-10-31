import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/badminton_controller.dart';
import '../models/badminton_match.dart';
import '../utils/app_theme.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  bool _isAttendanceExpanded = true;

  @override
  Widget build(BuildContext context) {
    final BadmintonController controller = Get.find<BadmintonController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Make Teams & Tournaments',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF25D366)),
            tooltip: 'Share Lineup to WhatsApp',
            onPressed: () {
              final isTournament = controller.matchmakingModeIndex.value == 1;
              final text = isTournament
                  ? controller.generateTournamentWhatsAppText()
                  : controller.generateMatchWhatsAppText();

              if (text.isEmpty) {
                Get.snackbar(
                  'No Lineup Yet',
                  isTournament
                      ? 'Start a tournament first before sharing.'
                      : 'Tap "Make Teams" first before sharing.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange.shade800,
                  colorText: Colors.white,
                );
                return;
              }
              Clipboard.setData(ClipboardData(text: text));
              Get.snackbar(
                'Lineup Copied! 📋',
                'Ready to paste in your WhatsApp group!',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppTheme.primaryGreen,
                colorText: Colors.white,
                icon: const Icon(Icons.content_paste, color: Colors.white),
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        final members = controller.members;
        final presentIds = controller.selectedPresentMemberIds;
        final presentCount = presentIds.length;
        final courtsCount = presentCount ~/ 4;
        final remainderCount = presentCount % 4;

        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'No Players Added Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your players in the first tab to start making teams.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Mode Segmented Control: Social Sets vs Tournament (SF & Final)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text('🏸 Social Sets (2v2)'),
                    icon: Icon(Icons.sports_tennis),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text('🏆 Tournament (SF & Final)'),
                    icon: Icon(Icons.emoji_events),
                  ),
                ],
                selected: {controller.matchmakingModeIndex.value},
                onSelectionChanged: (val) {
                  controller.matchmakingModeIndex.value = val.first;
                },
              ),
            ),

            // Step 1: Who is playing today? (Attendance Checkboxes + Skill Cycle)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppTheme.primaryGreen, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance: $presentCount of ${members.length} Players Present',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                controller.matchmakingModeIndex.value == 1
                                    ? '${presentCount ~/ 2} Teams of 2 for Tournament'
                                    : (courtsCount > 0
                                        ? (controller.autoGraspForRemainder.value &&
                                                remainderCount >= 2 &&
                                                courtsCount >= 1
                                            ? '${courtsCount + 1} Courts (Grasping ${4 - remainderCount} player so all $presentCount play!)'
                                            : '$courtsCount Court(s) • Sets of 2 vs 2${remainderCount != 0 ? " • $remainderCount resting" : ""}')
                                        : 'Select at least 4 players'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: courtsCount > 0
                                      ? AppTheme.primaryGreen
                                      : Colors.orange.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isAttendanceExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                          onPressed: () {
                            setState(() {
                              _isAttendanceExpanded = !_isAttendanceExpanded;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isAttendanceExpanded) ...[
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Uncheck if absent. Tap badge to cycle level:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () =>
                                    controller.selectAllAttendance(true),
                                child: const Text(
                                  'Select All',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    controller.selectAllAttendance(false),
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: members.length,
                        separatorBuilder: (context, sepIdx) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        itemBuilder: (context, idx) {
                          final m = members[idx];
                          final isPresent = presentIds.contains(m.id);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Color(m.colorValue),
                                  child: Text(
                                    m.name.isNotEmpty
                                        ? m.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    m.name,
                                    style: TextStyle(
                                      fontWeight: isPresent
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isPresent
                                          ? AppTheme.textDark
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                                // One-tap badge to cycle: Play Good -> Play Medium -> Play Less
                                InkWell(
                                  onTap: () {
                                    controller.cycleMemberSkillLevel(m.id);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: m.skillBgColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: m.skillColor.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          m.skillBadge,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: m.skillColor,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.sync,
                                          size: 11,
                                          color: m.skillColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            value: isPresent,
                            activeColor: AppTheme.primaryGreen,
                            onChanged: (_) {
                              controller.toggleMemberAttendance(m.id);
                            },
                          );
                        },
                      ),
                      // Grasp player toggle for remaining players (Social Sets mode)
                      if (controller.matchmakingModeIndex.value == 0) ...[
                        const Divider(height: 20),
                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Grasp player for remaining (Everyone plays)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'e.g. 15 players = 3 courts full + 1 extra court grasping 1 player from other courts',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          value: controller.autoGraspForRemainder.value,
                          activeThumbColor: AppTheme.primaryGreen,
                          onChanged: (val) {
                            controller.autoGraspForRemainder.value = val;
                            if (controller.currentMatchRound.value != null) {
                              controller.generateBalancedMatches(
                                isNextRound: false,
                                showNotice: false,
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Mode Views
            if (controller.matchmakingModeIndex.value == 0)
              _buildSocialSetsView(context, controller, presentCount)
            else
              _buildTournamentView(context, controller, presentCount),
          ],
        );
      }),
    );
  }

  // MARK: - Social Sets Mode View
  Widget _buildSocialSetsView(
    BuildContext context,
    BadmintonController controller,
    int presentCount,
  ) {
    final round = controller.currentMatchRound.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Make Teams Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: presentCount >= 4
                ? () {
                    controller.generateBalancedMatches(
                      isNextRound: false,
                      showNotice: true,
                    );
                    setState(() {
                      _isAttendanceExpanded = false;
                    });
                  }
                : null,
            icon: const Icon(Icons.sports_tennis, size: 22),
            label: Text(
              round == null
                  ? '🏸 Make Balanced Teams (2 vs 2)'
                  : '🎲 Shuffle & Change Partners',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (round != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Game / Set ${round.roundNumber}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  controller.generateBalancedMatches(
                    isNextRound: true,
                    showNotice: true,
                  );
                },
                icon: const Icon(Icons.skip_next, size: 18),
                label: const Text('Next Game / Set'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: const BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Matches List
          ...round.matches.map((m) => _buildMatchCard(context, m)),

          // Resting Players Banner (if not grasping)
          if (round.restingPlayers.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_bottom,
                      color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Resting this game: ${round.restingPlayers.map((m) => m.name).join(", ")} (Guaranteed to play next set!)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Share Lineup for WhatsApp
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                final text = controller.generateMatchWhatsAppText();
                Clipboard.setData(ClipboardData(text: text));
                Get.snackbar(
                  'Lineup Copied! 📋',
                  'Paste directly into your WhatsApp group!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFF25D366),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                  margin: const EdgeInsets.all(12),
                );
              },
              icon: const Icon(Icons.share, size: 20),
              label: const Text(
                'Copy Teams for WhatsApp',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.sports_tennis,
                  size: 40,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Fair 2 vs 2 Teams',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Balances teams across Play Good, Play Medium, and Play Less players so matches are fair and fun.\n\nCheck who is here and tap "Make Balanced Teams"!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  // MARK: - Tournament Mode View (Semi-Finals & Final)
  Widget _buildTournamentView(
    BuildContext context,
    BadmintonController controller,
    int presentCount,
  ) {
    final tState = controller.tournamentState.value;
    final int possibleTeams = presentCount ~/ 2;

    if (tState == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events,
                size: 52,
                color: Colors.amber,
              ),
              const SizedBox(height: 12),
              const Text(
                'Knockout Tournament',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pairs your $presentCount present players into $possibleTeams balanced doubles teams.\n\n'
                '• 3 Teams: 1 team gets a random BYE straight to the Grand Final, other 2 play the Semi-Final!\n'
                '• 4+ Teams: Knockout brackets through Semi-Finals to Grand Final!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: presentCount >= 4
                      ? () {
                          controller.startTournament();
                          setState(() {
                            _isAttendanceExpanded = false;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.play_arrow, size: 22),
                  label: Text(
                    'Start Tournament ($possibleTeams Teams of 2)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Active Tournament
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stage Header Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: tState.isFinished
                ? Colors.amber.shade100
                : AppTheme.primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tState.isFinished
                  ? Colors.amber.shade400
                  : AppTheme.primaryGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    tState.isFinished
                        ? Icons.emoji_events
                        : Icons.sports_tennis,
                    color: tState.isFinished
                        ? Colors.amber.shade900
                        : AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tState.isFinished
                        ? '🏆 TOURNAMENT COMPLETED'
                        : 'STAGE: ${tState.currentStage.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: tState.isFinished
                          ? Colors.amber.shade900
                          : AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => controller.startTournament(),
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('Restart', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Champions Banner if Finished
        if (tState.isFinished && tState.champion != null) ...[
          Card(
            color: Colors.amber.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.amber.shade400, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('🎉 🏆 🎉', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 6),
                  const Text(
                    'CHAMPIONS!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB78103),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tState.champion!.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    tState.champion!.playerNames,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (tState.runnerUp != null) ...[
                    const Divider(height: 24),
                    Text(
                      '🥈 Runner-Up: ${tState.runnerUp!.name} (${tState.runnerUp!.playerNames})',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 3-Team BYE Card: User's rule!
        if (tState.byeTeam != null) ...[
          Card(
            color: Colors.amber.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.amber.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.confirmation_number_outlined,
                      color: Color(0xFFB78103),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎟️ DIRECT TO GRAND FINAL (BYE)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB78103),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tState.byeTeam!.name}: ${tState.byeTeam!.playerNames}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          'Moves directly to Grand Final to play the Semi-Final winner!',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Matches in this stage
        ...tState.matches.map(
          (m) => _buildTournamentMatchCard(context, controller, m),
        ),

        const SizedBox(height: 16),
        // Share Button for WhatsApp
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              final text = controller.generateTournamentWhatsAppText();
              Clipboard.setData(ClipboardData(text: text));
              Get.snackbar(
                'Tournament Copied! 📋',
                'Ready to paste into WhatsApp!',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xFF25D366),
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share Tournament on WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildTournamentMatchCard(
    BuildContext context,
    BadmintonController controller,
    TournamentMatch match,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: match.isCompleted ? Colors.green.shade300 : Colors.grey.shade300,
          width: match.isCompleted ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🏸 ${match.stageName.toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textDark,
                  ),
                ),
                if (match.isCompleted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      '🏆 ${match.winnerTeamName} Won',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Tap winner to advance',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Team A Box
                Expanded(
                  child: _buildTournamentTeamBox(
                    team: match.teamA,
                    isWinner: match.winnerTeamName == match.teamA.name,
                    isCompleted: match.isCompleted,
                    onPickWinner: () => controller.markTournamentMatchWinner(
                      match.id,
                      match.teamA.name,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ),
                // Team B Box
                Expanded(
                  child: _buildTournamentTeamBox(
                    team: match.teamB,
                    isWinner: match.winnerTeamName == match.teamB.name,
                    isCompleted: match.isCompleted,
                    onPickWinner: () => controller.markTournamentMatchWinner(
                      match.id,
                      match.teamB.name,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentTeamBox({
    required BadmintonTeam team,
    required bool isWinner,
    required bool isCompleted,
    required VoidCallback onPickWinner,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isWinner
            ? Colors.green.shade50
            : (isCompleted ? Colors.grey.shade100 : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner
              ? AppTheme.primaryGreen
              : (isCompleted ? Colors.grey.shade300 : Colors.blue.shade200),
          width: isWinner ? 1.8 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isWinner) const Text('🏆 ', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Text(
                  team.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isWinner ? AppTheme.primaryGreen : AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...team.players.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    p.skillBadge,
                    style: TextStyle(fontSize: 9, color: p.skillColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!isCompleted)
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: onPickWinner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  elevation: 1,
                ),
                child: const Text(
                  'Mark Winner 🏆',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else if (isWinner)
            const Center(
              child: Text(
                'ADVANCED ✅',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // MARK: - Regular Court Match Card
  Widget _buildMatchCard(BuildContext context, BadmintonMatch match) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Court Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🏸 COURT ${match.courtNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.textDark,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Text(
                    'Balanced Game ✅',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Grasped player banner if court has a double duty player
            if (match.hasBorrowedPlayer && match.borrowedCourtNote != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt,
                        size: 16, color: Colors.purple),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        match.borrowedCourtNote!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Teams (2 players vs 2 players)
            Row(
              children: [
                // Team A
                Expanded(
                  child: _buildTeamBox(
                    match: match,
                    team: match.teamA,
                    title: 'Team 1',
                    bgColor: Colors.green.shade50,
                    borderColor: Colors.green.shade200,
                    titleColor: const Color(0xFF1B5E20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ),
                // Team B
                Expanded(
                  child: _buildTeamBox(
                    match: match,
                    team: match.teamB,
                    title: 'Team 2',
                    bgColor: Colors.blue.shade50,
                    borderColor: Colors.blue.shade200,
                    titleColor: const Color(0xFF0D47A1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamBox({
    required BadmintonMatch match,
    required BadmintonTeam team,
    required String title,
    required Color bgColor,
    required Color borderColor,
    required Color titleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          ...team.players.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      Text(
                        p.skillBadge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: p.skillColor,
                        ),
                      ),
                      if (match.isPlayerBorrowed(p.id))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.purple.shade300),
                          ),
                          child: const Text(
                            '🔄 Grasped / 2nd Game',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
