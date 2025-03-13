import 'package:firebase_core/firebase_core.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
