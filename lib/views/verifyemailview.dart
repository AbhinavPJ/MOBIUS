import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0, 23, 45, 1),
              Color.fromRGBO(0, 82, 162, 1),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                ),
                const SizedBox(width: 10),
                const Text(
                  "MOBIUS",
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Verification Message
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "Please verify your email address.\nCheck your inbox and click the verification link.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Send Verification Email Button
            _buildButton1(
                "Resend Verification Email", Colors.white, Colors.black,
                () async {
              final user = FirebaseAuth.instance.currentUser;
              print(user);
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("You are not logged in."),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                await user.sendEmailVerification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Verification email sent! Check your inbox."),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }),

            const SizedBox(height: 20),

            // Go to Login Button
            _buildButton2("Go to Login", Colors.white, Colors.black, () {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildButton1(
      String text, Color bgColor, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: 270,
      height: 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildButton2(
      String text, Color bgColor, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: 150,
      height: 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
