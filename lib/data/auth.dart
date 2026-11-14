import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AppUser {
  const AppUser({required this.uid, this.displayName, this.email});
  final String uid;
  final String? displayName;
  final String? email;

  /// First word of the Google display name, for prefilling setup.
  String get firstName => (displayName ?? '').trim().split(RegExp(r'\s+')).first;
}

/// Thrown when the user backs out of the Google account picker.
class SignInCancelled implements Exception {}

abstract class AuthService {
  AppUser? get currentUser;
  Stream<AppUser?> get changes;

  /// Null-safe: throws [SignInCancelled] if the user cancels.
  Future<AppUser> signInWithGoogle();
  Future<void> signOut();

  /// Deletes the Firebase account. May ask the user to pick their Google
  /// account again, since deletion needs a recent sign-in.
  Future<void> deleteAccount();
}

/// Google sign-in through Firebase Auth.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  Future<void>? _init;

  Future<void> _ensureInit() => _init ??= GoogleSignIn.instance.initialize();

  static AppUser? _map(User? u) =>
      u == null ? null : AppUser(uid: u.uid, displayName: u.displayName, email: u.email);

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AppUser?> get changes => _auth.authStateChanges().map(_map);

  Future<AuthCredential> _googleCredential() async {
    await _ensureInit();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return GoogleAuthProvider.credential(idToken: account.authentication.idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw SignInCancelled();
      rethrow;
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final cred = await _auth.signInWithCredential(await _googleCredential());
    return _map(cred.user)!;
  }

  @override
  Future<void> signOut() async {
    await _ensureInit();
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      await user.reauthenticateWithCredential(await _googleCredential());
      await user.delete();
    }
    await GoogleSignIn.instance.signOut();
  }
}
