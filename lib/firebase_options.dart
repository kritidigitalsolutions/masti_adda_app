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
    apiKey: 'AIzaSyCnP1vZvgzhMyzCRcsKEF0pi7wN3S8-yNE',
    appId: '1:163739706839:web:1fe18af5e37d919f0f1792',
    messagingSenderId: '163739706839',
    projectId: 'masti-adda-f4bdb',
    authDomain: 'masti-adda-f4bdb.firebaseapp.com',
    storageBucket: 'masti-adda-f4bdb.firebasestorage.app',
    measurementId: 'G-6GY2TN93JV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBjpkOiw8RebHvN_pInr560y1UmK5N5TC4',
    appId: '1:163739706839:android:b8020bc231fac0730f1792',
    messagingSenderId: '163739706839',
    projectId: 'masti-adda-f4bdb',
    storageBucket: 'masti-adda-f4bdb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBjpkOiw8RebHvN_pInr560y1UmK5N5TC4',
    appId: '1:163739706839:android:b8020bc231fac0730f1792',
    messagingSenderId: '163739706839',
    projectId: 'masti-adda-f4bdb',
    storageBucket: 'masti-adda-f4bdb.firebasestorage.app',
  );
}
