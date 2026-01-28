import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/super_admin_home_page.dart';
import 'firebase_options.dart';
import 'features/login_page.dart';
import 'features/signup_page.dart';
import 'features/home_page.dart';
import 'features/guest_home_page.dart';
import 'features/anonymous_home_page.dart';
import 'features/home_menu_page.dart';
import 'core/secondary_auth.dart';
import 'dart:async';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Arka planda bildirim geldi: ${message.notification?.title}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'default_channel',
  'Genel Bildirimler',
  description: 'Uygulama bildirimleri için varsayılan kanal',
  importance: Importance.high,
);

StreamSubscription<RemoteMessage>? _foregroundSub;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AuthChannels.init();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const ProviderScope(child: MTUBilgiMobilApp()));
}

class MTUBilgiMobilApp extends StatelessWidget {
  const MTUBilgiMobilApp({super.key});

  Future<Widget> _determineHome() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      // 🔹 Varsayılan: anonim ekran
      return const HomeMenuPage(role: "anonymous", department: "Misafir");
    } else {
      // 🔹 Normal kullanıcı → Firestore’dan role ve department çek
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final role = doc.data()?['role'] ?? "student";
      final department = doc.data()?['department'] ?? "Genel";

      return HomeMenuPage(role: role, department: department);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTÜ Bilgi Mobil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      home: FutureBuilder<Widget>(
        future: _determineHome(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text("Bir hata oluştu")),
            );
          }
          return snapshot.data!;
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/guestHome': (context) => const GuestHomePage(),
        '/superAdminHome': (context) => const SuperAdminHomePage(),
        // 🔹 Burada pageType parametresi eklendi
        '/anonymousHome': (context) =>
        const AnonymousHomePage(pageType: "announcements"),
        '/menu': (context) =>
        const HomeMenuPage(role: "anonymous", department: "Misafir"),
      },
    );
  }
}

void _setupForegroundNotificationsForNonAnonymous(User user, String role) {
  if (role == "anonymous" || user.isAnonymous) {
    print("ℹ️ Anonim için foreground bildirim dinleyicisi devre dışı");
    _foregroundSub?.cancel();
    _foregroundSub = null;
    return;
  }

  _foregroundSub ??= FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground bildirim: ${message.notification?.title}");
    if (message.notification != null) {
      _showLocalNotification(
        message.notification!.title,
        message.notification!.body,
      );
    }
  });
}

Future<void> saveTokenToFirestore(String uid) async {
  final userDoc =
  await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final role = userDoc.data()?['role'] ?? "student";

  if (role == "anonymous") {
    print("ℹ️ Anonymous kullanıcı için FCM token kaydedilmiyor");
    return;
  }

  String? token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
    print("FCM Token kaydedildi: $token");
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcmToken': newToken},
      SetOptions(merge: true),
    );
    print("FCM Token yenilendi: $newToken");
  });
}

Future<void> _showLocalNotification(String? title, String? body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'default_channel',
    'Genel Bildirimler',
    channelDescription: 'Uygulama bildirimleri için varsayılan kanal',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails =
  NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    title ?? 'Yeni Bildirim',
    body ?? '',
    platformDetails,
  );
}