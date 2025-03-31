import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/views/card_provider.dart';
import 'package:flutter_application_2/views/register_view.dart';
import 'package:flutter_application_2/views/verifyemailview.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'views/survey.dart';
import 'views/loginview.dart';
import 'views/matchmaking.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CardProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => ChangeNotifierProvider(
              create: (_) => CardProvider(),
              child: FutureBuilder<Map<String, double>>(
                future: MyApp._fetchCoefficients(),
                builder: (context, coefSnapshot) {
                  if (coefSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (coefSnapshot.hasData) {
                    final coefficients = coefSnapshot.data!;
                    return MatchmakingScreen(
                      flag: false,
                      n1: coefficients["n1"]!,
                      n2: coefficients["n2"]!,
                      n3: coefficients["n3"]!,
                      n4: coefficients["n4"]!,
                      n5: coefficients["n5"]!,
                      n6: coefficients["n6"]!,
                      n7: coefficients["n7"]!,
                      n8: coefficients["n8"]!,
                      n9: coefficients["n9"]!,
                      n10: coefficients["n10"]!,
                    );
                  }

                  return const Center(
                      child: Text("Failed to load coefficients"));
                },
              ),
            ),
        '/login': (context) => const LoginView(),
        '/survey': (context) => const SurveyView(),
        '/register': (context) => const RegisterView(),
        '/verify': (context) => const VerifyEmailView(),
      },
    );
  }

  // Static method to fetch coefficients
  static Future<Map<String, double>> _fetchCoefficients() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("coefficients")
          .doc("1")
          .get();

      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

      if (data == null) {
        return _getDefaultCoefficients();
      }

      return {
        "n1": _parseDoubleOrDefault(data["n1"], 0.01),
        "n2": _parseDoubleOrDefault(data["n2"], 20.0),
        "n3": _parseDoubleOrDefault(data["n3"], 20.0),
        "n4": _parseDoubleOrDefault(data["n4"], 5.0),
        "n5": _parseDoubleOrDefault(data["n5"], 10.0),
        "n6": _parseDoubleOrDefault(data["n6"], 5.0),
        "n7": _parseDoubleOrDefault(data["n7"], 15.0),
        "n8": _parseDoubleOrDefault(data["n8"], 15.0),
        "n9": _parseDoubleOrDefault(data["n9"], 15.0),
        "n10": _parseDoubleOrDefault(data["n10"], 15.0),
      };
    } catch (e) {
      print("Error fetching coefficients: $e");
      return _getDefaultCoefficients();
    }
  }

  // Helper method to get default coefficients
  static Map<String, double> _getDefaultCoefficients() {
    return {
      "n1": 0.01,
      "n2": 20.0,
      "n3": 20.0,
      "n4": 5.0,
      "n5": 10.0,
      "n6": 5.0,
      "n7": 15.0,
      "n8": 15.0,
      "n9": 15.0,
      "n10": 15.0,
    };
  }

  // Helper method to parse values safely
  static double _parseDoubleOrDefault(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;

    if (value is num) return value.toDouble();

    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return defaultValue;
      }
    }

    return defaultValue;
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Map<String, double>> _fetchCoefficients() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("coefficients")
          .doc("1")
          .get();

      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

      if (data == null) {
        // Return default values if document doesn't exist or is empty
        return {
          "n1": 0.01,
          "n2": 20.0,
          "n3": 20.0,
          "n4": 5.0,
          "n5": 10.0,
          "n6": 5.0,
          "n7": 15.0,
          "n8": 15.0,
          "n9": 15.0,
          "n10": 15.0,
        };
      }
      print(data);
      return {
        "n1": _parseDoubleOrDefault(data["n1"], 0.01),
        "n2": _parseDoubleOrDefault(data["n2"], 20.0),
        "n3": _parseDoubleOrDefault(data["n3"], 20.0),
        "n4": _parseDoubleOrDefault(data["n4"], 5.0),
        "n5": _parseDoubleOrDefault(data["n5"], 10.0),
        "n6": _parseDoubleOrDefault(data["n6"], 5.0),
        "n7": _parseDoubleOrDefault(data["n7"], 15.0),
        "n8": _parseDoubleOrDefault(data["n8"], 15.0),
        "n9": _parseDoubleOrDefault(data["n9"], 15.0),
        "n10": _parseDoubleOrDefault(data["n10"], 15.0),
      };
    } catch (e) {
      print("Error fetching coefficients: $e");
      // Return default values on error instead of empty map
      return {
        "n1": 0.01,
        "n2": 20.0,
        "n3": 20.0,
        "n4": 5.0,
        "n5": 10.0,
        "n6": 5.0,
        "n7": 15.0,
        "n8": 15.0,
        "n9": 15.0,
        "n10": 15.0,
      };
    }
  }

// Helper method to parse values safely
  double _parseDoubleOrDefault(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;

    if (value is num) return value.toDouble();

    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return defaultValue;
      }
    }

    return defaultValue;
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (context) => CardProvider(),
      child: StreamBuilder<User?>(
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
                  return FutureBuilder<Map<String, double>>(
                    future: _fetchCoefficients(),
                    builder: (context, coefSnapshot) {
                      if (coefSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (coefSnapshot.hasData) {
                        final coefficients = coefSnapshot.data!;
                        return MatchmakingScreen(
                          flag: false,
                          n1: coefficients["n1"]!,
                          n2: coefficients["n2"]!,
                          n3: coefficients["n3"]!,
                          n4: coefficients["n4"]!,
                          n5: coefficients["n5"]!,
                          n6: coefficients["n6"]!,
                          n7: coefficients["n7"]!,
                          n8: coefficients["n8"]!,
                          n9: coefficients["n9"]!,
                          n10: coefficients["n10"]!,
                        );
                      }

                      return const Center(
                          child: Text("Failed to load coefficients"));
                    },
                  );
                } else {
                  return const SurveyView();
                }
              },
            );
          }

          return const RegisterView();
        },
      ));
}
