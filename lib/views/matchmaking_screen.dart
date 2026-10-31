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
          'Make Balanced Teams',
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
              final text = controller.generateMatchWhatsAppText();
              if (text.isEmpty) {
                Get.snackbar(
                  'No Teams Yet',
                  'Tap "Make Teams" first before sharing.',
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
        final round = controller.currentMatchRound.value;
        final courtsCount = presentCount ~/ 4;

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
            // Step 1: Who is playing today?
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
                                'Step 1: Who is playing today? ($presentCount/${members.length})',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                courtsCount > 0
                                    ? '$courtsCount Court(s) • Sets of 2 vs 2${presentCount % 4 != 0 ? " • ${presentCount % 4} resting" : ""}'
                                    : 'Select at least 4 players',
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
                            'Uncheck if absent. Tap badge to change level:',
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
                                // One-tap badge to toggle: Plays Well vs Plays Less
                                InkWell(
                                  onTap: () {
                                    final next = m.isGoodPlayer ? 1 : 2;
                                    controller.updateMemberSkill(m.id, next);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: m.isGoodPlayer
                                          ? Colors.green.shade50
                                          : Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: m.isGoodPlayer
                                            ? Colors.green.shade300
                                            : Colors.amber.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          m.isGoodPlayer
                                              ? '🟢 Plays Well'
                                              : '🟡 Plays Less',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: m.isGoodPlayer
                                              ? Colors.green.shade800
                                              : Colors.orange.shade900,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(
                                          Icons.sync,
                                          size: 11,
                                          color: Colors.grey,
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
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Step 2 Button: Make Balanced Teams
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

            // Teams Section
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Courts List
              ...round.matches.map((match) => _buildMatchCard(context, match)),

              // Resting Players
              if (round.restingPlayers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_bottom,
                          color: Colors.amber.shade900, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Resting this game: ${round.restingPlayers.map((m) => m.name).join(', ')} (They play next game!)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              // WhatsApp Share
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
                      'Pairs 1 player who plays well with 1 regular player on each side so the match is fair and fun.\n\nCheck who is here and tap "Make Balanced Teams"!',
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
      }),
    );
  }

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
            const SizedBox(height: 12),

            // Teams (2 players vs 2 players)
            Row(
              children: [
                // Team A
                Expanded(
                  child: _buildTeamBox(
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
                  Text(
                    p.isGoodPlayer ? '🟢 Plays Well' : '🟡 Plays Less',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: p.isGoodPlayer
                          ? Colors.green.shade800
                          : Colors.orange.shade900,
                    ),
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
