import 'package:flutter_test/flutter_test.dart';
import 'package:gym_guru/audio/coach.dart';
import 'package:gym_guru/audio/workout_announcer.dart';
import 'package:gym_guru/game/exercises.dart';
import 'package:gym_guru/game/levels.dart';
import 'package:gym_guru/tracking/tracker.dart';

/// Records what the coach would say and play, on a controllable clock.
class Recorder {
  final said = <String>[];
  final played = <Sfx>[];
  var now = DateTime(2026, 11, 14, 9);

  late final coach = Coach(speak: said.add, playSound: played.add, clock: () => now);

  void wait(Duration d) => now = now.add(d);
}

/// A tracker the test drives by hand.
class FakeTracker extends WorkoutTracker {
  FakeTracker(super.blocks) : super(countdownStep: const Duration(milliseconds: 1));

  @override
  bool get simulated => true;

  @override
  Future<void> start() async => setPhase(TrackerPhase.intro);

  void checksPass() => reportChecks(const [true, true, true]);
  void rep([FormIssue? issue]) => reportRep(issue);
  void live(FormIssue? issue) => reportLive(progress: .5, issue: issue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Coach rate limiting', () {
    test('the same line waits for its cooldown', () {
      final r = Recorder();
      expect(r.coach.say('Knees out', key: 'k'), isTrue);
      r.wait(const Duration(seconds: 5));
      expect(r.coach.say('Knees out', key: 'k'), isFalse);
      r.wait(const Duration(seconds: 4));
      expect(r.coach.say('Knees out', key: 'k'), isTrue);
    });

    test('different lines keep a gap between them', () {
      final r = Recorder();
      r.coach.say('One');
      r.wait(const Duration(seconds: 1));
      expect(r.coach.say('Two'), isFalse);
      r.wait(const Duration(seconds: 3));
      expect(r.coach.say('Two'), isTrue);
    });

    test('urgent lines skip the gap', () {
      final r = Recorder();
      r.coach.say('One');
      expect(r.coach.say('Next exercise', urgent: true), isTrue);
    });

    test('settings mute voice and sounds separately', () {
      final r = Recorder();
      r.coach
        ..voice = false
        ..sounds = true;
      r.coach.say('Hello', urgent: true);
      r.coach.play(Sfx.rep);
      expect(r.said, isEmpty);
      expect(r.played, [Sfx.rep]);
      r.coach.sounds = false;
      r.coach.play(Sfx.rep);
      expect(r.played, hasLength(1));
    });
  });

  group('WorkoutAnnouncer', () {
    late Recorder r;
    late FakeTracker t;
    late WorkoutAnnouncer a;

    setUp(() async {
      r = Recorder();
      t = FakeTracker(const [Block(Exercise.squat, 8), Block(Exercise.gluteBridge, 8)]);
      a = WorkoutAnnouncer(r.coach);
      await t.start();
      a.update(t);
    });

    tearDown(() => t.dispose());

    test('announces each exercise with how to stand', () {
      expect(r.said.single, contains('First up: 8 squats'));
      expect(r.said.single, contains('Face the camera'));
    });

    /// Intro → calibrated → countdown → counting.
    Future<void> startCounting() async {
      t
        ..confirmIntro()
        ..checksPass();
      a.update(t);
      while (t.phase != TrackerPhase.workout) {
        await Future<void>.delayed(const Duration(milliseconds: 2));
        a.update(t);
      }
    }

    test('countdown ticks, then a go sound', () async {
      await startCounting();
      expect(r.played.where((s) => s == Sfx.tick), isNotEmpty);
      expect(r.played.last, Sfx.go);
    });

    test('a form problem is spoken once, not every frame', () async {
      await startCounting();
      final before = r.said.length;
      for (var i = 0; i < 20; i++) {
        t.live(FormIssue.kneesIn);
        a.update(t);
        t.live(null);
        a.update(t);
        r.wait(const Duration(milliseconds: 200));
      }
      // 4 seconds of flickering: inside the 8-second cooldown.
      expect(r.said.length, before + 1);
      expect(r.said.last, FormIssue.kneesIn.cue);
    });

    test('clean reps get a sound; bad reps are spoken', () async {
      await startCounting();
      t.rep();
      a.update(t);
      expect(r.played.last, Sfx.rep);
      r.wait(const Duration(seconds: 10));
      t.rep(FormIssue.shallow);
      a.update(t);
      expect(r.said.last, FormIssue.shallow.cue);
    });

    test('says "three more" once, then chimes and announces the next exercise', () async {
      await startCounting();
      for (var i = 0; i < 8; i++) {
        r.wait(const Duration(seconds: 4));
        t.rep();
        a.update(t);
      }
      expect(r.said.where((s) => s == 'Three more!'), hasLength(1));
      expect(t.phase, TrackerPhase.intro);
      expect(r.played, contains(Sfx.blockDone));
      expect(r.said.last, contains('Next: 8 bridges'));
      expect(r.said.last, contains('side-on'));
    });

    test('spoken labels read naturally for holds', () {
      expect(WorkoutAnnouncer.spokenLabel(const Block(Exercise.plank, 20)), 'a 20 second plank');
      expect(WorkoutAnnouncer.spokenLabel(const Block(Exercise.squat, 8)), '8 squats');
    });
  });
}
