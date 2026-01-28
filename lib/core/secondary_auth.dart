import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart'; // flutterfire configure ile oluşan dosya

class AuthChannels {
  static FirebaseApp? secondaryApp;
  static FirebaseAuth? secondaryAuth;

  static Future<void> init() async {
    // Varsayılan app (genelde zaten başlatılmıştır, tekrar çağrı sorun değil)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // İkincil app (admin oturumunu bozmadan ayrı bir Auth kanalı)
    secondaryApp ??= await Firebase.initializeApp(
      name: 'admin-helper-app',
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // İkincil app için ayrı Auth instance
    secondaryAuth ??= FirebaseAuth.instanceFor(app: secondaryApp!);
  }
}