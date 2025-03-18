import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0, 0, 0, 1),
              Color.fromRGBO(10, 10, 10, 1),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "MOBIUS",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 179, 255, 0),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Swipe. Match. Meet. Exclusively for IITD.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40), // Increased spacing

            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    _buildTextField(_email, "Enter email", false),
                    const SizedBox(height: 20), // Increased spacing
                    _buildTextField(_password, "Enter password", true),
                    const SizedBox(height: 30), // Increased spacing
                    _buildButton(
                        "Register", Colors.white, Colors.black, _registerUser),
                    const SizedBox(height: 20), // Increased spacing
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: const Text(
                        "Already Registered? Login Here",
                        style: TextStyle(
                          color: Color.fromARGB(255, 179, 255, 80),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerUser() async {
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("All fields are required");
      return;
    }

    if (email.endsWith("iitd.ac.in")) {
      _showError("Do not use IIT-Delhi email");
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      final uid = user.uid;

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "uid": uid,
        "email": email,
        "created_at": FieldValue.serverTimestamp(),
      });

      if (!user.emailVerified) {
        Future.delayed(const Duration(seconds: 2), () async {
          await _sendVerificationEmail(user);
        });
      }

      print("User Registered & Data Saved Successfully!");

      // Ensure navigation happens immediately after registration
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/verify', (route) => false);
    } on FirebaseAuthException catch (e) {
      _showError(e.code);
    }
  }

  Future<void> _sendVerificationEmail(User user) async {
    try {
      // Check if user is still not verified
      await user.reload();
      if (user.emailVerified) {
        return; // No need to send another verification email
      }

      await user.sendEmailVerification();
      print("Verification email sent successfully.");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        _showError("Too many requests. Try again later.");
      } else {
        _showError("Error sending verification email: ${e.message}");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hintText, bool isPassword) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: TextField(
        enableSuggestions: false,
        autocorrect: false,
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
      String text, Color bgColor, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: 200,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
