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
    apiKey: 'AIzaSyCK58XBPxi7Bc2iaxKwwYlaMHf1R8T85Ek',
    appId: '1:972154992772:web:7535d4b6ed240a766caad1',
    messagingSenderId: '972154992772',
    projectId: 'gerenciamento-de-cacambas',
    authDomain: 'gerenciamento-de-cacambas.firebaseapp.com',
    storageBucket: 'gerenciamento-de-cacambas.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCK58XBPxi7Bc2iaxKwwYlaMHf1R8T85Ek',
    appId: '1:972154992772:android:afe3aafca61690dd6caad1',
    messagingSenderId: '972154992772',
    projectId: 'gerenciamento-de-cacambas',
    storageBucket: 'gerenciamento-de-cacambas.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCK58XBPxi7Bc2iaxKwwYlaMHf1R8T85Ek',
    appId: '1:972154992772:ios:7535d4b6ed240a766caad1',
    messagingSenderId: '972154992772',
    projectId: 'gerenciamento-de-cacambas',
    storageBucket: 'gerenciamento-de-cacambas.firebasestorage.app',
    iosBundleId: 'com.example.appMotorista',
  );
}
