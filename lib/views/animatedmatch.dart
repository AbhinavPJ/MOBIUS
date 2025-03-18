import 'package:flutter/material.dart';
import 'package:flutter_application_2/views/matchmaking.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:url_launcher/url_launcher.dart';

class MatchAnimationView extends StatefulWidget {
  final MatchmakingProfile currentUser;
  final MatchmakingProfile match;
  final bool flag1;
  final bool flag2;

  const MatchAnimationView({
    Key? key,
    required this.currentUser,
    required this.match,
    required this.flag1,
    required this.flag2,
  }) : super(key: key);

  @override
  State<MatchAnimationView> createState() => _MatchAnimationViewState();
}

class _MatchAnimationViewState extends State<MatchAnimationView>
    with TickerProviderStateMixin {
  late AnimationController _profileAnimationController;
  late AnimationController _textAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _profileAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _buttonAnimation;
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Initialize confetti controller
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    // Initialize animation controllers
    _profileAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Create animations
    _profileAnimation = CurvedAnimation(
      parent: _profileAnimationController,
      curve: Curves.easeOutBack,
    );

    _textAnimation = CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeOut,
    );

    _buttonAnimation = CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.elasticOut,
    );

    // Play sound effect
    _playMatchSound();

    // Start animations in sequence
    _startAnimationSequence();
  }

  Future<void> _playMatchSound() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/match_sound.mp3');
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void _startAnimationSequence() async {
    // Start profile pictures animation
    _profileAnimationController.forward();

    // Wait a bit before showing text
    await Future.delayed(const Duration(milliseconds: 300));
    if (_isDisposed) return;

    // Start text animation and confetti
    _textAnimationController.forward();
    _confettiController.play();

    // Wait before showing button
    await Future.delayed(const Duration(milliseconds: 800));
    if (_isDisposed) return;

    // Animate button
    _buttonAnimationController.forward();
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final Uri whatsappUri = Uri.parse("https://wa.me/$phoneNumber");

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not launch WhatsApp')));
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _profileAnimationController.dispose();
    _textAnimationController.dispose();
    _buttonAnimationController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7B61FF),
              Color(0xFFFF477E),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 3.1415926 / 2,
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.1,
                colors: const [
                  Colors.red,
                  Colors.green,
                  Colors.blue,
                  Colors.yellow,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple
                ],
              ),
            ),

            // Main content
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const SizedBox(height: 20),

                    // Profile pictures with animation
                    ScaleTransition(
                      scale: _profileAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildProfileCircle(
                              widget.currentUser.profilePicture),
                          const SizedBox(width: 10),
                          Icon(Icons.favorite, color: Colors.red, size: 50),
                          const SizedBox(width: 10),
                          _buildProfileCircle(widget.match.profilePicture),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Match text with animation
                    FadeTransition(
                      opacity: _textAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(_textAnimation),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              Text(
                                "It's a Match! 🎉",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 15),
                              Text(
                                "You and ${widget.match.name} have matched!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Buttons with animation
                    ScaleTransition(
                      scale: _buttonAnimation,
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.chat, color: Colors.white),
                            label: const Text(
                              "Message on WhatsApp",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              _launchWhatsApp(widget.match.number);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 5,
                              // ignore: deprecated_member_use
                              shadowColor: Colors.black.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              print("oogaaa");
                              print(widget.flag1);
                              Navigator.of(context).pop(false);
                            },
                            child: const Text(
                              "Continue Browsing",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
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

  Widget _buildProfileCircle(String imageUrl) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
            );
          },
        ),
      ),
    );
  }
}
