import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../game/exercises.dart';

import '../../data/auth.dart';
import '../../onboarding/onboarding_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../app_controller.dart';

/// Nickname, plan summary, sign out and account deletion.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.app, required this.auth});

  final AppController app;
  final AuthService auth;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _busy = false;

  AppController get _app => widget.app;

  Future<void> _editNickname() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _NicknameDialog(initial: _app.profile.nickname),
    );
    if (value == null || value == _app.profile.nickname) return;
    await _guard(() => _app.setNickname(value), "Couldn't save your nickname.");
  }

  Future<T?> _pick<T>(String title, List<(T, String)> options, T current) => showDialog<T>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: [
        for (final (v, label) in options)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, v),
            child: Row(
              children: [
                Expanded(child: Text(label, style: nunito(15))),
                if (v == current) const Icon(Icons.check_rounded, color: AppColors.pink),
              ],
            ),
          ),
      ],
    ),
  );

  Future<void> _editGoal() async {
    final p = _app.profile;
    final v = await _pick('Your goal', [for (final g in goals) (g.id, g.title)], p.goal);
    if (v == null || v == p.goal) return;
    await _guard(() => _app.updateProfile(p.copyWith(goal: v)), "Couldn't save your goal.");
  }

  Future<void> _editMinutes() async {
    final p = _app.profile;
    final v = await _pick('Daily goal', [
      for (final o in timeOptions) (o.minutes, '${o.minutes} min · ${o.label}'),
    ], p.minutes);
    if (v == null || v == p.minutes) return;
    await _guard(
      () => _app.updateProfile(p.copyWith(minutes: v)),
      "Couldn't save your daily goal.",
    );
  }

  Future<void> _editLimitations() async {
    final p = _app.profile;
    final v = await showDialog<Set<Limitation>>(
      context: context,
      builder: (_) => _LimitsDialog(initial: p.limitations),
    );
    if (v == null || setEquals(v, p.limitations)) return;
    await _guard(
      () => _app.updateProfile(p.copyWith(limitations: v)),
      "Couldn't save your settings.",
    );
  }

  Future<void> _signOut() async {
    Navigator.of(context).popUntil((r) => r.isFirst);
    await widget.auth.signOut();
  }

  Future<void> _delete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently removes your profile, workouts, stars and leaderboard entry. '
          "It can't be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await _guard(() async {
      await _app.repository.deleteAll();
      await widget.auth.deleteAccount();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }, "Couldn't delete your account. Check your connection and try again.");
  }

  Future<void> _guard(Future<void> Function() action, String error) async {
    setState(() => _busy = true);
    try {
      await action();
    } on SignInCancelled {
      // Cancelled re-authentication: nothing deleted from the account.
    } on Object catch (e) {
      debugPrint('$error $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _app.profile;
    final email = widget.auth.currentUser?.email;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text('Profile', style: baloo(22)),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListenableBuilder(
          listenable: _app,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            children: [
              Row(
                spacing: 14,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.purpleTint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset('assets/mascot/cheer.png'),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: baloo(24, height: 1.1)),
                        Text(
                          '${_app.rank.title} · ${_app.xp} XP',
                          style: nunito(14, color: AppColors.purple),
                        ),
                        if (email != null)
                          Text(
                            email,
                            style: nunito(12, weight: FontWeight.w600, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedCard(
                padding: EdgeInsets.zero,
                // Transparent Material so the list tiles' ripples show on the card.
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      _Item(label: 'Leaderboard nickname', value: p.nickname, onTap: _editNickname),
                      _Item(label: 'Goal', value: planNameFor(p.goal), onTap: _editGoal),
                      _Item(label: 'Daily goal', value: '${p.minutes} min', onTap: _editMinutes),
                      _Item(label: 'Experience', value: Level.values.byName(p.experience).label),
                      _Item(
                        label: 'Go easy on',
                        value: p.limitations.isEmpty
                            ? 'Nothing'
                            : p.limitations.map((l) => l.label).join(', '),
                        onTap: _editLimitations,
                      ),
                      _Item(label: 'Best streak', value: '${_app.bestStreak} days'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(onPressed: _signOut, child: const Text('Sign out')),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _delete,
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
                child: const Text('Delete account'),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(child: CircularProgressIndicator(color: AppColors.pink)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    title: Text(
      label,
      style: nunito(14, weight: FontWeight.w700, color: AppColors.textMuted),
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Text(value, style: nunito(15)),
        if (onTap != null) const Icon(Icons.edit_rounded, size: 16, color: AppColors.pink),
      ],
    ),
  );
}

/// Owns its text controller, so it's disposed only after the dialog has
/// finished closing (disposing it on pop crashed the closing animation).
class _NicknameDialog extends StatefulWidget {
  const _NicknameDialog({required this.initial});

  final String initial;

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = OnboardingController.validNickname(_ctrl.text);
    return AlertDialog(
      title: const Text('Leaderboard nickname'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLength: 20,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          errorText: ok ? null : "2–20 letters, numbers, spaces or . ' -",
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: ok ? () => Navigator.pop(context, _ctrl.text.trim()) : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _LimitsDialog extends StatefulWidget {
  const _LimitsDialog({required this.initial});

  final Set<Limitation> initial;

  @override
  State<_LimitsDialog> createState() => _LimitsDialogState();
}

class _LimitsDialogState extends State<_LimitsDialog> {
  late final _picked = Set.of(widget.initial);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Go easy on'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final l in Limitation.values)
          CheckboxListTile(
            value: _picked.contains(l),
            title: Text(l.label),
            activeColor: AppColors.pink,
            onChanged: (on) => setState(() => on! ? _picked.add(l) : _picked.remove(l)),
          ),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.pop(context, _picked), child: const Text('Save')),
    ],
  );
}
