import 'package:flutter/material.dart';

import '../../game/progression.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../app_controller.dart';

/// Global leaderboard: this week's XP or all-time XP.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.app, required this.visible});

  final AppController app;

  /// Refresh when the tab comes into view.
  final bool visible;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _Board {
  const _Board(this.entries, this.myRank);
  final List<LeaderboardEntry> entries;
  final int myRank;
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const _timeout = Duration(seconds: 10);

  bool _weekly = true;
  Future<_Board>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.visible) _refresh();
  }

  @override
  void didUpdateWidget(LeaderboardScreen old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) _refresh();
  }

  void _refresh() {
    final app = widget.app;
    final repo = app.repository;
    final weekId = _weekly ? app.weekId : null;
    setState(() {
      _future = () async {
        try {
          // Never spin forever: a stalled connection shows the retry message.
          final (entries, rank) = await (
            repo.leaderboard(weekId: weekId),
            repo.rankFor(_weekly ? app.weeklyXp : app.xp, weekId: weekId),
          ).wait.timeout(_timeout);
          return _Board(entries, rank);
        } on Object catch (e) {
          debugPrint('Leaderboard failed: $e');
          rethrow;
        }
      }();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return RefreshIndicator(
      color: AppColors.pink,
      onRefresh: () async {
        _refresh();
        await _future?.catchError((_) => const _Board([], 0));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
        children: [
          Row(
            children: [
              Expanded(child: Text('Leaderboard', style: baloo(28, height: 1.05))),
              Image.asset('assets/mascot/cheer.png', width: 64),
            ],
          ),
          const SizedBox(height: 12),
          _Toggle(
            weekly: _weekly,
            onChanged: (w) {
              _weekly = w;
              _refresh();
            },
          ),
          const SizedBox(height: 14),
          FutureBuilder<_Board>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.pink)),
                );
              }
              if (snap.hasError || !snap.hasData) {
                return _Message(
                  "Couldn't load the leaderboard. Pull down to try again.",
                  onRetry: _refresh,
                );
              }
              final board = snap.data!;
              final myScore = _weekly ? app.weeklyXp : app.xp;
              // Only players with XP are ranked; zero-XP rows would contradict
              // the "train to get ranked" state.
              final ranked = [
                for (final e in board.entries)
                  if ((_weekly ? e.weeklyXp : e.xp) > 0) e,
              ];
              final inTop = ranked.any((e) => e.uid == app.repository.uid);
              return Column(
                spacing: 8,
                children: [
                  _YouCard(
                    nickname: app.profile.nickname,
                    rank: board.myRank,
                    score: myScore,
                    weekly: _weekly,
                  ),
                  if (ranked.isEmpty)
                    _Message(
                      _weekly
                          ? 'No one on the board yet this week. Train to claim #1!'
                          : 'No one on the board yet. Train to claim #1!',
                    ),
                  for (final (i, e) in ranked.indexed)
                    _Row(
                      position: i + 1,
                      nickname: e.nickname,
                      score: _weekly ? e.weeklyXp : e.xp,
                      rank: rankFor(e.xp).title,
                      me: e.uid == app.repository.uid,
                    ),
                  if (!inTop && ranked.isNotEmpty)
                    Text(
                      'Top ${ranked.length} shown',
                      style: nunito(12, color: AppColors.textFaint),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.weekly, required this.onChanged});

  final bool weekly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool value) => Expanded(
      child: Semantics(
        container: true,
        button: true,
        selected: weekly == value,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: weekly == value ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: nunito(14, color: weekly == value ? AppColors.ink : AppColors.textFaint),
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(16)),
      child: Row(spacing: 4, children: [tab('This week', true), tab('All time', false)]),
    );
  }
}

class _YouCard extends StatelessWidget {
  const _YouCard({
    required this.nickname,
    required this.rank,
    required this.score,
    required this.weekly,
  });

  final String nickname;
  final int rank;
  final int score;
  final bool weekly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.purple,
        borderRadius: BorderRadius.circular(20),
        boxShadow: hardShadow(AppColors.purpleDark, 5),
      ),
      child: Row(
        spacing: 12,
        children: [
          // No XP means no place yet; don't claim #1 on an empty board.
          Text(score > 0 ? '#$rank' : '–', style: baloo(28, color: Colors.white)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(
                  score == 0
                      ? (weekly ? 'TRAIN TO GET RANKED THIS WEEK' : 'TRAIN TO GET RANKED')
                      : (weekly ? 'YOUR RANK THIS WEEK' : 'YOUR ALL-TIME RANK'),
                  color: AppColors.purpleMuted,
                ),
                Text(nickname, style: nunito(16, color: Colors.white)),
              ],
            ),
          ),
          Text('$score XP', style: nunito(15, color: AppColors.lime)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.position,
    required this.nickname,
    required this.score,
    required this.rank,
    required this.me,
  });

  final int position;
  final String nickname;
  final int score;
  final String rank;
  final bool me;

  static const _medals = [Color(0xFFFFC93D), Color(0xFFC9CDD6), Color(0xFFE0A16A)];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: me ? AppColors.pinkTint : Colors.white,
        border: Border.all(color: me ? AppColors.pink : AppColors.line, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: position <= 3 ? _medals[position - 1] : AppColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Text('$position', style: nunito(14, weight: FontWeight.w900)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(me ? '$nickname (you)' : nickname, style: nunito(15)),
                Text(
                  rank,
                  style: nunito(12, weight: FontWeight.w700, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text('$score XP', style: nunito(14, color: AppColors.purple)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      spacing: 8,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: nunito(14, weight: FontWeight.w600, color: AppColors.textMuted),
        ),
        if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
