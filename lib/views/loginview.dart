import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(185, 0, 105, 0.949),
              Color.fromRGBO(17, 0, 150, 0.817),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 80),

            // App Logo
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 130,
                ),
                const SizedBox(width: 10),
                const Text(
                  "MOBIUS",
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(223, 214, 168, 0),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 80),

            // Email Field
            _buildTextField(_email, "Enter email", false),
            const SizedBox(height: 10),

            // Password Field
            _buildTextField(_password, "Enter password", true),
            const SizedBox(height: 20),

            // Login Button
            _buildButton1("Login", const Color.fromARGB(255, 203, 0, 85),
                Colors.black, _loginUser),

            const SizedBox(height: 10),

            // Register Button
            _buildButton2("Not Registered? Register here",
                const Color.fromARGB(255, 237, 144, 209), Colors.black, () {
              Navigator.of(context).pushNamed('/register');
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _loginUser() async {
    final email = _email.text.trim();
    final password = _password.text.trim();

    try {
      if (email.endsWith("iitd.ac.in")) {
        _showError("Do not use IIT-Delhi email");
        return;
      }

      // 🔹 Authenticate user
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      print(user);
      if (user != null) {
        if (!user.emailVerified) {
          // ❌ Email not verified, send verification and redirect
          await user.sendEmailVerification();
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/verify', (route) => false);
          return;
        }
        print("here2");
        // 🔹 Fetch user details from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          _showError("User details not found. Please register again.");
          return;
        }
        print("here1");
        // 🔹 Check if user has completed the survey
        DocumentSnapshot surveyDoc = await FirebaseFirestore.instance
            .collection("surveys")
            .doc(user.uid)
            .get();
        print("here");
        if (surveyDoc.exists) {
          // ✅ Survey exists, redirect to matchmaking
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/matchmaking', (route) => false);
        } else {
          print("here");
          // ❌ Survey not found, redirect to survey
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/survey', (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = e.toString();
      if (e.code == "wrong-password") {
        errorMessage = "Wrong password";
      } else if (e.code == "user-not-found") {
        errorMessage = "User not found";
      }
      _showError(errorMessage);
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
        controller: controller,
        obscureText: isPassword,
        enableSuggestions: !isPassword,
        autocorrect: !isPassword,
        keyboardType:
            isPassword ? TextInputType.text : TextInputType.emailAddress,
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

  Widget _buildButton1(
      String text, Color bgColor, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: 120,
      height: 40,
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
