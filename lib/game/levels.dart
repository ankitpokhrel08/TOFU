import 'exercises.dart';

/// One exercise in a workout: reps, or seconds for timed holds.
class Block {
  const Block(this.exercise, this.target);

  final Exercise exercise;
  final int target;

  /// Graded units: reps, or 5-second segments for holds.
  int get units => exercise.timed ? (target / Exercise.holdSegment).ceil() : target;

  String get label =>
      exercise.timed ? '${exercise.label} ${target}s' : '$target ${exercise.plural}';
}

class GameLevel {
  const GameLevel(this.number, this.title, this.blocks, {this.boss = false, this.passForm = 60});

  final int number;
  final String title;
  final List<Block> blocks;

  /// Boss levels close each unit: longer, stricter, double XP.
  final bool boss;

  /// Minimum form score to pass (earn 1 star).
  final int passForm;

  int get unit => (number - 1) ~/ levelsPerUnit + 1;
}

const levelsPerUnit = 5;

const unitNames = ['Foundations', 'Control', 'Strength', 'Endurance'];

const _sq = Exercise.squat;
const _br = Exercise.gluteBridge;
const _pu = Exercise.pushUp;
const _pl = Exercise.plank;
const _lu = Exercise.reverseLunge;
const _jj = Exercise.jumpingJack;

/// The 20-level path. New exercises arrive unit by unit.
const gameLevels = [
  // Unit 1 · Foundations: squat, glute bridge.
  GameLevel(1, 'First steps', [Block(_sq, 8), Block(_br, 8)]),
  GameLevel(2, 'Find your depth', [Block(_sq, 10), Block(_br, 10)]),
  GameLevel(3, 'Steady base', [Block(_sq, 12), Block(_br, 10)]),
  GameLevel(4, 'Glute power', [Block(_br, 15), Block(_sq, 10)]),
  GameLevel(5, 'Foundations test', [Block(_sq, 15), Block(_br, 15)], boss: true, passForm: 75),
  // Unit 2 · Control: push-up, plank.
  GameLevel(6, 'Push-up intro', [Block(_sq, 10), Block(_pu, 5), Block(_pl, 15)]),
  GameLevel(7, 'Hold strong', [Block(_pu, 6), Block(_pl, 20), Block(_br, 12)]),
  GameLevel(8, 'Core control', [Block(_sq, 12), Block(_pl, 25), Block(_pu, 6)]),
  GameLevel(9, 'Upper body', [Block(_pu, 8), Block(_pl, 30), Block(_sq, 12)]),
  GameLevel(
    10,
    'Control test',
    [Block(_sq, 15), Block(_pu, 10), Block(_pl, 40)],
    boss: true,
    passForm: 75,
  ),
  // Unit 3 · Strength: reverse lunge.
  GameLevel(11, 'Lunge intro', [Block(_lu, 8), Block(_sq, 12), Block(_pl, 30)]),
  GameLevel(12, 'Balance', [Block(_lu, 10), Block(_pu, 8), Block(_br, 15)]),
  GameLevel(13, 'Leg day', [Block(_sq, 15), Block(_lu, 12), Block(_br, 15)]),
  GameLevel(14, 'Full body', [Block(_pu, 10), Block(_lu, 12), Block(_pl, 40)]),
  GameLevel(
    15,
    'Strength test',
    [Block(_sq, 18), Block(_lu, 14), Block(_pu, 12), Block(_pl, 45)],
    boss: true,
    passForm: 80,
  ),
  // Unit 4 · Endurance: jumping jacks.
  GameLevel(16, 'Cardio spark', [Block(_jj, 20), Block(_sq, 15), Block(_pl, 40)]),
  GameLevel(17, 'Burner', [Block(_jj, 25), Block(_pu, 12), Block(_lu, 12)]),
  GameLevel(18, 'Engine', [Block(_jj, 30), Block(_sq, 20), Block(_br, 20)]),
  GameLevel(19, 'Gauntlet', [Block(_jj, 30), Block(_pu, 15), Block(_lu, 16), Block(_pl, 50)]),
  GameLevel(
    20,
    'Legend test',
    [Block(_jj, 40), Block(_sq, 25), Block(_pu, 15), Block(_lu, 16), Block(_pl, 60)],
    boss: true,
    passForm: 85,
  ),
];

GameLevel levelByNumber(int n) => gameLevels[n - 1];

/// Swap or soften moves that clash with the user's limitations.
List<Block> adaptBlocks(List<Block> blocks, Set<Limitation> limits) {
  final knees = limits.contains(Limitation.knees);
  final back = limits.contains(Limitation.back);
  return [
    for (final b in blocks)
      switch (b.exercise) {
        // Lunges and jumping are hard on sore knees: bridges load the hips instead.
        Exercise.reverseLunge || Exercise.jumpingJack when knees => Block(_br, b.target),
        Exercise.squat when knees => Block(_sq, (b.target * .8).round()),
        // Shorter holds protect a sore lower back.
        Exercise.plank when back => Block(_pl, (b.target * .7 / 5).round() * 5),
        _ => b,
      },
  ];
}

/// First level for each experience.
int startLevelFor(String experience) => switch (experience) {
  'intermediate' => 6,
  'advanced' => 11,
  _ => 1,
};

/// Exercises introduced up to and including [level].
Set<Exercise> exercisesUnlockedBy(int level) => {
  for (final l in gameLevels.take(level))
    for (final b in l.blocks) b.exercise,
};
