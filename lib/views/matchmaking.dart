import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_2/views/achievementsview.dart';
import 'package:flutter_application_2/views/animatedmatch.dart';
import 'package:flutter_application_2/views/card_provider.dart';
import 'package:flutter_application_2/views/confessions.dart';
import 'package:flutter_application_2/views/mymatchesview.dart';
import 'package:flutter_application_2/views/profileview.dart';
import 'dart:math' as math;
import 'package:flutter_application_2/views/reviewdatesview.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomCacheManager {
  static const key = 'matchmakingImagesCache';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

class MatchmakingProfile {
  final String userId;
  final String name;
  final String gender;
  final String entryNumber;
  final List<String> clubs;
  final String hangoutSpot;
  final List<String> movieGenres;
  final List<String> musicGenres;
  final double personality;
  final String popularity;
  final String profilePicture;
  final String relationshipType;
  final List<String> sports;
  final Timestamp timestamp;
  final String tagline;
  final String hostel;
  final String number;
  final List<String>? rightswipedby;
  final String description;
  final List<String>? heleftwiped;
  final String? catfishradar;
  // Add a map to store user IDs and their swipe timestamps
  final Map<String, Timestamp>? swipeTimestamps;
  final bool? hasUpdated;
  MatchmakingProfile({
    required this.userId,
    required this.name,
    required this.gender,
    required this.entryNumber,
    required this.clubs,
    required this.hangoutSpot,
    required this.movieGenres,
    required this.musicGenres,
    required this.personality,
    required this.popularity,
    required this.profilePicture,
    required this.relationshipType,
    required this.sports,
    required this.timestamp,
    required this.tagline,
    required this.hostel,
    required this.number,
    required this.rightswipedby,
    required this.description,
    this.heleftwiped,
    this.swipeTimestamps,
    this.hasUpdated,
    this.catfishradar,
  });

  factory MatchmakingProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Convert the swipeTimestamps from Firestore to a Map<String, Timestamp>
    Map<String, Timestamp>? swipeTimestamps;
    if (data['swipeTimestamps'] != null) {
      swipeTimestamps = Map<String, Timestamp>.from(
        (data['swipeTimestamps'] as Map<dynamic, dynamic>).map(
          (key, value) => MapEntry(key.toString(), value as Timestamp),
        ),
      );
      print(swipeTimestamps);
    }

    return MatchmakingProfile(
        userId: data['userId'] ?? '',
        name: data['name'] ?? '',
        gender: data['gender'] ?? '',
        entryNumber: data['entry_number'] ?? '',
        clubs: List<String>.from(data['clubs'] ?? []),
        hangoutSpot: data['hangout_spot'] ?? '',
        movieGenres: List<String>.from(data['movie_genres'] ?? []),
        musicGenres: List<String>.from(data['music_genres'] ?? []),
        personality: (data['personality'] as num?)?.toDouble() ?? 0.0,
        popularity: data['popularity']?.toString() ?? '',
        profilePicture: data['profilePicture'] ?? '',
        relationshipType: data['relationship_type'] ?? '',
        sports: List<String>.from(data['sports'] ?? []),
        timestamp: data['timestamp'] ?? Timestamp.now(),
        tagline: data['tagline'] ?? '',
        hostel: data['hostel'] ?? '',
        number: data['number'] ?? '',
        rightswipedby: List<String>.from(data['rightswipedby']),
        description: data['description'] ?? '',
        heleftwiped: List<String>.from(data['Heleftwiped'] ?? []),
        swipeTimestamps: swipeTimestamps);
  }
}

// ignore: must_be_immutable
class MatchmakingScreen extends StatefulWidget {
  final double n1, n2, n3, n4, n5, n6, n7, n8, n9, n10;
  var flag = false;
  MatchmakingScreen({
    Key? key,
    required this.n1,
    required this.n2,
    required this.n3,
    required this.n4,
    required this.n5,
    required this.n6,
    required this.n7,
    required this.n8,
    required this.n9,
    required this.n10,
    required this.flag,
  }) : super(key: key);
  @override
  _MatchmakingScreenState createState() => _MatchmakingScreenState();
}

