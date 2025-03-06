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
  late final TextEditingController _name;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _name = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
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
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 80),

            // Name Field
            _buildTextField(_name, "Enter full name", false),
            const SizedBox(height: 10),

            // Email Field
            _buildTextField(_email, "Enter email", false),
            const SizedBox(height: 10),

            // Password Field
            _buildTextField(_password, "Enter password", true),
            const SizedBox(height: 20),

            // Register Button
            _buildButton1(
                "Register", Colors.white, Colors.black, _registerUser),

            const SizedBox(height: 10),

            // Login Button
            _buildButton2(
                "Already Registered? Login Here", Colors.white, Colors.black,
                () {
              Navigator.of(context).pushNamed('/login');
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _registerUser() async {
    final email = _email.text.trim();
    final password = _password.text.trim();
    final name = _name.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      _showError("All fields are required");
      return;
    }

    if (email.endsWith("iitd.ac.in")) {
      _showError("Do not use IIT-Delhi email");
      return;
    }

    try {
      // 🔹 Create user in Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 🔹 Store user details in Firestore
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "uid": uid,
        "name": name,
        "email": email,
        "created_at": FieldValue.serverTimestamp(),
      });

      // 🔹 Send email verification
      await userCredential.user?.sendEmailVerification();

      print("User Registered & Data Saved Successfully!");

      // 🔹 Redirect to verification page
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/verify', (route) => false);
    } on FirebaseAuthException catch (e) {
      String errorMessage = e.code;
     // print(e.toString());
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
      width: 180,
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
      width: 260,
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
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
