import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDU33dgM5XcKEquBmTH2wTLfDzSaQjG0PQ',
    appId: '1:928234105384:web:26d9585573231d48fea31d',
    messagingSenderId: '928234105384',
    projectId: 'snapcircle-41ca8',
    authDomain: 'snapcircle-41ca8.firebaseapp.com',
    storageBucket: 'snapcircle-41ca8.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDU33dgM5XcKEquBmTH2wTLfDzSaQjG0PQ',
    appId: '1:928234105384:android:26d9585573231d48fea31d',
    messagingSenderId: '928234105384',
    projectId: 'snapcircle-41ca8',
    storageBucket: 'snapcircle-41ca8.firebasestorage.app',
  );
}
