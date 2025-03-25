import 'package:flutter/material.dart';
import 'package:flutter_application_2/views/matchmaking.dart';

class vProfileView extends StatefulWidget {
  final MatchmakingProfile profile;

  const vProfileView({Key? key, required this.profile}) : super(key: key);

  @override
  _vProfileViewState createState() => _vProfileViewState();
}

class _vProfileViewState extends State<vProfileView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 46, 49, 73),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Match Profile",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _buildBackCard(widget.profile),
      ),
    );
  }

  Widget _buildBackCard(MatchmakingProfile currentMatch) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Container
          Container(
            width: 390,
            height: 660,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700), width: 10),
              color: const Color.fromARGB(
                  255, 46, 49, 73), // Same dark blue as front
              boxShadow: [
                const BoxShadow(
                  color: Colors.black54,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 220), // Space for profile image

                // Name
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    currentMatch.name,
                    style: const TextStyle(
                      fontSize: 25,
                      fontFamily: "assets/fonts/futura.ttf",
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Description Box
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile Insights:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentMatch.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Gradient Flip Button (Same as Front)
                const SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFFFF477E)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // Profile Image Positioned at the Top
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter, // Ensures centering
              child: ClipOval(
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center, // Centers loading indicator
                    children: [
                      // Circular progress indicator while loading
                      const CircularProgressIndicator(),
                      // Image with loading handling
                      Image.network(
                        currentMatch.profilePicture,
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null)
                            return child; // Fully loaded
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.error,
                          size: 180,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
