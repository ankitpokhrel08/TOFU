import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app_controller.dart';
import 'app/main_shell.dart';
import 'data/auth.dart';
import 'data/repository.dart';
import 'game/progression.dart';
import 'onboarding/onboarding_flow.dart';
import 'onboarding/screens/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'tracking/tracker.dart';

typedef RepositoryFactory = Repository Function(String uid);

/// Routes between sign-in, profile setup and the main app.
class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    required this.auth,
    required this.repositoryFor,
    required this.trackerFactory,
    this.clock,
  });

  final AuthService auth;
  final RepositoryFactory repositoryFor;
  final TrackerFactory trackerFactory;
  final DateTime Function()? clock;

  @override
  State<AppRoot> createState() => _AppRootState();
}

enum _Stage { loading, signedOut, setup, ready, failed }

class _AppRootState extends State<AppRoot> {
  _Stage _stage = _Stage.loading;
  AppUser? _user;
  Repository? _repo;
  AppController? _app;
  bool _signingIn = false;
  String? _error;
  StreamSubscription<AppUser?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.auth.changes.listen(_onUser);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _app?.dispose();
    super.dispose();
  }

  Future<void> _onUser(AppUser? user) async {
    if (user?.uid == _user?.uid && _stage != _Stage.loading && _stage != _Stage.failed) return;
    _user = user;
    _app?.dispose();
    _app = null;
    if (user == null) {
      setState(() => _stage = _Stage.signedOut);
      return;
    }
    setState(() => _stage = _Stage.loading);
    await _load();
  }

  Future<void> _load() async {
    final user = _user!;
    final repo = _repo = widget.repositoryFor(user.uid);
    try {
      final data = await repo.load();
      if (!mounted || _user?.uid != user.uid) return;
      if (data.profile == null) {
        setState(() => _stage = _Stage.setup);
        return;
      }
      final app = AppController(repo, data, clock: widget.clock);
      setState(() {
        _app = app;
        _stage = _Stage.ready;
      });
      // Opened from the cache: catch up with the server in the background
      // (another phone may have trained), then settle streak freezes.
      try {
        app.replaceData(await repo.loadFromServer());
      } on Object catch (e) {
        debugPrint('Refreshing from server failed: $e');
      }
      if (!mounted || _app != app) return;
      final froze = await app.applyFreezeIfNeeded();
      if (!mounted) return;
      if (froze) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('You missed yesterday, so a streak freeze kept your streak alive.'),
          ),
        );
      }
    } on Object catch (e) {
      debugPrint('Loading data failed: $e');
      if (mounted) setState(() => _stage = _Stage.failed);
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _signingIn = true;
      _error = null;
    });
    try {
      await widget.auth.signInWithGoogle();
    } on SignInCancelled {
      // User backed out; stay on the welcome screen.
    } on Object catch (e) {
      debugPrint('Sign-in failed: $e');
      _error = "Couldn't sign in. Check your connection and try again.";
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  Future<void> _saveProfile(Profile profile) async {
    await _repo!.saveProfile(
      profile,
      LeaderboardUpdate(
        nickname: profile.nickname,
        xp: 0,
        weeklyXp: 0,
        weekId: weekIdFor(widget.clock?.call() ?? DateTime.now()),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      _Stage.loading => const _Loading(),
      _Stage.failed => _Failed(
        onRetry: () {
          setState(() => _stage = _Stage.loading);
          _load();
        },
        onSignOut: widget.auth.signOut,
      ),
      _Stage.signedOut => WelcomeScreen(onSignIn: _signIn, busy: _signingIn, error: _error),
      _Stage.setup => OnboardingFlow(
        initialName: _user?.firstName ?? '',
        onDone: _saveProfile,
        onExit: widget.auth.signOut,
      ),
      _Stage.ready => MainShell(
        key: ValueKey(_user!.uid),
        app: _app!,
        auth: widget.auth,
        trackerFactory: widget.trackerFactory,
      ),
    };
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator(color: AppColors.pink)),
  );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.onRetry, required this.onSignOut});

  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Image.asset('assets/mascot/laptop.png', width: 140),
            Text("Couldn't load your progress", style: baloo(24), textAlign: TextAlign.center),
            Text(
              'Check your connection and try again.',
              style: nunito(15, weight: FontWeight.w600, color: AppColors.textMuted),
            ),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
            TextButton(onPressed: onSignOut, child: const Text('Sign out')),
          ],
        ),
      ),
    ),
  );
}
