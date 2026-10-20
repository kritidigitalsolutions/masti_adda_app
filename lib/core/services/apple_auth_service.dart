import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthService {
  static final AppleAuthService _instance = AppleAuthService._internal();
  factory AppleAuthService() => _instance;
  AppleAuthService._internal();

  /// Trigger Sign in with Apple
  Future<AuthorizationCredentialAppleID?> signIn() async {
    try {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
        return credential;
      } else {
        debugPrint("Sign in with Apple is primarily supported on iOS and macOS");
        return null;
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('canceled') ||
          errorStr.contains('cancelled') ||
          errorStr.contains('authorization_error/canceled')) {
        debugPrint('Apple Sign-In cancelled by user.');
        return null;
      }
      debugPrint('Apple Sign-In Error: $e');
      rethrow;
    }
  }
}
