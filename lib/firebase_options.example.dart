// Template for lib/firebase_options.dart, which is not committed.
//
// Generate the real file for your own Firebase project with:
//   flutterfire configure --platforms=android
// or copy this file to lib/firebase_options.dart and fill in the values
// from your project's settings. See README.md, "Firebase setup".
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('Only Android is configured.');
    }
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.firebasestorage.app',
  );
}
