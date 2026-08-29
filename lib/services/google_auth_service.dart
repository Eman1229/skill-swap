import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Signs in with Google and ensures every authenticated user has a profile.
///
/// Firebase handles the browser popup on web. Android uses the native Google
/// account chooser supplied by `google_sign_in`.
class GoogleAuthService {
  GoogleAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Future<GoogleSignInResult?> signIn() async {
    UserCredential credential;

    if (kIsWeb) {
      credential = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } on PlatformException catch (error) {
        if (error.code == 'sign_in_canceled' ||
            error.message?.contains('12501') == true) {
          return null;
        }
        if (error.message?.contains('ApiException: 10') == true) {
          throw const GoogleAuthException(
            code: 'android-oauth-not-configured',
            message:
                'Google Sign-In is not configured for this Android build. '
                'Add this app\'s SHA-1 and SHA-256 fingerprints in Firebase, '
                'then download a new google-services.json.',
          );
        }
        throw GoogleAuthException(
          code: error.code,
          message: error.message ?? 'Google Sign-In could not be started.',
        );
      }
      // Dismissing the account chooser is expected user cancellation.
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final oauthCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      credential = await _auth.signInWithCredential(oauthCredential);
    }

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google did not return a user account.',
      );
    }

    final profile = _firestore.collection('users').doc(user.uid);
    final existingProfile = await profile.get();
    final isNewUser = credential.additionalUserInfo?.isNewUser == true ||
        !existingProfile.exists;

    if (isNewUser) {
      await profile.set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return GoogleSignInResult(isNewUser: isNewUser);
  }
}

class GoogleSignInResult {
  const GoogleSignInResult({required this.isNewUser});

  final bool isNewUser;
}

class GoogleAuthException implements Exception {
  const GoogleAuthException({required this.code, required this.message});

  final String code;
  final String message;
}
