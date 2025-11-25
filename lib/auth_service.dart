import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn.instance;

  Future<User?> signInWithGoogle() async {
    await _googleSignIn?.initialize(
      clientId:
          "726676382628-cqjt5slq0jhfs008dugsvhpuk9l6r2hv.apps.googleusercontent.com",
    );

    if (kIsWeb) {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      UserCredential userCredential = await _auth.signInWithPopup(
        googleProvider,
      );
      return userCredential.user;
    } else {
      try {
        final GoogleSignInAccount googleUser = await _googleSignIn!
            .authenticate();

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final GoogleSignInAuthorizationClient authorizationClient =
            googleUser.authorizationClient;

        GoogleSignInClientAuthorization? authorization =
            await authorizationClient.authorizationForScopes([
              'email',
              'profile',
            ]);

        final accessToken = authorization?.accessToken;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );
        return userCredential.user;
      } on FirebaseAuthException catch (e) {
        debugPrint("Firebase Auth Error: ${e.message}");
        return null;
      } catch (e) {
        debugPrint(
          "Google Sign-In Error: Unable to complete sign-in. Please try again.",
        );
        return null;
      }
    }
  }

  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint("Registration Error: $e");
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint("Sign-In Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn?.signOut();
    }
    await _auth.signOut();
  }

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint("Password Reset Error: $e");
      rethrow;
    }
  }
}
