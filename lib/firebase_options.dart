import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Placeholder Firebase configuration.
///
/// Replace the values in this file with the real configuration generated via
/// `flutterfire configure` before shipping the app.
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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'TODO',
    measurementId: 'TODO',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDkVCQl_6eq1ksnoD8SajX154cxwurMH-0',
    appId: '1:477894684654:android:b9e6067c357bd108fea8ff',
    messagingSenderId: '477894684654',
    projectId: 'tread-runner',
    storageBucket: 'tread-runner.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC1_yv3m1w5PvPgFNzipNtbRUZdT7H8D3Y',
    appId: '1:477894684654:ios:38d15c141ecbd3a1fea8ff',
    messagingSenderId: '477894684654',
    projectId: 'tread-runner',
    storageBucket: 'tread-runner.firebasestorage.app',
    iosBundleId: 'com.hartvig-solutions.tread-runner.RunnerTests',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'TODO',
    storageBucket: 'TODO',
    iosBundleId: 'com.hartvig-solutions.tread-runner',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'TODO',
    storageBucket: 'TODO',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'TODO',
    storageBucket: 'TODO',
  );
}