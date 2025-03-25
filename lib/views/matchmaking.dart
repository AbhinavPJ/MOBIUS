// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_2/views/achievementsview.dart';
import 'package:flutter_application_2/views/animatedmatch.dart';
import 'package:flutter_application_2/views/mymatchesview.dart';
import 'package:flutter_application_2/views/profileview.dart';
import 'dart:math' as math;
import 'package:flutter_application_2/views/reviewdatesview.dart';

class HomePage extends StatelessWidget {
  final MatchmakingProfile profile;
  final double n1, n2, n3, n4, n5, n6, n7, n8, n9, n10;
  const HomePage({
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
    required this.profile,
  }) : super(key: key);

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.black,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center items
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 40,
          ),
          const SizedBox(width: 10), // Add some spacing between logo and button
          ElevatedButton(
            onPressed: () {
              // Button action here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, // Set background to black
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Rounded edges
              ),
            ),
            child: const Text(
              "MOBIUS",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 179, 255, 1), // Light green text
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0D0D),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    _buildOptionCard(
                      context,
                      "Achievements",
                      Icons.emoji_events,
                      AchievementsView(profile: profile),
                    ),
                    _buildOptionCard(
                      context,
                      "My Profile",
                      Icons.person,
                      ProfileView(
                        profile: profile,
                        onProfileUpdated: () {},
                      ),
                    ),
                    _buildOptionCard(
                      context,
                      "My Matches",
                      Icons.favorite,
                      MyMatchesView(
                          n1: n1,
                          n2: n2,
                          n3: n3,
                          n4: n4,
                          n5: n5,
                          n6: n6,
                          n7: n7,
                          n8: n8,
                          n9: n9,
                          n10: n10),
                    ),
                    _buildOptionCard(
                      context,
                      "Review Your Date",
                      Icons.rate_review,
                      ReviewDatePage(
                          n1: n1,
                          n2: n2,
                          n3: n3,
                          n4: n4,
                          n5: n5,
                          n6: n6,
                          n7: n7,
                          n8: n8,
                          n9: n9,
                          n10: n10),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MatchmakingScreen(
                          flag: true,
                          n1: n1,
                          n2: n2,
                          n3: n3,
                          n4: n4,
                          n5: n5,
                          n6: n6,
                          n7: n7,
                          n8: n8,
                          n9: n9,
                          n10: n10),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Enter Matchmaking Arena",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildOptionCard(
    BuildContext context, String title, IconData icon, Widget destination) {
  return GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    ),
    child: Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: Colors.pinkAccent),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  // New animation controllers for swipe transitions
  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _fadeAnimation;

  final _random = math.Random();
  bool _isMatchPopupShown = false; // Add this to your class
  bool _isAnimating = false; // Track if the card was accepted or rejected
  bool _isFrontVisible = true;
  bool _isLastProfile = false; // Add this to your state variables
  MatchmakingProfile? currentUserProfile;
  List<MatchmakingProfile> potentialMatches = [];
  List<MapEntry<MatchmakingProfile, double>> rankedMatches = [];
  int currentMatchIndex = 0;
  String? currentDescription;
  bool isLoadingDescription = false;

  @override
  void initState() {
    super.initState();

    // Initialize the flip animation controller
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_flipController)
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    // Initialize the swipe animation controller
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0), // Will be updated based on swipe direction
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

    _swipeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishSwipeTransition();
      }
    });
    _fetchUserProfiles();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_flipController.status != AnimationStatus.forward &&
        _flipController.status != AnimationStatus.reverse) {
      if (_isFrontVisible) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
      if (mounted) {
        setState(() {
          _isFrontVisible = !_isFrontVisible;
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
      ..sort((a, b) => b.value
          .compareTo(a.value)); // Sort in descending order of match score
  }

  // Placeholder match score calculation
  double _calculateMatchScore(MatchmakingProfile profile) {
    if (currentUserProfile == null) {
      return 0.0;
    }
    print(currentUserProfile!.name);
    if ((profile.name) == "peeeejaaayyy") {
      return -200.0;
    }
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

  // Helper method to reset and prepare for next animation
  void _moveToNextMatch({bool accepted = false}) {
    if (!mounted) return;

    // First, check if this is the last profile
    bool isLastProfile = currentMatchIndex + 1 >= potentialMatches.length;

    // If it's the last profile and the user accepted, handle the match first
    if (isLastProfile && accepted && currentUserProfile != null) {
      // Store the current match before animation
      final currentMatch = potentialMatches[currentMatchIndex];

      // Process the match logic first
      AClogic(currentUserProfile!, currentMatch).then((isMatch) {
        // If it's a match, we'll let the match popup handle navigation
        if (mounted) {
          // Only go to final page if it's not a match
          _prepareForNextAnimation(accepted, isLastProfile);
          _swipeController.forward();
        }
      });
    } else {
      // For non-last profiles or rejections, continue as before
      _prepareForNextAnimation(accepted, isLastProfile);
      _swipeController.forward();
    }

    // Make sure card is showing front side for the next profile
    if (!_isFrontVisible) {
      _flipCard();
    }
  }

// Helper method to reset and prepare for next animation
  void _prepareForNextAnimation(bool accepted, bool isLastProfile) {
    if (mounted) {
      // Generate random vertical offset between -0.5 and 0.5
      double randomVerticalOffset = (_random.nextDouble() - 0.5);
      // Generate random rotation angle between -0.2 and 0.2 radians

      setState(() {
        _isAnimating = true;
        _isLastProfile = isLastProfile;

        // Set the horizontal direction based on acceptance
        double horizontalDirection = accepted ? 1.5 : -1.5;

        // Create the animation with random vertical component
        _swipeAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: Offset(horizontalDirection, randomVerticalOffset),
        ).animate(CurvedAnimation(
          parent: _swipeController,
          curve: Curves.easeOut,
        ));

        // Add rotation to the animation
      });
    }
  }

// Complete the transition after animation
  void _finishSwipeTransition() {
    if (!mounted) return;

    // Check if this was the last profile

    setState(() {
      _isAnimating = false;
      _swipeController.reset();

      // Make sure card is showing front side for the next profile
      if (!_isFrontVisible) {
        _isFrontVisible = true;
      }

      // Now increment the index after animation completes
      currentMatchIndex = (currentMatchIndex + 1) % potentialMatches.length;

      // Load the description for the new profile
      _loadProfileDescription(potentialMatches[currentMatchIndex]);
    });
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

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 35,
              ),
              onPressed: () => _showAchievemnts(context),
              tooltip: 'Achievements',
            ),
          ),
          const SizedBox(width: 40),
          // Change logo to be a button
          GestureDetector(
            onTap: () {
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
                ),
              );
            },
            child: Image.asset(
              'assets/images/logo.png',
              height: 40,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(
                      profile: currentUserProfile!,
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
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, // Set background to black
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Rounded edges
              ),
            ),
            child: const Text(
              "MOBIUS",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 179, 255, 1), // Light green text
              ),
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        // Profile button
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            icon: Icon(
              Icons.account_circle,
              color: Colors.white,
              size: 35,
            ),
            onPressed: () => _showProfileDialog(context),
            tooltip: 'View Profile',
          ),
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0, 0, 0, 1),
              Color.fromRGBO(0, 0, 0, 1),
            ],
          ),
        ),
      ),
      elevation: 0,
    );
  }

  void _showAchievemnts(BuildContext context) {
    if (currentUserProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile is still loading. Please try again.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AchievementsView(profile: currentUserProfile!),
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    if (currentUserProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile is still loading. Please try again.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileView(
          profile: currentUserProfile!,
          onProfileUpdated: () {
            _fetchUserProfiles(); // Refresh profile data
          },
        ),
      ),
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

  // Update the build method to use mounted check instead of _isDisposed
  @override
  Widget build(BuildContext context) {
    if (potentialMatches.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 0, 0, 0),
                Color.fromARGB(255, 0, 0, 0)
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        color:
                            Colors.redAccent, // Match the previous icon color
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Oh no!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We couldn't find any matches for you.\nTry your luck again later!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (!widget.flag) {
      return HomePage(
          profile: currentUserProfile!,
          n1: widget.n1,
          n2: widget.n2,
          n3: widget.n3,
          n4: widget.n4,
          n5: widget.n5,
          n6: widget.n6,
          n7: widget.n7,
          n8: widget.n8,
          n9: widget.n9,
          n10: widget.n10);
    }
    MatchmakingProfile currentMatch = potentialMatches[currentMatchIndex];
    double matchScore = rankedMatches[currentMatchIndex].value;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 0, 0, 0),
              Color.fromARGB(255, 0, 0, 0)
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              children: [
                // Current profile card with swipe animation
                SlideTransition(
                  position: _swipeAnimation,
                  child: Transform(
                    transform:
                        Matrix4.rotationY(_flipAnimation.value * math.pi),
                    alignment: Alignment.center,
                    child: _isFrontVisible
                        ? _buildFrontCard(currentMatch, matchScore)
                        : _buildBackCard(currentMatch),
                  ),
                ),

                // Fade in next profile card if animating
                if (_isAnimating &&
                    currentMatchIndex + 1 < potentialMatches.length)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform(
                      transform: Matrix4.rotationY(0),
                      alignment: Alignment.center,
                      child: _buildFrontCard(
                        potentialMatches[
                            (currentMatchIndex + 1) % potentialMatches.length],
                        rankedMatches[
                                (currentMatchIndex + 1) % rankedMatches.length]
                            .value,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard(MatchmakingProfile currentMatch) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(math.pi),
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
                      child: isLoadingDescription
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.deepOrange,
                              ),
                            )
                          : SingleChildScrollView(
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
                                    currentDescription ??
                                        'No description available',
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
                  child: TextButton(
                    onPressed: _flipCard,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      "Flip Back",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
            child: Center(
              child: ClipOval(
                child: Image.network(
                  currentMatch.profilePicture,
                  width: 180, // Same size as front
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update the _buildFrontCard method to use the modified AClogic without context
  Widget _buildFrontCard(MatchmakingProfile currentMatch, double matchScore) {
    String beta = (matchScore % 100).toStringAsFixed(2);
    if (currentMatch.name == "peeeejaaayyy") {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Card with Same Shape and Styling
          Container(
            width: 390,
            height: 660,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.yellow,
                width: 6,
              ),
              color: const Color.fromARGB(255, 46, 49, 73),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 240),
                Text(
                  "That's all for today!",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Text(
                  "You've seen all potential matches for now. Check back tomorrow for new matches!",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, 'matched'); // Returns to home page
                  },
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
          // Profile Image Positioned Above Card

          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Profile Image (Moved Up)

        // Background Container
        Container(
          width: 390,
          height: 660,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.yellow,
              width: 6,
            ),
            color: Color.fromARGB(255, 46, 49, 73),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Added space since image moved up
              const SizedBox(height: 240),
              Text(
                currentMatch.name,
                style: TextStyle(
                  fontSize: 25,
                  fontFamily: "assets/fonts/futura.ttf",
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 254, 254, 254),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                currentMatch.tagline,
                style: TextStyle(
                    fontSize: 14,
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontFamily: "assets/fonts/futura.ttf",
                    fontWeight: FontWeight.normal,
                    fontStyle: FontStyle.normal),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7B61FF),
                      Color(0xFFFF477E)
                    ], // Purple to Pink
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextButton(
                  onPressed: _flipCard,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    "Flip Me",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 40,
                        child: Image.asset("assets/images/fire.png",
                            height: 40, width: 40),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Match Score : $beta",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 40,
                        child: Image.asset("assets/images/hourglass.png",
                            height: 40, width: 40),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        Fetchyear(currentMatch),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 40,
                        child: Image.asset("assets/images/college.png",
                            height: 40, width: 40),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          Fetchdept(currentMatch),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      /// 🔴 PASS BUTTON
                      ClipPath(
                        clipper: CustomShapeClipper(),
                        child: ElevatedButton(
                          onPressed: () async {
                            DocumentReference matchRef = FirebaseFirestore
                                .instance
                                .collection('surveys')
                                .doc(currentUserProfile!.userId);

                            await matchRef.update({
                              'Heleftwiped':
                                  FieldValue.arrayUnion([currentMatch.userId])
                            });
                            _moveToNextMatch(accepted: false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0)),
                          ),
                          child: const Text(
                            "PASS",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),

                      /// 🟢 ACCEPT BUTTON
                      ClipPath(
                        clipper: CustomShapeClipper(),
                        child: ElevatedButton(
                          onPressed: () {
                            if (currentUserProfile != null) {
                              AClogic(currentUserProfile!, currentMatch);
                              _moveToNextMatch(accepted: true);
                              print(_isLastProfile);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0)),
                          ),
                          child: const Text(
                            "ACCEPT",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Center(
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Profile Image with Loading Indicator
                  Image.network(
                    currentMatch.profilePicture,
                    width: 180, // Adjust size as needed
                    height: 180,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child; // Image is fully loaded
                      }
                      return SizedBox(
                        width: 180,
                        height: 180,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                            color: Colors.white, // Change color if needed
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 180,
                        height: 180,
                        color: Colors.grey[300], // Fallback color
                        child: const Icon(Icons.person,
                            size: 80, color: Colors.grey),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height * 0.2);
    path.lineTo(size.width * 0.1, 0);
    path.lineTo(size.width * 0.9, 0);
    path.lineTo(size.width, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.8);
    path.lineTo(size.width * 0.9, size.height);
    path.lineTo(size.width * 0.1, size.height);
    path.lineTo(0, size.height * 0.8);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
