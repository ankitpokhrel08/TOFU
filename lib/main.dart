import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_root.dart';
import 'data/auth.dart';
import 'data/repository.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'tracking/camera_tracker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts ship in assets/google_fonts; never hit the network for them.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final (pkg, file) in [('Nunito', 'OFL-Nunito'), ('Baloo 2', 'OFL-Baloo2')]) {
      final text = await rootBundle.loadString('assets/google_fonts/$file.txt');
      yield LicenseEntryWithLineBreaks([pkg], text);
    }
  });
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Cache data on the device so training works offline and syncs later.
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  runApp(
    TofuApp(
      root: AppRoot(
        auth: FirebaseAuthService(),
        repositoryFor: FirestoreRepository.new,
        trackerFactory: CameraTracker.new,
      ),
    ),
  );
}

class TofuApp extends StatelessWidget {
  const TofuApp({super.key, required this.root});

  final Widget root;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOFU',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: AnnotatedRegion(value: SystemUiOverlayStyle.dark, child: root),
    );
  }
}
