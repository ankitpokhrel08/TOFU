/// How the user should stand relative to the phone.
enum CameraView { front, side }

/// Form problems the analyzers can flag.
enum FormIssue {
  kneesIn('Knees caved in', 'Push knees out over your toes', 'Knees caving in! Push them out'),
  shallow('Too shallow', 'Hips should reach knee height', 'Go lower: hips to knee height'),
  halfRep('Half rep', 'Lower until your elbows reach 90°', 'Lower: chest toward the floor'),
  hipSag('Hips sagging', 'Brace your core to keep a straight line', 'Hips up, squeeze your core'),
  hipPike('Hips too high', 'Lower your hips into a straight line', 'Drop your hips into line'),
  lungeShallow(
    'Shallow lunge',
    'Lower until your front thigh is near parallel',
    'Deeper: back knee to the floor',
  ),
  torsoLean('Leaning forward', 'Keep your chest tall over your hips', 'Chest up, stay tall'),
  lowBridge(
    'Hips not fully up',
    'Squeeze glutes until hips line up with knees',
    'Higher! Squeeze your glutes',
  ),
  shortRange(
    'Partial jack',
    'Arms overhead and feet wide every rep',
    'Full range: arms up, feet wide',
  );

  const FormIssue(this.title, this.tip, this.cue);

  /// Shown on the results screen.
  final String title;
  final String tip;

  /// Shown live during the set.
  final String cue;
}

/// Exercises the camera can track and grade.
enum Exercise {
  squat(
    'Squat',
    'squats',
    CameraView.front,
    cues: [
      ('Hips to knee height', 'Thighs parallel to the floor'),
      ('Knees track over toes', 'No caving inward'),
      ('Chest proud', 'Keep your torso tall'),
    ],
    issues: [FormIssue.kneesIn, FormIssue.shallow],
  ),
  gluteBridge(
    'Glute bridge',
    'bridges',
    CameraView.side,
    cues: [
      ('Lie on your back', 'Knees bent, feet flat, side-on to the phone'),
      ('Drive through heels', 'Lift hips until shoulders, hips and knees line up'),
      ('Squeeze at the top', 'Pause for a moment, then lower slowly'),
    ],
    issues: [FormIssue.lowBridge],
  ),
  pushUp(
    'Push-up',
    'push-ups',
    CameraView.side,
    cues: [
      ('Straight line', 'Head, hips and heels in one line'),
      ('Elbows to 90°', 'Chest close to the floor'),
      ('Hands under shoulders', 'Knees down is fine while you build up'),
    ],
    issues: [FormIssue.halfRep, FormIssue.hipSag, FormIssue.hipPike],
  ),
  plank(
    'Plank',
    'plank',
    CameraView.side,
    timed: true,
    cues: [
      ('Forearms under shoulders', 'Side-on to the phone'),
      ('Straight line', 'No sagging or piking hips'),
      ('Breathe', 'Brace your core and keep breathing'),
    ],
    issues: [FormIssue.hipSag, FormIssue.hipPike],
  ),
  reverseLunge(
    'Reverse lunge',
    'lunges',
    CameraView.side,
    cues: [
      ('Step back', 'Long step, back knee toward the floor'),
      ('Front knee over ankle', 'Front thigh near parallel'),
      ('Stay tall', 'Chest up, torso over hips'),
    ],
    issues: [FormIssue.lungeShallow, FormIssue.torsoLean],
  ),
  jumpingJack(
    'Jumping jacks',
    'jacks',
    CameraView.front,
    cues: [
      ('Arms overhead', 'Hands meet above your head'),
      ('Feet wide', 'Wider than your shoulders'),
      ('Land soft', 'Stay light on the balls of your feet'),
    ],
    issues: [FormIssue.shortRange],
  );

  const Exercise(
    this.label,
    this.plural,
    this.view, {
    this.timed = false,
    required this.cues,
    required this.issues,
  });

  final String label;
  final String plural;
  final CameraView view;

  /// Held for time (seconds) instead of counted in reps.
  final bool timed;

  /// Three coaching cues shown before the set.
  final List<(String, String)> cues;

  /// Issues this exercise can flag, most important first.
  final List<FormIssue> issues;

  /// What must be visible to track: both sides only when both arms and
  /// legs are judged (jumping jacks). Everything else works with one full
  /// side, which also survives knees hiding each other at the bottom of a
  /// squat.
  CameraView get trackingView => this == Exercise.jumpingJack ? CameraView.front : CameraView.side;

  String get setupHint => switch (this) {
    Exercise.squat => 'Face the camera or stand side-on, whole body in frame',
    _ when view == CameraView.front => 'Face the camera, whole body in frame',
    _ => 'Turn side-on to the camera',
  };

  /// Seconds per graded segment for timed holds.
  static const holdSegment = 5;
}

/// Areas the user wants to protect.
enum Limitation {
  knees('Knees'),
  back('Lower back');

  const Limitation(this.label);
  final String label;
}
