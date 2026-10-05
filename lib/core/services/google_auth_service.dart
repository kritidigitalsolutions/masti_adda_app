import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  /// Web Client ID from Firebase / Google Cloud Console (client_type: 3 in google-services.json)
  static const String webClientId =
      '807853365926-ad785gcjvkcq1oiusk3sn9uisc586k4q.apps.googleusercontent.com';

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? webClientId : null,
    serverClientId: kIsWeb ? null : webClientId,
    scopes: <String>['email', 'profile', 'openid'],
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Trigger interactive Google Sign-In
  Future<GoogleSignInAccount?> signIn() async {
    try {
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
      } catch (_) {}

      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Get authentication tokens for signed-in account
  Future<GoogleSignInAuthentication?> getAuthentication(
    GoogleSignInAccount account,
  ) async {
    try {
      final auth = await account.authentication;
      debugPrint(
        'Google Auth obtained: idToken length = ${auth.idToken?.length ?? 0}, accessToken length = ${auth.accessToken?.length ?? 0}',
      );
      return auth;
    } catch (e) {
      debugPrint('Google Get Authentication Error: $e');
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out Error: $e');
    }
  }

  /// Disconnect Google account
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Google Disconnect Error: $e');
    }
  }
}
