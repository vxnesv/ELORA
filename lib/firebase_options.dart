import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
        'O Firebase da ELORA está configurado para Android, iOS e Web.',
      ),
    };
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAuYrs9YJHs28qkhup3FfNkyzuwoURMlJo',
    appId: '1:719947553194:web:563de176ef43e0399d33d3',
    messagingSenderId: '719947553194',
    projectId: 'elora-85c35',
    authDomain: 'elora-85c35.firebaseapp.com',
    storageBucket: 'elora-85c35.firebasestorage.app',
    measurementId: 'G-PH0ERGG82Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyADUGGEhUPmOa8Fk3LN9_RPQKVLVBonc-U',
    appId: '1:719947553194:android:0dd2150aedcaefff9d33d3',
    messagingSenderId: '719947553194',
    projectId: 'elora-85c35',
    storageBucket: 'elora-85c35.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBN41G8GpmDhwcpH84p3r7mvGtwmFejBCw',
    appId: '1:719947553194:ios:136c2eda303aa7869d33d3',
    messagingSenderId: '719947553194',
    projectId: 'elora-85c35',
    storageBucket: 'elora-85c35.firebasestorage.app',
    iosBundleId: 'br.com.elora.app',
  );
}
