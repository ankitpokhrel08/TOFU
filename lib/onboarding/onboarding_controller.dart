import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../game/exercises.dart';

class Goal {
  const Goal(this.id, this.title, this.subtitle, this.planName);
  final String id;
  final String title;
  final String subtitle;
  final String planName;
}

class TimeOption {
  const TimeOption(this.minutes, this.label, {this.recommended = false});
  final int minutes;
  final String label;
  final bool recommended;
}

enum Level {
  beginner('Beginner', 'New'),
  intermediate('Intermediate', 'Mid'),
  advanced('Advanced', 'Adv.');

  const Level(this.label, this.short);
  final String label;
  final String short;
}

const goals = [
  Goal('strength', 'Build strength', 'More push-ups, stronger legs', 'Strength Foundations'),
  Goal('fat', 'Lose fat', 'Efficient sessions that burn', 'Lean & Strong'),
  Goal('posture', 'Fix my posture', 'Undo the desk-day damage', 'Posture Reset'),
  Goal('pain', 'Move without pain', 'Gentle strength for hips and back', 'Pain-Free Movement'),
  Goal('habit', 'Stay consistent', 'Finally make it stick', 'Daily Habit Builder'),
];

String planNameFor(String goal) =>
    goals.firstWhere((g) => g.id == goal, orElse: () => goals.first).planName;

const timeOptions = [
  TimeOption(3, 'Quick spark'),
  TimeOption(5, 'Sweet spot', recommended: true),
  TimeOption(10, 'Committed'),
  TimeOption(15, 'Beast mode'),
];

/// Setup answers. Only what the app uses.
class OnboardingController extends ChangeNotifier {
  OnboardingController({String name = ''}) : _name = name.trim(), _nickname = name.trim();

  String _name;
  String _nickname;
  String _goal = 'strength';
  int _minutes = 5;
  Level _level = Level.beginner;
  final Set<Limitation> _limits = {};

  String get name => _name;
  String get nickname => _nickname;
  String get goal => _goal;
  int get minutes => _minutes;
  Level get level => _level;
  Set<Limitation> get limitations => Set.unmodifiable(_limits);

  String get planName => planNameFor(_goal);

  static bool validNickname(String s) =>
      s.trim().length >= 2 && s.trim().length <= 20 && RegExp(r"^[\w .'-]+$").hasMatch(s.trim());

  bool get namesValid => _name.isNotEmpty && validNickname(_nickname);

  void setName(String v) {
    // Keep the nickname following the name until the user edits it.
    if (_nickname == _name) _nickname = v.trim();
    _name = v.trim();
    notifyListeners();
  }

  void setNickname(String v) {
    _nickname = v.trim();
    notifyListeners();
  }

  void setGoal(String id) {
    _goal = id;
    notifyListeners();
  }

  void setMinutes(int v) {
    _minutes = v;
    notifyListeners();
  }

  void setLevel(Level v) {
    _level = v;
    notifyListeners();
  }

  void toggleLimitation(Limitation l) {
    _limits.contains(l) ? _limits.remove(l) : _limits.add(l);
    notifyListeners();
  }

  void clearLimitations() {
    _limits.clear();
    notifyListeners();
  }

  Profile toProfile(DateTime now) => Profile(
    name: _name,
    nickname: _nickname,
    goal: _goal,
    experience: _level.name,
    minutes: _minutes,
    limitations: Set.of(_limits),
    createdAt: now,
  );
}

/// Navigation callbacks handed to each setup screen.
class FlowNav {
  const FlowNav({required this.next, required this.back, required this.step, required this.total});
  final VoidCallback next;
  final VoidCallback back;

  /// 1-based step, for the progress header.
  final int step;
  final int total;
}
