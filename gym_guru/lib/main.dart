import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'onboarding/onboarding_flow.dart';
import 'theme/app_theme.dart';

void main() {
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
  runApp(const GymGuruApp());
}

class GymGuruApp extends StatelessWidget {
  const GymGuruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Guru',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AnnotatedRegion(value: SystemUiOverlayStyle.dark, child: OnboardingFlow()),
    );
  }
}
