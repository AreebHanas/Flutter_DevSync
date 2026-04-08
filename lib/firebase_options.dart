// IMPORTANT: This file is a placeholder.
// You MUST run `flutterfire configure` to generate the real version of this file
// from your own Firebase project. Follow the steps in README.md.
//
// Command: flutterfire configure --project=<your-firebase-project-id>
//
// Leave this file in place until you run that command.

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // -----------------------------------------------------------------------
  // REPLACE ALL VALUES BELOW WITH YOUR OWN FROM `flutterfire configure`
  // -----------------------------------------------------------------------

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD7atHYcwgK06P3_kfFbEApDex7pJCDIrQ',
    appId: '1:1098835692511:web:f889f51fe2707f1a39126a',
    messagingSenderId: '1098835692511',
    projectId: 'devsync-19fd9',
    authDomain: 'devsync-19fd9.firebaseapp.com',
    storageBucket: 'devsync-19fd9.firebasestorage.app',
    measurementId: "G-YGV231R00T",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'devsync-19fd9',
    storageBucket: 'devsync-19fd9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'devsync-19fd9',
    storageBucket: 'devsync-19fd9.firebasestorage.app',
    iosBundleId: 'com.example.flutterProjectManagement',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'devsync-19fd9',
    storageBucket: 'devsync-19fd9.firebasestorage.app',
    iosBundleId: 'com.example.flutterProjectManagement',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_WINDOWS_API_KEY',
    appId: 'YOUR_WINDOWS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'devsync-19fd9',
    storageBucket: 'devsync-19fd9.firebasestorage.app',
  );
}
