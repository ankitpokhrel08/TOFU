import 'package:flutter/foundation.dart';

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

enum Plan { annual, monthly }

const goals = [
  Goal('strength', 'Build strength', 'Lift more with clean form', 'Strength Foundations'),
  Goal('fat', 'Lose fat', 'Efficient sessions that burn', 'Lean & Strong'),
  Goal('posture', 'Fix my posture', 'Undo the desk-day damage', 'Posture Reset'),
  Goal('pain', 'Move without pain', 'Mobility for knees, hips, back', 'Pain-Free Movement'),
  Goal('habit', 'Stay consistent', 'Finally make it stick', 'Daily Habit Builder'),
];

const timeOptions = [
  TimeOption(3, 'Quick spark'),
  TimeOption(5, 'Sweet spot', recommended: true),
  TimeOption(10, 'Committed'),
  TimeOption(15, 'Beast mode'),
];

const quizCorrect = 'B';

/// Answers collected across the onboarding flow.
class OnboardingController extends ChangeNotifier {
  OnboardingController({this.showAhaTags = true, this.showTrialTimeline = true});

  /// Shows the "AHA #n" labels on the three key value-prop screens.
  final bool showAhaTags;

  /// Shows the trial timeline under the annual plan on the paywall.
  final bool showTrialTimeline;

  final List<String> _goals = ['strength', 'posture'];
  int _minutes = 5;
  Level _level = Level.beginner;
  String? _quizAnswer;
  Plan _plan = Plan.annual;

  List<String> get selectedGoals => List.unmodifiable(_goals);
  int get minutes => _minutes;
  Level get level => _level;
  String? get quizAnswer => _quizAnswer;
  Plan get plan => _plan;

  bool get hasGoals => _goals.isNotEmpty;
  bool get quizAnswered => _quizAnswer != null;
  bool get quizCorrectAnswer => _quizAnswer == quizCorrect;

  /// Named after the first goal the user picked.
  String get planName {
    if (_goals.isEmpty) return goals.first.planName;
    return goals.firstWhere((g) => g.id == _goals.first).planName;
  }

  bool isGoalSelected(String id) => _goals.contains(id);

  void toggleGoal(String id) {
    _goals.contains(id) ? _goals.remove(id) : _goals.add(id);
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

  void answerQuiz(String key) {
    if (_quizAnswer != null) return;
    _quizAnswer = key;
    notifyListeners();
  }

  void setPlan(Plan v) {
    _plan = v;
    notifyListeners();
  }
}

/// Navigation callbacks handed to each screen.
class FlowNav {
  const FlowNav({
    required this.next,
    required this.back,
    required this.restart,
    required this.startTrial,
  });
  final VoidCallback next;
  final VoidCallback back;
  final VoidCallback restart;

  /// Leaves onboarding for the main app once the free trial starts.
  final VoidCallback startTrial;
}
