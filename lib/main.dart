import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/views/register_view.dart';
import 'package:flutter_application_2/views/verifyemailview.dart';
import 'package:flutter_application_2/views/welcome.dart';
import 'firebase_options.dart';
import 'views/survey.dart';
import 'views/loginview.dart';
import 'views/matchmaking.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔹 Background Notification: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase Messaging & Notifications
  await FirebaseApi().initNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      routes: {
        '/login': (context) => const LoginView(),
        '/survey': (context) => const SurveyView(),
        '/matchmaking': (context) => MatchmakingScreen(),
        '/register': (context) => const RegisterView(),
        '/verify': (context) => const VerifyEmailView(),
      },
    );
  }
}

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Step 3: Request Notification Permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ Notification permission granted.");
    } else {
      print("❌ Notification permission denied.");
      return;
    }

    // Step 4: Retrieve & Print FCM Token
    String? fcmToken = await _firebaseMessaging.getToken();
    print("📲 FCM Token: $fcmToken");

    // Save Token to Firestore (Optional)
    if (fcmToken != null) {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? "unknown_user";
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {'fcmToken': fcmToken},
        SetOptions(merge: true),
      );
    }

    // Handle Notifications in Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 Foreground Notification: ${message.notification?.title}");
      // You can show a local notification here if needed
    });

    // Handle Notifications when App is Opened from Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📬 Opened from Background: ${message.notification?.title}");
    });

    // Handle Background Messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          if (!user.emailVerified) {
            user.sendEmailVerification();
            return const VerifyEmailView();
          }

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection("surveys")
                .doc(user.uid)
                .get(),
            builder: (context, surveySnapshot) {
              if (surveySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (surveySnapshot.hasData && surveySnapshot.data!.exists) {
                return MatchmakingScreen();
              } else {
                return const SurveyView();
              }
            },
          );
        }

        return const WelcomeScreen();
      },
    );
  }
}
