import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_2/main.dart';
import 'package:flutter_application_2/views/matchmaking.dart';
import 'package:flutter_application_2/views/profileview.dart';
import 'package:flutter_application_2/views/viewprofile.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:groq/groq.dart';
import 'package:url_launcher/url_launcher.dart';

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
  List<String> ratedProfiles = [];

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
        if (!myRightSwipes.contains(otherUserId)) {
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

    score +=
        n2 * (ismatchyear(currentUserProfile.entryNumber, profile.entryNumber));

    score +=
        n3 * (ismatchdept(currentUserProfile.entryNumber, profile.entryNumber));

    score += n4 *
        (ismatchpopularity(currentUserProfile.popularity, profile.popularity));

    score += n5 *
        (ismatchhangout(currentUserProfile.hangoutSpot, profile.hangoutSpot));

    score += n6 *
        ismatchrelationship(
            currentUserProfile.relationshipType, profile.relationshipType);

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

  // Helper calculations for match score
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
              Color(0xFFE3F2FD), // Soft pastel blue
              Color(0xFFF3E5F5), // Very soft lavender
              Colors.white, // Pure white
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                  ),
                )
              : _matches.isEmpty
                  ? AnimationLimiter(child: _buildEmptyState())
                  : AnimationLimiter(child: _buildMatchesList()),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: AnimationConfiguration.staggeredGrid(
        position: 0,
        duration: const Duration(milliseconds: 600),
        columnCount: 1,
        child: SlideAnimation(
          horizontalOffset: 50.0,
          child: FadeInAnimation(
            child: _buildAnimatedCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Color(0xFF6C63FF),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Nothing left to review",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurpleAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "You've reviewed all your current matches. Keep exploring!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Back to Playground",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildMatchesList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 500),
          child: SlideAnimation(
            horizontalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildMatchCard(match),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchCard(MatchData match) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Text("User not logged in");
    }
    return FutureBuilder(
      future: Future.wait([
        FirebaseFirestore.instance
            .collection('surveys')
            .doc(currentUser.uid)
            .get(),
        FirebaseFirestore.instance
            .collection('surveys')
            .doc(match.userId)
            .get(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.hasError) {
          return const Text("Error loading profile data.");
        }

        final userDoc = snapshot.data![0];
        final matchDoc = snapshot.data![1];

        final cur = MatchmakingProfile.fromFirestore(userDoc);
        final curmatch = MatchmakingProfile.fromFirestore(matchDoc);

        return _buildMatchCardContent(
            match, cur, curmatch, match.matchScore % 100);
      },
    );
  }

  Widget _buildMatchCardContent(MatchData match, MatchmakingProfile cur,
      MatchmakingProfile curmatch, double matchPercentage) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE3F2FD), // Soft pastel blue
                Color(0xFFF3E5F5), // Very soft lavender
                Color(0xFFFFFFFF), // Pure white
              ],
              stops: [0.0, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ExpansionTile(
              collapsedIconColor: const Color(0xFF6C63FF),
              iconColor: const Color(0xFF6C63FF),
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'match-${match.userId}',
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF6C63FF).withOpacity(0.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: const Color(0xFF6C63FF),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundImage: match.profilePicture.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    match.profilePicture,
                                    cacheManager:
                                        CustomProfileImageCacheManager.instance,
                                  )
                                : null,
                            child: match.profilePicture.isEmpty
                                ? const Icon(Icons.person,
                                    size: 32, color: Colors.white70)
                                : null,
                          ),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E2E2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          PurpleTextWithGroq(
                            currentUser: cur,
                            match: curmatch,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${matchPercentage.toStringAsFixed(1)}%",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(
                        color: Color(0xFFE3F2FD),
                        thickness: 1.5,
                      ),
                      const SizedBox(height: 16),

                      // Match Progress Bar (similar to achievement progress)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Match Compatibility',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            '${matchPercentage.toInt()}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder(
                        tween: Tween<double>(
                            begin: 0.0, end: matchPercentage / 100),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        builder: (context, double value, child) {
                          return Stack(
                            children: [
                              // Background track
                              Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              // Progress indicator
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Container(
                                    height: 12,
                                    width: constraints.maxWidth * value,
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurpleAccent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF5722)
                                              .withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),

                      // Rating section if needed
                      if (!ratedProfiles.contains(match.userId)) ...[
                        const SizedBox(height: 16),
                        _buildRatingSection(match),
                      ],

                      // Contact info - redesigned
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFE3F2FD), width: 1),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  const Color(0xFF6C63FF).withOpacity(0.2),
                              child: const Icon(
                                Icons.phone,
                                color: Color(0xFF6C63FF),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Phone",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  match.contactNumber,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Buttons
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _viewFullProfile(match),
                              icon: const Icon(Icons.person_outline,
                                  color: Colors.white),
                              label: const Text(
                                "View Profile",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C63FF),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _openWhatsApp(match.contactNumber),
                              icon: const Icon(Icons.chat, color: Colors.white),
                              label: const Text(
                                "WhatsApp",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to create styled cards
  Widget _buildAnimatedCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE3F2FD), // Soft pastel blue
                Color(0xFFF3E5F5), // Very soft lavender
                Color(0xFFFFFFFF), // Pure white
              ],
              stops: [0.0, 0.6, 1.0],
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
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }

  void _openWhatsApp(String phoneNumber) async {
    final Uri url = Uri.parse("https://wa.me/$phoneNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  Widget _buildRatingSection(MatchData match) {
    double _rating = 0.0; // Stores the selected rating

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE3F2FD),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_border_rounded,
                    color: Color(0xFF6C63FF),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Rate Your Experience",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _rating > 0
                    ? () async {
                        await _submitRating(match.userId, _rating, context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _rating > 0
                      ? const Color(0xFF6C63FF)
                      : Colors.grey.withOpacity(0.5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: _rating > 0 ? 4 : 0,
                ),
                child: const Text(
                  "Submit Rating",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
          builder: (context) => vProfileView(profile: fullProfile),
        ),
      );
    } catch (e) {
      print("Error fetching full profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load the full profile'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
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

class PurpleTextWithGroq extends StatefulWidget {
  final MatchmakingProfile currentUser;
  final MatchmakingProfile match;

  const PurpleTextWithGroq({
    Key? key,
    required this.currentUser,
    required this.match,
  }) : super(key: key);

  @override
  State<PurpleTextWithGroq> createState() => _PurpleTextWithGroqState();
}

class _PurpleTextWithGroqState extends State<PurpleTextWithGroq> {
  late Groq groq;
  bool _isLoading = false;
  String _displayText = "Can't decide on where do go for your next date?";

  @override
  void initState() {
    super.initState();
    groq = Groq(
      apiKey: SecretsLoader.groqApiKey,
      model: "llama3-8b-8192",
    );
  }

  Future<void> _askGroq() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Start Groq chat session
      groq.startChat();

      // Define the prompt
      final current = widget.currentUser;
      final match = widget.match;

      String prompt = '''
here is the format of what you answer should look like:
<HERE ARE THREE IDEAS:> then start a new line
<IDEA1> then start a new line
<IDEA2> then start a new line
<IDEA3>\n
Generate exactly three lines,give each line in a new line,you are not supposed to mix date ideas. on line number 'x' you should recommend exactly one object from category x,you can sugarcoat stuff,but give only and exactly 3 lines. Each fact must include one choice from each of the following categories:
Take into account each person's personality while giving ideas.
for example two people who play badminton should be recommended to play badminton
Category 1: Ground beside Mittal between 6–7 PM, Biotech lawn, Walk in campus at night  
Category 2: Ammy’s coffee in sda market (special recommendation – waffle), Café Coffee Day, Street food tour in Delhi, Have an ice cream at a place of your choice  
Category 3: Photowalk, Cycle to India Gate, Play Sports, Photo walk around campus, Make an Instagram reel of you dancing  

STRICT NOTE: DO NOT INCLUDE AN INTRODUCTORY LINE.JUST START FROM THE POINTS
Do not include any introductory or concluding lines. Just output the three facts directly, each as a single line.

Here is the profile of the user:
Name: ${current.name}  
Gender: ${current.gender}  
Hostel: ${current.hostel}  
Tagline: ${current.tagline}  
Personality: ${current.personality}  
Hobbies and Interests: ${current.clubs.join(", ")}, ${current.movieGenres.join(", ")}, ${current.musicGenres.join(", ")}, ${current.sports.join(", ")}  
Favorite Hangout Spot: ${current.hangoutSpot}  
Description: ${current.description}  

And here is the potential match:
Name: ${match.name}  
Gender: ${match.gender}  
Personality: ${match.personality}  
Hobbies and Interests: ${match.clubs.join(", ")}, ${match.movieGenres.join(", ")}, ${match.musicGenres.join(", ")}, ${match.sports.join(", ")}  
Favorite Hangout Spot: ${match.hangoutSpot}  
Description: ${match.description}

for referencez,here's what each club means:
here is what each club means:

Aeromodelling: Design,Construction,Flying of model aircraft by applying aerodynamic analysis
AXLR8R: Engineers create a superfast open-wheel formula-one style electric car within a year
PAC: Physics and Astronomy club
GROQ_API_KE: Algorithms and competitive coding club (Incredibly smart people here)
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
"eDc": entrepreneurship club,
"Music Club": Musics club,
"FACC":Painting,designing stuff and designing fashion(creative people here),
"Envogue": Fashion club,
"Enactus":NGO social service etc. club,
"Debsoc":Debate society,
"Lit club":Literary club (discuss books,word games),
"QC": Quizzing club,
"Design club":Do pretty stuff like UI/UX design,photo editing,graphics, VFX ,
"Dance club":they dance
"Drama club":Drama club,
"Spic Macay":Classical dance,

''';
      print(prompt);
      // Send the message and wait for response
      GroqResponse response = await groq.sendMessage(prompt);

      // Extract response content
      String groqResponse = response.choices.first.message.content;
      print(groqResponse);
      // Update UI
      setState(() {
        _isLoading = false;
        _showBeautifulPopup(context, groqResponse);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showBeautifulPopup(BuildContext context, String responseText) {
    // Parse the response text into bullet points (assuming it has line breaks or can be split)
    List<String> bulletPointse = responseText
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .take(4)
        .toList();
    List<String> bulletPoints = [];
    bulletPoints.add(bulletPointse[1].substring(8));
    bulletPoints.add(bulletPointse[2].substring(8));
    bulletPoints.add(bulletPointse[3].substring(8));
    if (bulletPoints.isEmpty) {
      bulletPoints = ['No matching information available.'];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  "A hand picked date idea",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                SizedBox(height: 20),
                // Nature bullet point
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.nature,
                        color: Colors.deepPurple.shade300,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bulletPoints.length > 0
                            ? bulletPoints[0]
                            : "Nature lover",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Food bullet point
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.deepPurple.shade300,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bulletPoints.length > 1
                            ? bulletPoints[1]
                            : "Food enthusiast",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Fun bullet point
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.celebration,
                        color: Colors.deepPurple.shade300,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bulletPoints.length > 2
                            ? bulletPoints[2]
                            : "Fun seeker",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade400,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "Close",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _askGroq,
      child: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.deepPurple.shade400),
              ),
            )
          : Text(
              _displayText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.deepPurple.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }
}
