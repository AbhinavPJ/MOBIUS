// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_2/views/achievementsview.dart';
import 'package:flutter_application_2/views/animatedmatch.dart';
import 'package:flutter_application_2/views/card_provider.dart';
import 'package:flutter_application_2/views/mymatchesview.dart';
import 'package:flutter_application_2/views/profileview.dart';
import 'dart:math' as math;
import 'package:flutter_application_2/views/reviewdatesview.dart';
import 'package:provider/provider.dart';

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
  MatchmakingProfile(
      {required this.userId,
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
      this.heleftwiped});

  factory MatchmakingProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
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
        heleftwiped: List<String>.from(data['Heleftwiped'] ?? []));
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

    // Build state indicators
    Widget stateIndicators = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
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

    // Bottom card (if available)
    if (totalCards >= 3) {
      MatchmakingProfile thirdProfile = _stackedProfiles[0];
      double thirdScore = _getScoreForProfile(thirdProfile);
      String thirdBeta = (thirdScore % 100).toStringAsFixed(2);

      stackedCards.add(
        Positioned(
          top: 40.0,
          child: Transform.scale(
            scale: 0.8,
            child: Opacity(
              opacity: 0.4,
              child: BuildCard(thirdProfile, thirdBeta),
            ),
          ),
        ),
      );
    }

    // Middle card (if available)
    if (totalCards >= 2) {
      MatchmakingProfile secondProfile = _stackedProfiles[totalCards - 2];
      double secondScore = _getScoreForProfile(secondProfile);
      String secondBeta = (secondScore % 100).toStringAsFixed(2);

      stackedCards.add(
        Positioned(
          top: 20.0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isTransitioning ? 0.7 : 0.7,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: _isTransitioning ? 0.95 : 0.9,
              child: BuildCard(secondProfile, secondBeta),
            ),
          ),
        ),
      );
    }

    // Front card - handle flipping here but not state switching
    if (totalCards > 0) {
      MatchmakingProfile frontProfile = _stackedProfiles[totalCards - 1];
      double frontScore = _getScoreForProfile(frontProfile);
      String frontBeta = (frontScore % 100).toStringAsFixed(2);

      // Simple flipping mechanism
      Widget frontWidget = _isCardFlipped
          ? _buildDescriptionCard(frontProfile)
          : buildFrontCard(frontProfile, frontBeta);

      stackedCards.add(frontWidget);
    }

    return Column(
      children: [
        stateIndicators,
        const SizedBox(height: 10),
        SizedBox(
          height: 520, // Fixed height for card stack
          child: Stack(
            alignment: Alignment.center,
            children: stackedCards,
          ),
        ),
      ],
    );
  }

// Simplified description card without any transformation logic
  Widget _buildDescriptionCard(MatchmakingProfile profile) {
    return Container(
      width: 350,
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            profile.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
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

  // New method to build a flippable card

  Widget buildFrontCard(MatchmakingProfile currentMatch, String beta) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          // Tap on card cycles through info states
          onTap: _cycleDisplayState,
          child: Consumer<CardProvider>(
            builder: (context, provider, child) {
              final angle = (provider.angle) * math.pi / 180;
              final center = constraints.smallest.center(Offset.zero);

              // Only apply the swipe rotation
              final rotatedMatrix = Matrix4.identity()
                ..translate(center.dx, center.dy)
                ..rotateZ(angle)
                ..translate(-center.dx, -center.dy);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 0),
                transform: rotatedMatrix
                  ..translate(provider.position.dx, provider.position.dy),
                child: BuildCard(currentMatch, beta),
              );
            },
          ),
          // Pan gestures for swiping
          onPanStart: (details) {
            Provider.of<CardProvider>(context, listen: false)
                .startPosition(details);
          },
          onPanUpdate: (details) {
            Provider.of<CardProvider>(context, listen: false)
                .updatePosition(details);
          },
          onPanEnd: (details) {
            final provider = Provider.of<CardProvider>(context, listen: false);
            provider.endPosition();

            // Check swipe result
            final status = provider.getStatus();

            if (status != SwipeStatus.none) {
              // Handle swipe based on direction
              if (status == SwipeStatus.like) {
                _handleSwipeRight();
              } else if (status == SwipeStatus.dislike) {
                _handleSwipeLeft();
              }

              // Reset card position
              provider.resetPosition();
            }
          },
        );
      },
    );
  }