// Removing _isDisposed state variable and related code
class _MatchmakingScreenState extends State<MatchmakingScreen>
    with TickerProviderStateMixin {
  // Animation controller for the flip card
  List<MatchmakingProfile> _stackedProfiles = [];
  bool _isTransitioning = false;
  late AnimationController _flipController;
  bool _isMatchPopupShown = false;
  bool _isLastProfile = false;
  bool _showThankYouPage = false;
  bool _isCardFlipped = false; // Controls card side (front/back)
  int _currentDisplayState = 1;
  MatchmakingProfile? currentUserProfile;
  List<MatchmakingProfile> potentialMatches = [];
  List<MapEntry<MatchmakingProfile, double>> rankedMatches = [];
  int currentMatchIndex = 0;
  String? currentDescription;
  bool isLoadingDescription = false;
  var len = 0;
  var L = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfiles();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      final provider = Provider.of<CardProvider>(context, listen: false);
      provider.setScreenSize(size);
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  // Add this method to fetch user profiles with cooldown check
  Future<void> _fetchUserProfiles() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }

      final DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('surveys')
          .doc(currentUser.uid)
          .get();

      if (!currentUserDoc.exists) {
        return;
      }

      currentUserProfile = MatchmakingProfile.fromFirestore(currentUserDoc);

      // Get all profiles
      final QuerySnapshot surveyDocs = await FirebaseFirestore.instance
          .collection('surveys')
          .where('userId', isNotEqualTo: currentUser.uid)
          .get();

      final List<MatchmakingProfile> allProfiles = surveyDocs.docs
          .map((doc) => MatchmakingProfile.fromFirestore(doc))
          .toList();

      // Current timestamp for cooldown check
      final Timestamp now = Timestamp.now();
      final Duration cooldownPeriod = Duration(days: 7);

      // Filter out profiles that the user has seen in the past week
      final List<MatchmakingProfile> availableProfiles =
          allProfiles.where((profile) {
        // Check cooldown period
        if (currentUserProfile!.swipeTimestamps != null &&
            currentUserProfile!.swipeTimestamps!.containsKey(profile.userId)) {
          final Timestamp swipeTime =
              currentUserProfile!.swipeTimestamps![profile.userId]!;
          final DateTime swipeDateTime = swipeTime.toDate();
          final DateTime nowDateTime = now.toDate();

          // Calculate difference in days
          final difference = nowDateTime.difference(swipeDateTime).inDays;

          // Return false if the profile is still in cooldown period (less than 7 days)
          if (difference < cooldownPeriod.inDays) {
            return false;
          }
        }

        return true;
      }).toList();

      // Rank the filtered matches
      rankedMatches = _rankMatches(availableProfiles);

      // Convert ranked matches back to a list of profiles for the UI
      potentialMatches = rankedMatches.map((entry) => entry.key).toList();

      // Prepare the initial card stack
      _prepareCardStack();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Error fetching profiles: $e");
    }
  }

  void _cycleDisplayState() {
    setState(() {
      // Cycle through display states (1-3)
      _currentDisplayState =
          _currentDisplayState < 3 ? _currentDisplayState + 1 : 1;
    });
  }

