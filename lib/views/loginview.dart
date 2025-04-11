import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class Loginview extends StatefulWidget {
  const Loginview({super.key});
  @override
  State<Loginview> createState() => _LoginviewState();
}

class _LoginviewState extends State<Loginview>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _email;
  late final TextEditingController _password;
  late AnimationController _animationController;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
        ),
        onPressed: _loginUser,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login_rounded, size: 24),
            const SizedBox(width: 10),
            const Text(
              "Login",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE3F2FD), // Soft pastel blue (from AchievementsView)
                  Color(0xFFF3E5F5), // Very soft lavender
                  Colors.white, // Pure white
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SafeArea(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: AnimationLimiter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 600),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          horizontalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          const SizedBox(height: 15),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "MOBIUS",
                                style: TextStyle(
                                  fontSize: 40,
                                  fontFamily: 'Cinzel',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurpleAccent,
                                ),
                              ),
                              Image.asset(
                                'assets/images/logo.png',
                                height: 120,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Swipe. Match. Meet. Exclusively for IITD.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF424242),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          _buildAnimatedCard(
                            child:
                                _buildTextField(_email, "Enter email", false),
                          ),
                          const SizedBox(height: 15),
                          _buildAnimatedCard(
                            child: _buildTextField(
                                _password, "Enter password", true),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _showForgotPasswordDialog,
                              child: Text(
                                'Forgot Password?    ',
                                style: TextStyle(
                                  color: const Color(
                                      0xFF6C63FF), // Change to any color you want
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildAnimatedCard(
                            child: _buildLoginButton(),
                          ),
                          const SizedBox(height: 15),
                          _buildAnimatedCard(
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/login'),
                              child: const Text(
                                "Not Registered yet? Register Here",
                                style: TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/verify', (route) => false);
          return;
        }

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          _showError("User details not found. Please register again.");
          return;
        }

        DocumentSnapshot surveyDoc = await FirebaseFirestore.instance
            .collection("surveys")
            .doc(user.uid)
            .get();

        if (surveyDoc.exists) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (route) => false);
        } else {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/survey', (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = e.code;
      if (e.code == "wrong-password") {
        errorMessage = "Wrong password";
      } else if (e.code == "user-not-found") {
        errorMessage = "User not found";
      }
      _showError(errorMessage);
    }
  }

  Widget _buildAnimatedCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFE3F2FD), // Soft pastel blue
                const Color(0xFFF3E5F5), // Very soft lavender
                const Color(0xFFFFFFFF), // Pure white
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
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
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Color(0xFF424242)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        prefixIcon: Icon(
          isPassword ? Icons.lock_outline : Icons.email_outlined,
          color: const Color(0xFF6C63FF),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController _resetEmail = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reset Password"),
          content: TextField(
            controller: _resetEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: "Enter your registered email",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final email = _resetEmail.text.trim();
                try {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);
                  Navigator.of(context).pop();
                  _showError("Password reset email sent");
                } on FirebaseAuthException catch (e) {
                  Navigator.of(context).pop();
                  _showError(e.message ?? "Failed to send reset email");
                }
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }
}
