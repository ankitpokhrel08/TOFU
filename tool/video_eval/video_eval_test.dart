// Runs the real exercise analyzers over pose landmarks extracted from
// videos (see tool/video_eval/README.md).
//
//   POSES=/path/to/poses OUT=/path/to/out flutter test tool/video_eval
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_guru/game/exercises.dart';
import 'package:gym_guru/tracking/analyzers.dart';
import 'package:gym_guru/tracking/pose.dart';

Exercise? _exerciseFor(String name) {
  if (name.startsWith('squat')) return Exercise.squat;
  if (name.startsWith('push-up')) return Exercise.pushUp;
  if (name.startsWith('plank')) return Exercise.plank;
  if (name.startsWith('hip_thrust')) return Exercise.gluteBridge;
  if (name.startsWith('lunge')) return Exercise.reverseLunge;
  if (name.startsWith('jumping')) return Exercise.jumpingJack;
  return null;
}

void main() {
  final dir = Platform.environment['POSES'];
  final out = Platform.environment['OUT'];

  test('evaluate videos', () {
    if (dir == null) {
      markTestSkipped('Set POSES to a folder of extracted pose JSON files.');
      return;
    }
    if (out != null) Directory(out).createSync(recursive: true);
    final files =
        Directory(dir).listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    final rows = <String>[];
    for (final f in files) {
      final j = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final name = j['name'] as String;
      final ex = _exerciseFor(name);
      if (ex == null) continue;
      final size = Size((j['width'] as num).toDouble(), (j['height'] as num).toDouble());
      final analyzer = analyzerFor(ex, const {});
      final setup = SetupChecker(view: ex.trackingView);
      var reps = 0, visible = 0, inPos = 0, frames = 0;
      int? setupPassAt;
      final issues = <FormIssue, int>{};
      final trace = StringBuffer('t,progress,inPosition,visible,rep,issue\n');

      for (final fr in j['frames'] as List) {
        frames++;
        final t = fr['t'] as int;
        final pts = fr['pts'] as Map<String, dynamic>;
        final pose = pts.isEmpty
            ? null
            : PoseSnapshot({
                for (final MapEntry(key: k, value: v) in pts.entries)
                  Joint.values.byName(k): PosePoint(
                    (v[0] as num).toDouble(),
                    (v[1] as num).toDouble(),
                    (v[2] as num).toDouble(),
                  ),
              }, size);
        final checks = setup.update(pose);
        if (setupPassAt == null && checks.every((c) => c)) setupPassAt = t;
        final vis = pose != null && SetupChecker.bodyInFrame(pose, ex.trackingView);
        RepEvent? e;
        if (vis) {
          visible++;
          e = analyzer.update(pose, Duration(milliseconds: t));
          if (analyzer.inPosition) inPos++;
        }
        if (e != null) {
          reps++;
          if (e.issue != null) issues[e.issue!] = (issues[e.issue!] ?? 0) + 1;
        }
        trace.writeln(
          '$t,${analyzer.progress.toStringAsFixed(3)},${analyzer.inPosition ? 1 : 0},${vis ? 1 : 0},'
          '${e == null ? 0 : 1},${e?.issue?.name ?? ''}',
        );
      }
      if (out != null) File('$out/$name.csv').writeAsStringSync(trace.toString());
      final unit = ex.timed ? 'segments' : 'reps';
      rows.add(
        '${name.padRight(14)} ${ex.name.padRight(12)} ${'$reps $unit'.padRight(12)} '
        'visible ${(100 * visible / frames).round()}%  '
        'in-position ${(100 * inPos / frames).round()}%  '
        'setup ${setupPassAt == null ? 'never' : '${(setupPassAt / 1000).toStringAsFixed(1)}s'}  '
        'issues ${issues.isEmpty ? '-' : issues.entries.map((e) => '${e.key.name}×${e.value}').join(' ')}',
      );
    }
    // ignore: avoid_print
    print('\n${rows.join('\n')}\n');
  });
}
