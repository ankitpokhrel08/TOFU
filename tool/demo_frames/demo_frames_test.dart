// Renders frames of each exercise animation's loop to PNGs for review.
//
//   OUT=/tmp/frames flutter test tool/demo_frames
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

const _loops = {
  'squat': .28,
  'push_up': 1.0,
  'plank': 1.0,
  'reverse_lunge': 1.0,
  'glute_bridge': 1.0,
  'jumping_jack': 1.0,
};

void main() {
  final out = Platform.environment['OUT'];

  testWidgets('render demo frames', (tester) async {
    if (out == null) return markTestSkipped('Set OUT to a folder.');
    Directory(out).createSync(recursive: true);
    for (final MapEntry(key: name, value: end) in _loops.entries) {
      final comp = (await tester.runAsync(
        () async =>
            LottieComposition.fromByteData(await rootBundle.load('assets/exercises/$name.json')),
      ))!;
      for (var k = 0; k < 6; k++) {
        final key = GlobalKey();
        await tester.pumpWidget(
          Center(
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: Colors.white,
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Lottie(
                    composition: comp,
                    animate: false,
                    frameRate: FrameRate.max,
                    controller: AlwaysStoppedAnimation(end * k / 5),
                  ),
                ),
              ),
            ),
          ),
        );
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final img = await boundary.toImage();
          return (await img.toByteData(format: ui.ImageByteFormat.png))!;
        });
        File('$out/${name}_$k.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      }
    }
  });
}
