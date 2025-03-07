import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_2/views/profileview.dart';
import 'package:groq/groq.dart';
import 'dart:math' as math;

final groq = Groq(
  apiKey: "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",
  model: "llama-3.3-70b-versatile", // Optional: specify a model
);

Future<String> getLLMReply(String prompt) async {
  groq.startChat();
  GroqResponse response = await groq.sendMessage(prompt);
  return (response.choices.first.message.content);
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
      this.rightswipedby});

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
        rightswipedby: List<String>.from(data['rightswipedby']));
  }
}

class MatchmakingScreen extends StatefulWidget {
  @override
  _MatchmakingScreenState createState() => _MatchmakingScreenState();
}

// Removing _isDisposed state variable and related code
class _MatchmakingScreenState extends State<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller for the flip card
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFrontVisible = true;

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

    _fetchUserProfiles();
  }

  @override
  void dispose() {
    _flipController.dispose();
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

    double score = 0.0;
    var n1 = 0.01;
    var n2 = 20.0;
    var n3 = 20.0;
    var n4 = 5.0;
    var n5 = 10.0;
    var n6 = 5.0;
    var n7 = 15.0;
    var n8 = 15.0;
    var n9 = 15.0;
    var n10 = 15.0;
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

  void _makefinalmpage() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: _buildAppBar(context),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(1, 111, 162, 0.82),
                  Color.fromRGBO(15, 172, 36, 0.653),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
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
                  border: Border.all(color: Color(0xFFFFD700), width: 5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "That's all for today!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "You've seen all potential matches for now. Check back tomorrow for new matches!",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

  void _moveToNextMatch() {
    if (!mounted) return;

    setState(() {
      // Make sure card is showing front side for the next profile
      if (!_isFrontVisible) {
        _flipCard();
      }
      if (currentMatchIndex + 1 == potentialMatches.length) {
        _makefinalmpage();
        return;
      }
      currentMatchIndex = (currentMatchIndex + 1) % potentialMatches.length;

      // Load the description for the new profile
      _loadProfileDescription(potentialMatches[currentMatchIndex]);
    });
  }

  void _moveToPreviousMatch() {
    if (!mounted) return;

    setState(() {
      // Make sure card is showing front side for the next profile
      if (!_isFrontVisible) {
        _flipCard();
      }

      currentMatchIndex = (currentMatchIndex - 1 + potentialMatches.length) %
          potentialMatches.length;

      // Load the description for the new profile
      _loadProfileDescription(potentialMatches[currentMatchIndex]);
    });
  }

  Future<String> _generateProfileDescription(
      MatchmakingProfile currentMatch) async {
    String promptu = """
Generate a short,sweet,insightful,fun,quirky,positive description of a person based on the following characteristics.The goal is to create a relationship
 between the person described and the person reading this.
 Try to infer from the fields below what a person might actually be like in person:

Name: ${currentMatch.name}
Gender: ${currentMatch.gender}

Interests:
- Clubs: ${currentMatch.clubs.join(', ')}
- Sports: ${currentMatch.sports.join(', ')}
- Movie Genres: ${currentMatch.movieGenres.join(', ')}
- Music Genres: ${currentMatch.musicGenres.join(', ')}
- Hangout Spot: ${currentMatch.hangoutSpot}
- Relationship Type: ${currentMatch.relationshipType}

here is what each club means:

Aeromodelling: Design,Construction,Flying of model aircraft by applying aerodynamic analysis
AXLR8R: Engineers create a superfast open-wheel formula-one style electric car within a year
PAC: Physics and Astronomy club
ANCC: Algorithms and competitive coding club (Incredibly smart people here)
DevClub: Association of Frontend,backend,Appdev,Cybersecurity engineers
Economics club:Economics club
Business and Consulting club:Business and consulting club
"Robotics": Robotics club
"ARIES": AI/ML society of IIT Delhi
"Infinity hyperloop": work on building a working prototype hyperloop
"IGTS": Game theory society,
"iGEM":Biotech/ Bioinformatics related club,
"BlocSoc": Crypto/blockchain enthusiasts,
"PFC": Photography and Films club,
"Music Club": Musics club,
"FACC":Painting,designing stuff and designing fashion(creative people here),
"Debsoc":Debate society,
"Lit club":Literary club (discuss books,word games),
"QC": Quizzing club,
"Design club":Do pretty stuff like UI/UX design,photo editing,graphics, VFX ,
"Dance club":they dance
"Drama club":Drama club,
"Spic Macay":Classical dance,
""";
    return await getLLMReply(promptu);
  }

  Future<void> _loadProfileDescription(MatchmakingProfile profile) async {
    if (!mounted) return;

    setState(() {
      isLoadingDescription = true;
      currentDescription = null;
    });

    try {
      String description = await _generateProfileDescription(profile);

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
        _showMatchPopup(currentUser, match);
        _sendMatchNotification(currentUser, match);
        return true;
        // Check if the widget is still mounted before showing the popup
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
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 40,
          ),
          const SizedBox(width: 10),
          const Text(
            "MOBIUS",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
              size: 30,
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
              Color.fromRGBO(0, 23, 45, 1),
              Color.fromRGBO(0, 82, 162, 1),
            ],
          ),
        ),
      ),
      elevation: 0,
    );
  }

  void _showProfileDialog(BuildContext context) {
    if (currentUserProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile is still loading. Please try again.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ProfileView(
            profile: currentUserProfile!,
            onProfileUpdated: () {
              // Refresh data after profile update
              _fetchUserProfiles();
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  // Updated _showMatchPopup to use the current context
  void _showMatchPopup(
      MatchmakingProfile currentUser, MatchmakingProfile match) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 10),
            Text("It's a Match! 🎉",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(
                "You and ${match.name} have matched! Whatsapp on ${match.number}",
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: Text("Awesome!"),
            ),
          ],
        ),
      ),
    );
  }

  // Update the build method to use mounted check instead of _isDisposed
  @override
  Widget build(BuildContext context) {
    if (potentialMatches.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.brown[50],
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 40,
              ),
              const SizedBox(width: 10),
              const Text(
                "MOBIUS",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE53935),
                  Color(0xFFFFC107),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
        ),
        body: Center(
          child: Text(
            "No matches found.",
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
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
              Color.fromRGBO(1, 111, 162, 0.82),
              Color.fromRGBO(15, 172, 36, 0.653),
            ],
          ),
        ),
        child: GestureDetector(
          // Handle vertical swipes for next/previous profile
          onVerticalDragEnd: (details) {
            if (details.velocity.pixelsPerSecond.dy > 0) {
              _moveToPreviousMatch();
            } else if (details.velocity.pixelsPerSecond.dy < 0) {
              _moveToNextMatch();
            }
          },
          // Handle horizontal swipes and taps for card flip
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              _flipCard();
            }
          },
          onTap: () {
            _flipCard();
          },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Transform(
                transform: Matrix4.rotationY(_flipAnimation.value * math.pi),
                alignment: Alignment.center,
                child: _isFrontVisible
                    ? _buildFrontCard(currentMatch, matchScore)
                    : _buildBackCard(currentMatch),
              ),
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
      child: Container(
        width: 390,
        height: 660,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFFFD700), width: 10),
          color: Colors.blue.shade400,
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                currentMatch.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoadingDescription
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.deepOrange,
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profile Insights:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                currentDescription ??
                                    'No description available',
                                style: TextStyle(
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

            // Info on how to flip back
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Tap to flip back',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update the _buildFrontCard method to use the modified AClogic without context
  Widget _buildFrontCard(MatchmakingProfile currentMatch, double matchScore) {
    String beta = (matchScore % 100).toStringAsFixed(2);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Profile Image (Moved Up)
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Center(
            child: ClipRRect(
              child: Image.network(
                currentMatch.profilePicture,
                width: 340,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // Background Container
        Container(
          width: 390,
          height: 660,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0xFFFFD700), width: 10),
            image: DecorationImage(
              image: AssetImage('assets/images/poke.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Added space since image moved up
              const SizedBox(height: 7),
              Text(
                currentMatch.name,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: "assets/fonts/futura.ttf",
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 307),
              Text(
                currentMatch.tagline,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontFamily: "assets/fonts/times.ttf",
                    fontWeight: FontWeight.normal,
                    fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),
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
                        ),
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
                        ),
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
                              fontWeight: FontWeight.bold, fontSize: 20),
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
                          onPressed: () => _moveToNextMatch(),
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
                              // Call AClogic without the context parameter

                              AClogic(currentUserProfile!, currentMatch).then(
                                  (isMatch) =>
                                      {if (!isMatch) _moveToNextMatch()});
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
