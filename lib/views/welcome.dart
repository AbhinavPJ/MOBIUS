import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            // Mobius Logo
            Row(
              mainAxisSize:
                  MainAxisSize.min, // Ensures only needed space is used
              children: [
                Image.asset(
                  'assets/images/logo.png', // Replace with your logo path
                  height: 130, // Adjust size as needed
                ),
                const SizedBox(width: 10), // Add spacing
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
            const SizedBox(height: 200), // Space before the next column item

            // Terms and Policies Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: const Text(
                "By tapping 'Create account' or 'Sign in', you agree to our Terms. Learn how we process your data in our Privacy Policy and Cookies Policy.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Buttons
            _buildButton1(
                "Create account", Colors.white, Colors.black, context),
            const SizedBox(height: 10),
            _buildButton2("Login", Colors.white, Colors.black, context),

            const SizedBox(height: 20),

            // Trouble Signing In
            const Text(
              "Trouble signing in?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton1(
      String text, Color bgColor, Color textColor, BuildContext context) {
    return SizedBox(
      width: 180,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/register');
        },
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
      String text, Color bgColor, Color textColor, BuildContext context) {
    return SizedBox(
      width: 150,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/login');
        },
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
