import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_2/views/matchmaking.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewDatePage extends StatefulWidget {
  final n1, n2, n3, n4, n5, n6, n7, n8, n9, n10;
  const ReviewDatePage({
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
  }) : super(key: key);

  @override
  _ReviewDatePageState createState() => _ReviewDatePageState();
}

class _ReviewDatePageState extends State<ReviewDatePage> {
  bool _isLoading = true;
  List<MatchData> _matches = [];
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('surveys')
          .doc(_currentUserId)
          .get();

      if (!currentUserDoc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      MatchmakingProfile currentUserProfile =
          MatchmakingProfile.fromFirestore(currentUserDoc);

      List<String> myRightSwipes = currentUserProfile.rightswipedby ?? [];

      // Fetch rated matches
      DocumentSnapshot ratedDoc = await FirebaseFirestore.instance
          .collection('ratings')
          .doc(_currentUserId)
          .get();

      List<String> ratedProfiles = [];
      if (ratedDoc.exists && ratedDoc.data() != null) {
        ratedProfiles = List<String>.from(ratedDoc['rated'] ?? []);
      }

      QuerySnapshot potentialMatches = await FirebaseFirestore.instance
          .collection('surveys')
          .where('rightswipedby', arrayContains: _currentUserId)
          .get();

      List<MatchData> loadedMatches = [];

      for (var doc in potentialMatches.docs) {
        String otherUserId = doc.id;

        // Skip if already rated or not mutually right-swiped
        if (ratedProfiles.contains(otherUserId) ||
            !myRightSwipes.contains(otherUserId)) {
          continue;
        }

        MatchmakingProfile otherUserProfile =
            MatchmakingProfile.fromFirestore(doc);

        double matchScore =
            _calculateMatchScore(currentUserProfile, otherUserProfile);

        loadedMatches.add(
          MatchData(
            matchId: '${_currentUserId}_$otherUserId',
            userId: otherUserId,
            name: otherUserProfile.name,
            profilePicture: otherUserProfile.profilePicture,
            matchScore: matchScore,
            contactNumber: otherUserProfile.number,
            hostel: otherUserProfile.hostel,
            entryNumber: otherUserProfile.entryNumber,
          ),
        );
      }

      loadedMatches.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      setState(() {
        _matches = loadedMatches;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching matches: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateMatchScore(
      MatchmakingProfile currentUserProfile, MatchmakingProfile profile) {
    double score = 0.0;
    var n1 = widget.n1;
    var n2 = widget.n2;
    var n3 = widget.n3;
    var n4 = widget.n4;
    var n5 = widget.n5;
    var n6 = widget.n6;
    var n7 = widget.n7;
    var n8 = widget.n8;
    var n9 = widget.n9;
    var n10 = widget.n10;
    score += n1 *
        (_calculatePersonalityOverlap(
            currentUserProfile.personality, profile.personality));

    //print("hereiii");
    //print(currentUserProfile?.gender);

    //print(currentUserProfile?.entryNumber);
    score +=
        n2 * (ismatchyear(currentUserProfile.entryNumber, profile.entryNumber));
    // Compare interests
    //print(profile.entryNumber);
    //print("ohh fuck");
    //print(currentUserProfile!.entryNumber);

    score +=
        n3 * (ismatchdept(currentUserProfile.entryNumber, profile.entryNumber));

    //print("oh bsdk");
    score += n4 *
        (ismatchpopularity(currentUserProfile.popularity, profile.popularity));

    score += n5 *
        (ismatchhangout(currentUserProfile.hangoutSpot, profile.hangoutSpot));

    //print('hereeeeiiiii');
    score += n6 *
        ismatchrelationship(
            currentUserProfile.relationshipType, profile.relationshipType);

    //print("mcccc");
    score += n7 *
        _calculateInterestOverlap(currentUserProfile.sports, profile.sports) *
        2;

    score +=
        n8 * _calculateInterestOverlap(currentUserProfile.clubs, profile.clubs);

    score += n9 *
        _calculateInterestOverlap(
            currentUserProfile.movieGenres, profile.movieGenres);

    score += n10 *
        _calculateInterestOverlap(
            currentUserProfile.musicGenres, profile.musicGenres);
    //print("hereiiiiiiiiiiiii");
    if (currentUserProfile.rightswipedby != null &&
        currentUserProfile.rightswipedby!.contains(profile.userId)) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Removes shadow for a clean look
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png', // Replace with your logo path
              height: 40,
            ),
            const SizedBox(width: 10),
            const Text(
              "MOBIUS", // Replace with your app name
              style: TextStyle(
                fontSize: 32,
                fontFamily: 'Cinzel',
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 255, 255, 255),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.deepOrange,
                ),
              )
            : _matches.isEmpty
                ? _buildEmptyState()
                : _buildMatchesList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade50,
              Colors.purple.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.shade200.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.purple.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              "Nothing left to review",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "You've reviewed all your current matches. Keep exploring!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.purple.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        return _buildMatchCard(match);
      },
    );
  }

  Widget _buildMatchCard(MatchData match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color.fromARGB(189, 114, 92, 174), width: 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE3F2FD), // Soft pastel blue
            const Color(0xFFF3E5F5), // Very soft lavender
            const Color(0xFFFAFAFA), // Almost white
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: ExpansionTile(
          collapsedIconColor: Colors.black,
          iconColor: Colors.black,
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          title: Row(
            children: [
              Hero(
                tag: 'match-${match.userId}',
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color.fromARGB(189, 114, 92, 174),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: match.profilePicture.isNotEmpty
                        ? NetworkImage(match.profilePicture)
                        : null,
                    child: match.profilePicture.isEmpty
                        ? const Icon(Icons.person,
                            size: 32, color: Colors.white70)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Image.asset(
                          "assets/images/fire.png",
                          height: 20,
                          width: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Match Score: ${(match.matchScore % 200).toStringAsFixed(1)}%",
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE3F2FD), // Soft pastel blue
                    const Color(0xFFF3E5F5), // Very soft lavender
                    const Color(0xFFFAFAFA), // Almost white
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white30),
                  const SizedBox(height: 8),
                  _buildRatingSection(match),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(MatchData match) {
    double _rating = 0.0; // Stores the selected rating

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Rate this Match",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 10),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await _submitRating(match.userId, _rating, context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                "Submit Rating",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, double>> _fetchCoefficients() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("coefficients")
          .doc("1")
          .get();

      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

      if (data == null) {
        // Return default values if document doesn't exist or is empty
        return {
          "n1": 0.01,
          "n2": 20.0,
          "n3": 20.0,
          "n4": 5.0,
          "n5": 10.0,
          "n6": 5.0,
          "n7": 15.0,
          "n8": 15.0,
          "n9": 15.0,
          "n10": 15.0,
        };
      }
      print(data);
      return {
        "n1": _parseDoubleOrDefault(data["n1"], 0.01),
        "n2": _parseDoubleOrDefault(data["n2"], 20.0),
        "n3": _parseDoubleOrDefault(data["n3"], 20.0),
        "n4": _parseDoubleOrDefault(data["n4"], 5.0),
        "n5": _parseDoubleOrDefault(data["n5"], 10.0),
        "n6": _parseDoubleOrDefault(data["n6"], 5.0),
        "n7": _parseDoubleOrDefault(data["n7"], 15.0),
        "n8": _parseDoubleOrDefault(data["n8"], 15.0),
        "n9": _parseDoubleOrDefault(data["n9"], 15.0),
        "n10": _parseDoubleOrDefault(data["n10"], 15.0),
      };
    } catch (e) {
      print("Error fetching coefficients: $e");
      // Return default values on error instead of empty map
      return {
        "n1": 0.01,
        "n2": 20.0,
        "n3": 20.0,
        "n4": 5.0,
        "n5": 10.0,
        "n6": 5.0,
        "n7": 15.0,
        "n8": 15.0,
        "n9": 15.0,
        "n10": 15.0,
      };
    }
  }

  double _parseDoubleOrDefault(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;

    if (value is num) return value.toDouble();

    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return defaultValue;
      }
    }

    return defaultValue;
  }

  Future<void> _submitRating(
      String matchId, double rating, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('ratings')
          .doc(_currentUserId)
          .set({
        'rated': FieldValue.arrayUnion([matchId])
      }, SetOptions(merge: true));

      setState(() {
        _matches.removeWhere((match) => match.userId == matchId);
      });

      // Fetch user profiles
      final user1id = _currentUserId;
      final user2id = matchId;
      final doc1 = await FirebaseFirestore.instance
          .collection('surveys')
          .doc(user1id)
          .get();
      final doc2 = await FirebaseFirestore.instance
          .collection('surveys')
          .doc(user2id)
          .get();

      MatchmakingProfile user1 = MatchmakingProfile.fromFirestore(doc1);
      MatchmakingProfile user2 = MatchmakingProfile.fromFirestore(doc2);

      final coeffs = await _fetchCoefficients();
      final similarity = _calculatesimilarity(user1, user2);
      final avg = await avgsimilarity();

      final Map<String, double> normalizationFactors = {
        'n1': 2000.0,
        'n2': 1.0, // Year match
        'n3': 1.0, // Department match
        'n4': 2.0, // Popularity match
        'n5': 1.0, // Hangout match
        'n6': 3.0, // Relationship match
        'n7': 2.0, // Sports interests
        'n8': 1.0, // Clubs interests
        'n9': 1.0, // Movie genres
        'n10': 1.0, // Music genres
      };

      final double baseLearningRate = 0.001; // 5% adjustment potential

      // New method for updating coefficients
      print(coeffs);
      Map<String, double> updatedCoeffs = {};
      for (int i = 1; i <= 10; i++) {
        String key = 'n$i';

        // Normalize the current similarity
        double currentSimilarity = similarity[i - 1] ?? 0;
        double normalizedSimilarity =
            currentSimilarity / normalizationFactors[key]!;

        // Normalize the average similarity
        double averageSimilarity = avg[key] ?? 0;
        double normalizedAverageSimilarity =
            averageSimilarity / normalizationFactors[key]!;
        double error =
            (normalizedSimilarity - normalizedAverageSimilarity).abs();

        // Adjust based on rating and error
        // Lower ratings (indicating less satisfaction) lead to more aggressive adjustments
        double adjustmentFactor = (rating - 3.0) / 3.0; // Ranges from 0 to 1

        // Learning rate is dynamically adjusted based on error and rating
        double learningRate = baseLearningRate * adjustmentFactor * (error + 1);

        // Update coefficient
        double currentCoeff = coeffs[key] ?? 0;
        double updatedCoeff = currentCoeff * (1 + learningRate);

        updatedCoeffs[key] = updatedCoeff;
      }
      print(updatedCoeffs);
      // Optional: Update Firestore with new coefficients
      await FirebaseFirestore.instance
          .collection("coefficients")
          .doc("1")
          .update(updatedCoeffs);

      // Provide user feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted successfully')),
      );
    } catch (e) {
      print("Error submitting rating: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting rating')),
      );
    }
  }

  List<dynamic> _calculatesimilarity(
      MatchmakingProfile user1, MatchmakingProfile user2) {
    print(user1.personality);
    print("oh");
    List l1 = [
      _calculatePersonalityOverlap(user1.personality, user2.personality)
    ];
    List l2 = [ismatchyear(user1.entryNumber, user2.entryNumber)];
    List l3 = [ismatchdept(user1.entryNumber, user2.entryNumber)];
    List l4 = [ismatchpopularity(user1.popularity, user2.popularity)];
    List l5 = [ismatchhangout(user1.relationshipType, user2.relationshipType)];
    List l6 = [
      ismatchrelationship(user1.relationshipType, user2.relationshipType)
    ];
    List l7 = [_calculateInterestOverlap(user1.sports, user2.sports) * 2];
    List l8 = [_calculateInterestOverlap(user1.clubs, user2.clubs)];
    List l9 = [_calculateInterestOverlap(user1.movieGenres, user2.movieGenres)];
    List l10 = [
      _calculateInterestOverlap(user1.musicGenres, user2.musicGenres)
    ];
    print("oh yea");
    return l1 + l2 + l3 + l4 + l5 + l6 + l7 + l8 + l9 + l10;
  }

  Future<Map<String, dynamic>> avgsimilarity() async {
    print("Fetching user profile...");
    final mp1 = await FirebaseFirestore.instance
        .collection("numberofusers")
        .doc("1")
        .get();
    final mp = mp1.data();
    final n = double.parse(mp!["n"]);
    final document = await FirebaseFirestore.instance
        .collection("similarity")
        .doc("1")
        .get();
    print(document.toString());
    final basesimilarity = document.data();
    print('ofuc');
    print('yeaboi');
    basesimilarity!["n1"] = double.parse(basesimilarity["n1"]) / (n);
    basesimilarity["n2"] = double.parse(basesimilarity["n2"]) / (n);
    basesimilarity["n3"] = double.parse(basesimilarity["n3"]) / (n);
    basesimilarity["n4"] = double.parse(basesimilarity["n4"]) / (n);
    basesimilarity["n5"] = double.parse(basesimilarity["n5"]) / (n);
    basesimilarity["n6"] = double.parse(basesimilarity["n6"]) / (n);
    basesimilarity["n7"] = double.parse(basesimilarity["n7"]) / (n);
    basesimilarity["n8"] = double.parse(basesimilarity["n8"]) / (n);
    basesimilarity["n9"] = double.parse(basesimilarity["n9"]) / (n);
    basesimilarity["n10"] = double.parse(basesimilarity["n10"]) / (n);
    print("lessgoo");
    return basesimilarity;
  }
}

class MatchData {
  final String matchId;
  final String userId;
  final String name;
  final String profilePicture;
  final double matchScore;
  final String contactNumber;
  final String hostel;
  final String entryNumber;

  MatchData({
    required this.matchId,
    required this.userId,
    required this.name,
    required this.profilePicture,
    required this.matchScore,
    required this.contactNumber,
    required this.hostel,
    required this.entryNumber,
  });
}