// Handle card flipping (front/back)
  void _flipCard() {
    setState(() {
      // Toggle between front and back
      _isCardFlipped = !_isCardFlipped;
    });
  }

  Widget _buildCardStack() {
    if (_stackedProfiles.isEmpty) {
      _prepareCardStack();
      if (_stackedProfiles.isEmpty) {
        return Container(); // Return empty container when no matches
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      // Set screen size in provider
      Provider.of<CardProvider>(context, listen: false)
          .setScreenSize(Size(constraints.maxWidth, constraints.maxHeight));

      // Make sure to reset position to center when rebuilding
      Provider.of<CardProvider>(context, listen: false).resetPosition();

      final availableWidth = constraints.maxWidth;
      final availableHeight = constraints.maxHeight;

      // Maximize card size while maintaining aspect ratio
      final paddingVertical = 10.0;
      final paddingHorizontal = 10.0;

      final cardWidth = availableWidth - paddingHorizontal * 2;
      final cardHeight = cardWidth * 1.5;
      final maxHeight = availableHeight -
          paddingVertical * 2 -
          40; // space for stateIndicators

      final adjustedCardHeight =
          cardHeight > maxHeight ? maxHeight : cardHeight;
      final adjustedCardWidth = adjustedCardHeight / 1.5;

      // State indicators
      Widget stateIndicators = Container(
        width: availableWidth,
        padding: EdgeInsets.symmetric(horizontal: availableWidth * 0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStateIndicator(1, "Score"),
            _buildStateIndicator(2, "Year"),
            _buildStateIndicator(3, "Dept"),
          ],
        ),
      );

      List<Widget> stackedCards = [];
      final int totalCards = _stackedProfiles.length;

      try {
        // Calculate the center position
        final centerX = (availableWidth - adjustedCardWidth) / 2;
        final centerY = (availableHeight - adjustedCardHeight - 60) / 2;

        // Third card (bottom)
        if (totalCards >= 3) {
          final thirdProfile = _stackedProfiles[0];
          final thirdScore = _getScoreForProfile(thirdProfile);
          final thirdBeta = (thirdScore % 100).toStringAsFixed(2);

          stackedCards.add(
            Positioned(
              // Position exactly at center
              left: centerX,
              top: centerY,
              child: Transform.scale(
                scale: 0.90,
                child: Opacity(
                  opacity: 0.4,
                  child: BuildCard(thirdProfile, thirdBeta, adjustedCardWidth,
                      adjustedCardHeight),
                ),
              ),
            ),
          );
        }

        // Second card (middle)
        if (totalCards >= 2) {
          final secondProfile = _stackedProfiles[totalCards - 2];
          final secondScore = _getScoreForProfile(secondProfile);
          final secondBeta = (secondScore % 100).toStringAsFixed(2);

          stackedCards.add(
            Positioned(
              // Position exactly at center
              left: centerX,
              top: centerY,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: 0.7,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 300),
                  scale: _isTransitioning ? 0.95 : 0.95,
                  child: BuildCard(secondProfile, secondBeta, adjustedCardWidth,
                      adjustedCardHeight),
                ),
              ),
            ),
          );
        }

        // Front card (topmost)
        if (totalCards > 0) {
          final frontProfile = _stackedProfiles[totalCards - 1];
          final frontScore = _getScoreForProfile(frontProfile);
          final frontBeta = (frontScore % 100).toStringAsFixed(2);

          stackedCards.add(
            Consumer<CardProvider>(
              builder: (context, provider, child) {
                Widget cardWidget = _isCardFlipped
                    ? _buildDescriptionCard(
                        frontProfile, adjustedCardWidth, adjustedCardHeight)
                    : BuildCard(frontProfile, frontBeta, adjustedCardWidth,
                        adjustedCardHeight);

                if (provider.isSwipingOut) {
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    left: -adjustedCardWidth * 1.5,
                    top: centerY, // Maintain vertical center during swipe
                    child: cardWidget,
                  );
                } else if (provider.isSwipingRightOut) {
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    left: availableWidth + adjustedCardWidth * 0.5,
                    top: centerY, // Maintain vertical center during swipe
                    child: cardWidget,
                  );
                } else {
                  // Calculate absolute position based on provider position
                  final absoluteX = centerX + provider.position.dx;
                  final absoluteY = centerY + provider.position.dy;

                  return Positioned(
                    // Use absolute positioning from center
                    left: absoluteX,
                    top: absoluteY,
                    child: Transform.rotate(
                      angle: provider.angle * (math.pi / 180),
                      child: GestureDetector(
                        onTap: _cycleDisplayState,
                        onPanStart: (details) {
                          Provider.of<CardProvider>(context, listen: false)
                              .startPosition(details);
                        },
                        onPanUpdate: (details) {
                          Provider.of<CardProvider>(context, listen: false)
                              .updatePosition(details);
                        },
                        onPanEnd: (details) {
                          final provider =
                              Provider.of<CardProvider>(context, listen: false);
                          provider.endPosition();

                          final status = provider.getStatus();

                          if (status != SwipeStatus.none) {
                            if (status == SwipeStatus.like) {
                              _handleSwipeRight();
                            } else if (status == SwipeStatus.dislike) {
                              _handleSwipeLeft();
                            }

                            provider.resetPosition();
                          }
                        },
                        child: cardWidget,
                      ),
                    ),
                  );
                }
              },
            ),
          );
        }
      } catch (e) {
        print("Error building card stack: $e");
        stackedCards = [
          Center(
            child: Container(
              width: adjustedCardWidth,
              height: adjustedCardHeight,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(child: Text("Error loading profiles")),
            ),
          )
        ];
      }

      return SafeArea(
        child: Column(
          children: [
            stateIndicators,
            SizedBox(height: paddingVertical),
            Expanded(
              child: Center(
                child: Stack(
                  // Removed alignment property to use explicit positioning
                  children: stackedCards,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

// Responsive description card with improved overflow handling
  Widget _buildDescriptionCard(
      MatchmakingProfile profile, double width, double height) {
    // Constrain text sizes to prevent overflow
    final titleSize = math.min(width * 0.08, 28.0); // Max 28px
    final bodySize = math.min(width * 0.045, 16.0); // Max 16px

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(math.min(20.0, width * 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(math.min(16.0, width * 0.05)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "About Me",
                style: GoogleFonts.playfairDisplay(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: math.min(16.0, height * 0.03)),
              Text(
                profile.description,
                style: TextStyle(
                  fontSize: bodySize,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateIndicator(int stateNumber, String label) {
    bool isActive = _currentDisplayState == stateNumber;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentDisplayState = stateNumber;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Prevent vertical overflow
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isActive ? Colors.deepPurpleAccent : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color:
                      isActive ? Colors.deepPurpleAccent : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Updated front card with overflow protection
  Widget buildFrontCard(MatchmakingProfile currentMatch, String beta,
      double width, double height) {
    // This method is no longer needed as we've integrated its functionality
    // directly into the _buildCardStack method above
    return BuildCard(currentMatch, beta, width, height);
  }

  String extractFileName(String fullPath) {
    final decoded = Uri.decodeFull(fullPath); // Decode %2F
    final start =
        decoded.indexOf('profile_pictures/') + 'profile_pictures/'.length;
    final end = decoded.indexOf('.jpg', start) + 4; // Include '.jpg'
    return decoded.substring(start, end);
  }

  Widget buildScoreBadge(String score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            score, // e.g. 8.7
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

// Simplified BuildCard that avoids complex transformations
  Widget BuildCard(MatchmakingProfile currentMatch, String beta, double width,
      double height) {
    final provider = Provider.of<CardProvider>(context, listen: false);
    String decisionText = "";
    Color decisionColor = Colors.transparent;

    // Safely determine swipe direction indicators
    final dx = provider.position.dx;
    if (dx > 15) {
      // Add threshold to avoid flickering
      decisionText = "SMASH";
      decisionColor = Color.fromARGB(255, 179, 255, 1);
    } else if (dx < -15) {
      decisionText = "PASS";
      decisionColor = Color.fromRGBO(244, 54, 54, 1.0);
    }

    // Calculate constrained values to prevent overflow
    final borderRadius = math.min(20.0, width * 0.10);
    final decisionFontSize = math.min(40.0, width * 0.12);
    final iconSize = math.min(50.0, width * 0.15);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, 10), // soft drop shadow
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Background image
            Container(
              width: width,
              height: height,
              child: CachedNetworkImage(
                imageUrl: currentMatch.profilePicture,
                cacheManager: CustomCacheManager.instance,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.deepPurpleAccent),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.error,
                    color: Colors.red,
                    size: iconSize,
                  ),
                ),
              ),
            ),

            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: math.min(100.0, height * 0.2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Profile info
            Positioned(
              bottom: math.min(20.0, height * 0.04),
              left: math.min(20.0, width * 0.05),
              right: math.min(20.0, width * 0.05),
              child: buildInfo(currentMatch, beta, width),
            ),

            // Decision text
            if (decisionText.isNotEmpty)
              Positioned(
                top: math.min(40.0, height * 0.08),
                left: math.min(50.0, width * 0.1),
                right: math.min(50.0, width * 0.1),
                child: Text(
                  decisionText,
                  style: TextStyle(
                    fontSize: decisionFontSize,
                    fontWeight: FontWeight.bold,
                    color: decisionColor,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Positioned(
              top: math.min(16.0, height * 0.03),
              right: math.min(16.0, width * 0.03),
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.white,
                ),
                color: Colors.white,
                onSelected: (String value) async {
                  if (value == 'report') {
                    final subject = 'User Report - ${currentMatch.userId}';
                    final body = '''
Hi Team,

I would like to report the following user:
• Name: ${currentMatch.name}
• ID: ${currentMatch.userId}
• Reason: [Brief description of issue]
• Additional Info: [Optional details]

Please look into this as soon as possible.

Thank you.
''';
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'mobius.app.services@gmail.com',
                      queryParameters: {'subject': subject, 'body': body},
                    );
                    final String encodedSubject = Uri.encodeComponent(subject);
                    final String encodedBody =
                        Uri.encodeComponent(body).replaceAll('+', '%20');

                    final Uri emailUri = Uri.parse(
                        'mailto:mobius.app.services@gmail.com?subject=$encodedSubject&body=$encodedBody');

                    if (await canLaunchUrl(emailLaunchUri)) {
                      await launchUrl(emailUri);
                    } else {
                      // Optionally show a snackbar or error dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open email app')),
                      );
                    }
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Text(
                          '⚠️',
                          style: TextStyle(fontSize: 16),
                          selectionColor: Colors.amber,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Report User',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Updated buildInfo with overflow protection for text
  Widget buildInfo(MatchmakingProfile profile, String beta, double cardWidth) {
    String displayText;
    switch (_currentDisplayState) {
      case 1:
        displayText = "Match score: $beta";
        break;
      case 2:
        displayText = Fetchyear(profile);
        break;
      case 3:
        displayText = Fetchdept(profile);
        break;
      default:
        displayText = "Match score: $beta";
    }

    // Constrain text sizes to prevent overflow
    final nameSize = math.min(cardWidth * 0.15, 28.0); // Max 28px
    //final infoSize = math.min(cardWidth * 0.05, 18.0); // Max 18px

    return Column(
      mainAxisSize: MainAxisSize.min, // Prevent vertical overflow
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.name,
          style: TextStyle(
            fontSize: nameSize,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 10, color: Colors.black)],
          ),
          overflow: TextOverflow.ellipsis, // Handle text overflow
        ),
        SizedBox(height: math.min(5.0, cardWidth * 0.08)),
        buildScoreBadge(displayText)
      ],
    );
  }

  // Update buildFrontCard to handle the flip gesture

  // Update the _handleSwipeLeft and _handleSwipeRight for seamless transitions
  // Update _handleSwipeLeft to store timestamp for cooldown
  void _handleSwipeLeft() async {
    if (_isTransitioning) return;

    if (potentialMatches.isNotEmpty) {
      setState(() {
        _isTransitioning = true;
        _isCardFlipped = false; // Reset flip state for new card
      });

      // Get the current front profile
      int frontIndex = potentialMatches.length - 1;
      MatchmakingProfile frontProfile = potentialMatches[frontIndex];

      // Pre-fetch the next stack while animation is happening
      DocumentReference userRef = FirebaseFirestore.instance
          .collection('surveys')
          .doc(currentUserProfile!.userId);

      // Get current timestamp for cooldown
      Timestamp swipeTimestamp = Timestamp.now();

      // Update Firebase to store left swipe and swipe timestamp
      Map<String, dynamic> updates = {
        'Heleftwiped': FieldValue.arrayUnion([frontProfile.userId]),
        'swipeTimestamps.${frontProfile.userId}': swipeTimestamp
      };

      // Update Firebase in the background
      userRef.update(updates);

      if (mounted) {
        setState(() {
          // Remove current card
          if (potentialMatches.isNotEmpty) {
            potentialMatches.removeLast();
            rankedMatches.removeLast();
          }

          // Check if we've run out of cards
          if (potentialMatches.isEmpty) {
            _showThankYouPage = true;
          } else {
            // Refresh the stack immediately
            _prepareCardStack();
          }

          // Short delay before enabling interactions again
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _isTransitioning = false;
              });
            }
          });
        });
      }
    }
  }

  // Update _handleSwipeRight to store timestamp for cooldown
  void _handleSwipeRight() {
    if (_isTransitioning) return;

    if (potentialMatches.isNotEmpty) {
      // Get the current front profile
      int frontIndex = potentialMatches.length - 1;
      MatchmakingProfile frontProfile = potentialMatches[frontIndex];

      setState(() {
        _isTransitioning = true;
        _isCardFlipped = false; // Reset flip state for new card
      });

      // Get current timestamp for cooldown
      Timestamp swipeTimestamp = Timestamp.now();

      // Update user's document to add the swipe timestamp
      DocumentReference userRef = FirebaseFirestore.instance
          .collection('surveys')
          .doc(currentUserProfile!.userId);
      print(swipeTimestamp);
      userRef
          .update({'swipeTimestamps.${frontProfile.userId}': swipeTimestamp});

      // Handle like/match logic in background
      if (currentUserProfile != null) {
        AClogic(currentUserProfile!, frontProfile);
      }

      // Update UI immediately
      if (mounted) {
        setState(() {
          // Remove current card
          if (potentialMatches.isNotEmpty) {
            potentialMatches.removeLast();
            rankedMatches.removeLast();
          }

          // Check if we've run out of cards
          if (potentialMatches.isEmpty) {
            _showThankYouPage = true;
          } else {
            // Refresh the stack immediately
            _prepareCardStack();
          }

          // Short delay before enabling interactions again
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _isTransitioning = false;
              });
            }
          });
        });
      }
    }
  }

  List<MapEntry<MatchmakingProfile, double>> _rankMatches(
      List<MatchmakingProfile> profiles) {
    // This is where you'll implement your custom matchmaking scoring algorithm
    // Each profile should be paired with a match score
    // Example placeholder implementation:
    return profiles
        .map((profile) => MapEntry(profile, _calculateMatchScore(profile)))
        .toList()
      ..sort((a, b) => (-b.value)
          .compareTo(-a.value)); // Sort in descending order of match score
  }

  // Placeholder match score calculation
  double _calculateMatchScore(MatchmakingProfile profile) {
    if (currentUserProfile == null) {
      return 0.0;
    }
    print(currentUserProfile!.name);

    double score = 0.0;
    final n1 = widget.n1;
    final n2 = widget.n2;
    final n3 = widget.n3;
    final n4 = widget.n4;
    final n5 = widget.n5;
    final n6 = widget.n6;
    final n7 = widget.n7;
    final n8 = widget.n8;
    final n9 = widget.n9;
    final n10 = widget.n10;
    score += n1 *
        (_calculatePersonalityOverlap(
            currentUserProfile!.personality, profile.personality));

    //print("hereiii");
    //print(currentUserProfile?.gender);

    //print(currentUserProfile?.entryNumber);
    score += n2 *
        (ismatchyear(currentUserProfile!.entryNumber, profile.entryNumber));
    // Compare interests
    //print(profile.entryNumber);
    //print("ohh fuck");
    //print(currentUserProfile!.entryNumber);

    score += n3 *
        (ismatchdept(currentUserProfile!.entryNumber, profile.entryNumber));

    //print("oh bsdk");
    score += n4 *
        (ismatchpopularity(currentUserProfile!.popularity, profile.popularity));

    score += n5 *
        (ismatchhangout(currentUserProfile!.hangoutSpot, profile.hangoutSpot));

    //print('hereeeeiiiii');
    score += n6 *
        ismatchrelationship(
            currentUserProfile!.relationshipType, profile.relationshipType);

    //print("mcccc");
    score += n7 *
        _calculateInterestOverlap(currentUserProfile!.sports, profile.sports) *
        2;

    score += n8 *
        _calculateInterestOverlap(currentUserProfile!.clubs, profile.clubs);

    score += n9 *
        _calculateInterestOverlap(
            currentUserProfile!.movieGenres, profile.movieGenres);

    score += n10 *
        _calculateInterestOverlap(
            currentUserProfile!.musicGenres, profile.musicGenres);
    //print("hereiiiiiiiiiiiii");
    if (currentUserProfile!.rightswipedby != null &&
        currentUserProfile!.rightswipedby!.contains(profile.userId)) {
      return 200.0 +
          100.0 *
              score /
              (2000.0 * n1 +
                  n2 +
                  n3 +
                  2 * n4 +
                  n5 +
                  3 * n6 +
                  n7 +
                  n8 +
                  n9 +
                  n10);
    }
    return 100.0 *
        score /
        (2000.0 * n1 + n2 + n3 + 2 * n4 + n5 + 3 * n6 + n7 + n8 + n9 + n10);
  }

  double ismatchyear(String s1, String s2) {
    var i = 0;
    while (i < 4) {
      if (s1[i] != s2[i]) {
        return 0.0;
      }
      ++i;
    }
    return 1.0;
  }

  double ismatchdept(String s1, String s2) {
    var i = 4;
    while (i < 6) {
      if (s1[i] != s2[i]) {
        return 0.0;
      }
      ++i;
    }
    return 1.0;
  }

  double ismatchhangout(String s1, String s2) {
    if (s1 == s2) {
      return 1.0;
    }
    return 0.0;
  }

  double ismatchrelationship(String s1, String s2) {
    return 3.0 - absolutevalue(indexrelationship(s1) - indexrelationship(s2));
  }

  double indexrelationship(String s) {
    if (s[0] == 'S') {
      return 0.0;
    }
    if (s[0] == 'C') {
      return 1.0;
    }
    if (s[0] == 'O') {
      return 2.0;
    }
    return 3.0;
  }

  double ismatchpopularity(String s1, String s2) {
    return (2.0 - absolutevalue(indexpopularity(s1) - indexpopularity(s2)));
  }

  double absolutevalue(double x) {
    if (x < 0.0) {
      return -x;
    }
    return x;
  }

  double indexpopularity(String s) {
    if (s[0] == 'N') {
      return 0.0;
    }
    if (s[0] == 's') {
      return 1.0;
    }
    return 2.0;
  }

  String Fetchyear(MatchmakingProfile m) {
    if (m.entryNumber[3] == '4') {
      return "First year";
    }
    if (m.entryNumber[3] == '3') {
      return "Second year";
    }
    if (m.entryNumber[3] == '2') {
      return "Third year";
    }
    if (m.entryNumber[3] == '1') {
      return "Fourth year";
    }
    return "Fifth year";
  }

  String Fetchdept(MatchmakingProfile m) {
    String code = m.entryNumber[4] + m.entryNumber[5];
    print(code);
    if (code == "AM") {
      return "Department of Applied Mechanics";
    }
    if (code == "BB") {
      return "Biotech Department";
    }
    if (code == "CH") {
      return "Chemical Department";
    }
    if (code == "CE") {
      return "Civil Department";
    }
    if (code == "EE") {
      return "EE Department";
    }
    if (code == "CS") {
      return "CS Department";
    }
    if (code == "ES") {
      return "Department of Energy Sciences";
    }
    if (code == "MS") {
      return "Material Science Department";
    }
    if (code == "MT") {
      return "Department of Mathematics";
    }
    if (code == "ME") {
      return "Mechanical Department";
    }
    if (code == "PH") {
      return "Department of Physics";
    }
    if (code == "CY") {
      return "Chemistry Department";
    }
    return "Textile Department";
  }

  double _calculatePersonalityOverlap(double x, double y) {
    return 1000.0 + 100.0 * (x + y) - 20.0 * x * y;
  }

  // Helper method to calculate interest overlap
  double _calculateInterestOverlap(List<String> list1, List<String> list2) {
    var i = 0;
    int intersects = 0;
    while (i < list1.length) {
      var j = 0;
      var flag = false;
      while (j < list2.length) {
        if (list1[i] == list2[j]) {
          flag = true;
          break;
        }
        j++;
      }
      i++;
      if (flag == true) {
        intersects += 1;
      }
    }
    return intersects.toDouble() /
        (list1.length.toDouble() + list2.length.toDouble() - intersects);
  }

  // Modified AClogic method to not require context
  Future<bool> AClogic(
      MatchmakingProfile currentUser, MatchmakingProfile match) async {
    try {
      DocumentReference matchRef =
          FirebaseFirestore.instance.collection('surveys').doc(match.userId);

      await matchRef.update({
        'rightswipedby': FieldValue.arrayUnion([currentUser.userId])
      });

      print(
          "Added ${currentUser.userId} to ${match.userId}'s rightswipedby list");

      if (match.rightswipedby == null) {
        print("Match rightswipedby is null");
        return false;
      }

      print("Checking for mutual match");
      print("Match rightswipedby: ${match.rightswipedby}");
      print("Current user rightswipedby: ${currentUser.rightswipedby}");

      if (currentUser.rightswipedby!.contains(match.userId)) {
        print("It's a match! Both users have swiped right on each other.");

        await FirebaseFirestore.instance.collection('matches').add({
          'users': [currentUser.userId, match.userId],
          'timestamp': FieldValue.serverTimestamp(),
          'matchScore': _calculateMatchScore(match),
        });

        // Show match popup before potentially redirecting
        if (mounted) {
          _showMatchPopup(currentUser, match, _isLastProfile);
        }
        _sendMatchNotification(currentUser, match);
        return true;
      }
      return false;
    } catch (e) {
      print("Error in AClogic: $e");
      return false;
    }
  }

  Future<void> _sendMatchNotification(
      MatchmakingProfile currentUser, MatchmakingProfile match) async {
    try {
      // This is a placeholder for your notification system
      print(
          "Sending notification to ${currentUser.name} about match with ${match.name}");
      print(
          "Sending notification to ${match.name} about match with ${currentUser.name}");
      // Implementation would go here
    } catch (e) {
      print("Error sending match notification: $e");
    }
  }

  BottomNavigationBar _buildBottomBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor:
          Colors.white, // Matches the white background in the image
      selectedItemColor: Colors.purple, // Highlight color for selected item
      unselectedItemColor: Colors.black, // Default color for unselected icons
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, size: 32),
          label: "",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.rate_review_outlined, size: 32),
          label: "",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events_outlined, size: 32),
          label: "",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border, size: 32),
          label: "",
        ),
        BottomNavigationBarItem(
            icon: Icon(Icons.mail_outline_rounded, size: 32), label: "")
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyMatchesView(
                  n1: widget.n1,
                  n2: widget.n2,
                  n3: widget.n3,
                  n4: widget.n4,
                  n5: widget.n5,
                  n6: widget.n6,
                  n7: widget.n7,
                  n8: widget.n8,
                  n9: widget.n9,
                  n10: widget.n10,
                ),
              ),
            );
            break;
          case 1:
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReviewDatePage(
                      n1: widget.n1,
                      n2: widget.n2,
                      n3: widget.n3,
                      n4: widget.n4,
                      n5: widget.n5,
                      n6: widget.n6,
                      n7: widget.n7,
                      n8: widget.n8,
                      n9: widget.n9,
                      n10: widget.n10),
                ));
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      AchievementsView(profile: currentUserProfile!)),
            );
            break;
          case 3:
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyMatchesView(
                      n1: widget.n1,
                      n2: widget.n2,
                      n3: widget.n3,
                      n4: widget.n4,
                      n5: widget.n5,
                      n6: widget.n6,
                      n7: widget.n7,
                      n8: widget.n8,
                      n9: widget.n9,
                      n10: widget.n10),
                ));
            break;
          case 4:
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ConfessionView(profile: currentUserProfile!),
                ));
        }
      },
    );
  }

  void _showMatchPopup(
      MatchmakingProfile currentUser, MatchmakingProfile match, bool flag) {
    if (!mounted || _isMatchPopupShown) return;
    _isMatchPopupShown = true; // Prevent duplicate popups
    print("Showing match popup");

    Future.microtask(() {
      if (mounted) {
        Navigator.of(context)
            .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MatchAnimationView(
                    currentUser: currentUser,
                    match: match,
                    flag1: (currentMatchIndex == (potentialMatches.length - 1)),
                    flag2: (currentMatchIndex == (potentialMatches.length))),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        )
            .then((_) {
          _isMatchPopupShown = false; // Reset flag when closed
          // Do NOT redirect to final page here - let the normal flow continue
        });
      }
    });
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center items
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 45,
          ),
          const SizedBox(width: 10), // Add spacing between logo and text
          const Text(
            "MOBIUS",
            style: TextStyle(
              fontSize: 32,
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
      actions: [
        FutureBuilder<MatchmakingProfile>(
          future: _fetchCurrentProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ); // Show loading indicator while fetching data
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return IconButton(
                icon: const Icon(Icons.error, size: 32, color: Colors.red),
                onPressed: () {}, // Do nothing on error
              );
            }

            final currentProfile = snapshot.data!;
            return IconButton(
              icon: const Icon(Icons.account_circle,
                  size: 32, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileView(
                      profile: currentProfile,
                      onProfileUpdated: () => {},
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

// Fetches the current user's profile from Firestore
  Future<MatchmakingProfile> _fetchCurrentProfile() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('surveys')
        .doc(currentUser.uid)
        .get();

    if (!userDoc.exists) {
      throw Exception("Profile not found");
    }

    return MatchmakingProfile.fromFirestore(userDoc);
  }

  // Update the build method to use mounted check instead of _isDisposed

  @override
  Widget build(BuildContext context) {
    if (_showThankYouPage || potentialMatches.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(context),
        extendBodyBehindAppBar: true,
        bottomNavigationBar: _buildBottomBar(context),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE3F2FD), // Soft pastel blue
                Color(0xFFF3E5F5), // Soft lavender
                Colors.white,
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
          child: _buildThankYouPage(),
        ),
      );
    }

    if (_stackedProfiles.isEmpty && potentialMatches.isNotEmpty) {
      _prepareCardStack();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildBottomBar(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD), // Soft pastel blue
              Color(0xFFF3E5F5), // Soft lavender
              Colors.white,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 5),
              Expanded(child: _buildCardStack()),
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCircularButton1(
                      icon: Icons.close,
                      onPressed: () {
                        Provider.of<CardProvider>(context, listen: false)
                            .triggerExternalSwipeLeft();
                        _handleSwipeLeft();
                      },
                    ),
                    const SizedBox(width: 20),
                    _buildCircularButton3(
                      icon: _isCardFlipped
                          ? Icons.flip_to_front
                          : Icons.flip_to_back,
                      onPressed: _flipCard,
                    ),
                    const SizedBox(width: 20),
                    _buildCircularButton2(
                      icon: Icons.check,
                      onPressed: () {
                        Provider.of<CardProvider>(context, listen: false)
                            .triggerSwipeRightOut();
                        _handleSwipeRight();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add methods to handle card actions
  void _prepareCardStack() {
    if (potentialMatches.isEmpty) {
      setState(() {
        _showThankYouPage = true;
      });
      return;
    }

    // Maintain a sliding window of 3 cards (or less if fewer remain)
    _stackedProfiles = [];
    final int totalCards = potentialMatches.length;
    const int windowSize = 3; // Fixed window size
    int startIndex = math.max(0, totalCards - windowSize);

    for (int i = startIndex; i < totalCards; i++) {
      _stackedProfiles.add(potentialMatches[i]);
    }
  }

// Use this improved card stack builder

// Helper method to get score for a profile
  double _getScoreForProfile(MatchmakingProfile profile) {
    for (var entry in rankedMatches) {
      if (entry.key.userId == profile.userId) {
        return entry.value;
      }
    }
    return 0.0;
  }

// Update swipe handlers to use animation

  // Add a method to build the thank you page
  Widget _buildThankYouPage() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite,
              color: Colors.deepPurpleAccent,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              "Thank You!",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurpleAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "You've seen all potential matches for now.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Check back later for new matches!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Navigate to MyMatchesView or another screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyMatchesView(
                      n1: widget.n1,
                      n2: widget.n2,
                      n3: widget.n3,
                      n4: widget.n4,
                      n5: widget.n5,
                      n6: widget.n6,
                      n7: widget.n7,
                      n8: widget.n8,
                      n9: widget.n9,
                      n10: widget.n10,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                "View My Matches",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update buildFrontCard method to handle swipe gestures

// Helper method to create consistent circular buttons
  Widget _buildCircularButton1({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 35,
        ),
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildCircularButton3({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: Colors.deepPurpleAccent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.deepPurpleAccent,
          size: 24,
        ),
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildCircularButton2({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.deepPurpleAccent,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 35,
        ),
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
