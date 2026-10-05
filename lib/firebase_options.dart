import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC1IIV8KUw2SuVdrN2SvWwE94MGixeSmnY',
    appId: '1:807853365926:web:d4346503b77b59f1207267',
    messagingSenderId: '807853365926',
    projectId: 'masti-adda',
    authDomain: 'masti-adda.firebaseapp.com',
    storageBucket: 'masti-adda.firebasestorage.app',
    measurementId: 'G-DNE0L66MV9',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDuyBfZn_nR8RvX_yz3oBQTNEzkA-9hQ2Q',
    appId: '1:807853365926:android:5a31c9fc9c35d64f207267',
    messagingSenderId: '807853365926',
    projectId: 'masti-adda',
    storageBucket: 'masti-adda.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDuyBfZn_nR8RvX_yz3oBQTNEzkA-9hQ2Q',
    appId: '1:807853365926:ios:5a31c9fc9c35d64f207267',
    messagingSenderId: '807853365926',
    projectId: 'masti-adda',
    storageBucket: 'masti-adda.firebasestorage.app',
  );
}
