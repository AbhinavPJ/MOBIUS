import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_2/views/matchmaking.dart';
import 'package:flutter_application_2/views/viewprofile.dart';

class MyMatchesView extends StatefulWidget {
  final n1, n2, n3, n4, n5, n6, n7, n8, n9, n10;
  const MyMatchesView({
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
  _MyMatchesViewState createState() => _MyMatchesViewState();
}

class _MyMatchesViewState extends State<MyMatchesView> {
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
      // First, get the current user's profile to access their rightswipedby list
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

      QuerySnapshot potentialMatches = await FirebaseFirestore.instance
          .collection('surveys')
          .where('rightswipedby', arrayContains: _currentUserId)
          .get();

      List<MatchData> loadedMatches = [];

      for (var doc in potentialMatches.docs) {
        String otherUserId = doc.id;

        if (otherUserId == _currentUserId) continue;

        if (myRightSwipes.contains(otherUserId)) {
          MatchmakingProfile otherUserProfile =
              MatchmakingProfile.fromFirestore(doc);
          double matchScore =
              _calculateMatchScore(currentUserProfile, otherUserProfile);
          loadedMatches.add(
            MatchData(
              matchId:
                  '${_currentUserId}_$otherUserId', // Create a unique match ID
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
    score += widget.n1 *
        (_calculatePersonalityOverlap(
            currentUserProfile.personality, profile.personality));

    //print("hereiii");
    //print(currentUserProfile?.gender);

    //print(currentUserProfile?.entryNumber);
    score += widget.n2 *
        (ismatchyear(currentUserProfile.entryNumber, profile.entryNumber));
    // Compare interests
    //print(profile.entryNumber);
    //print("ohh fuck");
    //print(currentUserProfile!.entryNumber);

    score += widget.n3 *
        (ismatchdept(currentUserProfile.entryNumber, profile.entryNumber));

    //print("oh bsdk");
    score += widget.n4 *
        (ismatchpopularity(currentUserProfile.popularity, profile.popularity));

    score += widget.n5 *
        (ismatchhangout(currentUserProfile.hangoutSpot, profile.hangoutSpot));

    //print('hereeeeiiiii');
    score += widget.n6 *
        ismatchrelationship(
            currentUserProfile.relationshipType, profile.relationshipType);

    //print("mcccc");
    score += widget.n7 *
        _calculateInterestOverlap(currentUserProfile.sports, profile.sports) *
        2;

    score += widget.n8 *
        _calculateInterestOverlap(currentUserProfile.clubs, profile.clubs);

    score += widget.n9 *
        _calculateInterestOverlap(
            currentUserProfile.movieGenres, profile.movieGenres);

    score += widget.n10 *
        _calculateInterestOverlap(
            currentUserProfile.musicGenres, profile.musicGenres);
    //print("hereiiiiiiiiiiiii");
    if (currentUserProfile.rightswipedby != null &&
        currentUserProfile.rightswipedby!.contains(profile.userId)) {
      return 200.0 +
          100.0 *
              score /
              (2000.0 * widget.n1 +
                  widget.n2 +
                  widget.n3 +
                  2 * widget.n4 +
                  widget.n5 +
                  3 * widget.n6 +
                  widget.n7 +
                  widget.n8 +
                  widget.n9 +
                  widget.n10);
    }
    return 100.0 *
        score /
        (2000.0 * widget.n1 +
            widget.n2 +
            widget.n3 +
            2 * widget.n4 +
            widget.n5 +
            3 * widget.n6 +
            widget.n7 +
            widget.n8 +
            widget.n9 +
            widget.n10);
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
      backgroundColor: Color.fromRGBO(229, 229, 229, 1),
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
              Icons.favorite_border_outlined,
              size: 80,
              color: Colors.purple.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              "No Matches Yet",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Keep swiping to find your perfect match! Your connection is just a swipe away.",
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
            color: const Color.fromARGB(255, 120, 186, 216), width: 2),
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
          iconColor: Colors.green,
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
                            fontSize: 14,
                            color: Colors.black,
                          ),
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
              decoration: BoxDecoration(
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
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 8),
                  _buildContactInfoRow(
                      Icons.phone, "Phone", match.contactNumber),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B61FF), Color(0xFFFF477E)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ElevatedButton(
                        onPressed: () => _viewFullProfile(match),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "View Description",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

  Widget _buildContactInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _viewFullProfile(MatchData match) async {
    try {
      DocumentSnapshot profileDoc = await FirebaseFirestore.instance
          .collection('surveys')
          .doc(match.userId)
          .get();

      if (!profileDoc.exists || !mounted) return;

      MatchmakingProfile fullProfile =
          MatchmakingProfile.fromFirestore(profileDoc);

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => vProfileView(profile: fullProfile)),
      );
    } catch (e) {
      print("Error fetching full profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load the full profile')),
        );
      }
    }
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