// Modified to handle different display states only (not flipping)
  Widget buildInfo(MatchmakingProfile profile, String beta) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.name,
          style: const TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 10, color: Colors.black)],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          displayText,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
            shadows: [Shadow(blurRadius: 10, color: Colors.black)],
          ),
        ),
      ],
    );
  }

  Widget BuildCard(MatchmakingProfile currentMatch, String beta) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Background image
          Container(
            width: 350,
            height: 500,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(currentMatch.profilePicture),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Gradient overlay at the bottom for better readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
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

          // Profile info at the bottom left with updated info display
          Positioned(
            bottom: 20,
            left: 20,
            child: buildInfo(currentMatch, beta),
          ),
        ],
      ),
    );
  }

  // Update buildFrontCard to handle the flip gesture

  // Update the _handleSwipeLeft and _handleSwipeRight for seamless transitions
  void _handleSwipeLeft() async {
    if (_isTransitioning) return;

    if (potentialMatches.isNotEmpty) {
      setState(() {
        _isTransitioning = true;
        _isCardFlipped = false; // Reset flip state for new card
      });

      // Pre-fetch the next stack while animation is happening
      DocumentReference matchRef = FirebaseFirestore.instance
          .collection('surveys')
          .doc(currentUserProfile!.userId);

      // Update Firebase in the background, don't wait for it
      matchRef.update({
        'Heleftwiped': FieldValue.arrayUnion(
            [potentialMatches[potentialMatches.length - 1].userId])
      });

      // Animate transition but prepare next card immediately
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
      return "Department of Chemical Engineering";
    }
    if (code == "CE") {
      return "Department of Civil Engineering";
    }
    if (code == "EE") {
      return "Department of Electrical Engineering";
    }
    if (code == "CS") {
      return "Department of Computer Science";
    }
    if (code == "ES") {
      return "Department of Energy Sciences";
    }
    if (code == "MS") {
      return "Department of Material Sciences";
    }
    if (code == "MT") {
      return "Department of Mathematics";
    }
    if (code == "ME") {
      return "Department of Mechanical Engineering";
    }
    if (code == "PH") {
      return "Department of Physics";
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

  Future<void> _fetchUserProfiles() async {
    try {
      print("Fetching user profile...");
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Fetch current user's survey document instead of users collection
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('surveys')
          .doc(currentUser.uid)
          .get();

      // Ensure document exists before creating profile
      if (!currentUserDoc.exists) {
        print("No survey document found for current user");
        return;
      }

      // Create currentUserProfile safely
      MatchmakingProfile tempProfile =
          MatchmakingProfile.fromFirestore(currentUserDoc);

      // Verify all critical fields are populated
      if (tempProfile.userId.isEmpty ||
          tempProfile.gender.isEmpty ||
          tempProfile.entryNumber.isEmpty) {
        print("Incomplete user profile data");
        return;
      }

      // Set state with the complete profile
      if (mounted) {
        setState(() {
          currentUserProfile = tempProfile;
        });
      }

      // Now fetch potential matches
      String oppositeGender =
          currentUserProfile!.gender == 'MALE' ? 'FEMALE' : 'MALE';

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('surveys')
          .where('userId', isNotEqualTo: currentUser.uid)
          .where('gender', isEqualTo: oppositeGender)
          .get();

      List<MatchmakingProfile> fetchedProfiles = querySnapshot.docs
          .map((doc) => MatchmakingProfile.fromFirestore(doc))
          .toList();

      // Rank matches only if profile is completely loaded
      if (currentUserProfile != null && mounted) {
        rankedMatches = _rankMatches(fetchedProfiles);

        setState(() {
          potentialMatches = rankedMatches.map((entry) => entry.key).toList();
          len = potentialMatches.length;
        });

        // Load first description
        if (potentialMatches.isNotEmpty) {
          _loadProfileDescription(potentialMatches[currentMatchIndex]);
        }
      }
    } catch (e) {
      print("Error fetching user profiles: $e");
    }
  }

  Future<void> _loadProfileDescription(MatchmakingProfile profile) async {
    if (!mounted) return;

    setState(() {
      isLoadingDescription = true;
      currentDescription = null;
    });

    try {
      String description = profile.description;

      if (mounted) {
        setState(() {
          currentDescription = description;
          isLoadingDescription = false;
        });
      }
    } catch (e) {
      print("Error generating description: $e");
      if (mounted) {
        setState(() {
          currentDescription = "Could not generate profile description.";
          isLoadingDescription = false;
        });
      }
    }
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
      backgroundColor: Colors.white,
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
    // Show thank you page when no more profiles or flag is set
    if (_showThankYouPage || potentialMatches.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(context),
        bottomNavigationBar: _buildBottomBar(context),
        backgroundColor: Colors.white,
        body: _buildThankYouPage(),
      );
    }

    if (_stackedProfiles.isEmpty && potentialMatches.isNotEmpty) {
      _prepareCardStack();
    }

    // Original UI with correctly wired controls
    return Scaffold(
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildBottomBar(context),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 5),
          // Card stack with state indicators
          _buildCardStack(),
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildCircularButton1(
                icon: Icons.close,
                onPressed: () {
                  // Handle swipe left/dislike
                  _handleSwipeLeft();
                }),
            const SizedBox(width: 20),
            _buildCircularButton3(
                icon: _isCardFlipped ? Icons.flip_to_front : Icons.flip_to_back,
                onPressed: () {
                  // ONLY flip the card here - no state change
                  _flipCard();
                }),
            const SizedBox(width: 20),
            _buildCircularButton2(
                icon: Icons.check,
                onPressed: () {
                  // Handle swipe right/like
                  _handleSwipeRight();
                }),
          ])
        ],
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

    _stackedProfiles = [];
    final int totalCards = potentialMatches.length;

    // Always show at least one card, but up to 3 if available
    int startIndex = math.max(0, totalCards - 3);

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
