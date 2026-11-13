import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/main_shell.dart';
import 'data/progress_store.dart';
import 'onboarding/onboarding_flow.dart';
import 'theme/app_theme.dart';

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
  final store = await ProgressStore.open();
  runApp(GymGuruApp(store: store));
}

class GymGuruApp extends StatelessWidget {
  const GymGuruApp({super.key, required this.store});

  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Guru',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Returning users skip straight to the app.
      home: AnnotatedRegion(
        value: SystemUiOverlayStyle.dark,
        child: store.profile == null ? OnboardingFlow(store: store) : MainShell(store: store),
      ),
    );
  }
}
