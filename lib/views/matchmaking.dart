import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:groq/groq.dart';

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
  });

  factory MatchmakingProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    print("this one");
    print(data['name']);
    print(data['userId']);
    print(data['clubs']);
    print(data['entry_number']);
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
        hostel: data['hostel'] ?? '');
  }
}

class MatchmakingScreen extends StatefulWidget {
  @override
  _MatchmakingScreenState createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  void _handleRightSwipe(MatchmakingProfile profile) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Liked ${profile.name}'),
        backgroundColor: Colors.green.shade700,
      ),
    );
    _moveToNextMatch();
  }

  void _handleLeftSwipe(MatchmakingProfile profile) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Passed on ${profile.name}'),
        backgroundColor: Colors.red.shade700,
      ),
    );
    _moveToNextMatch();
  }

  MatchmakingProfile? currentUserProfile;
  List<MatchmakingProfile> potentialMatches = [];
  List<MapEntry<MatchmakingProfile, double>> rankedMatches = [];
  int currentMatchIndex = 0;

  @override
  void initState() {
    print("hereeeee");
    super.initState();
    _fetchUserProfiles();
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
      setState(() {
        currentUserProfile = tempProfile;
      });

      print("Fetched currentUserProfile: ${currentUserProfile?.name}");

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

      print("Fetched ${fetchedProfiles.length} profiles.");

      // Rank matches only if profile is completely loaded
      if (currentUserProfile != null) {
        rankedMatches = _rankMatches(fetchedProfiles);
        print("Ranked matches: ${rankedMatches.length}");

        setState(() {
          potentialMatches = rankedMatches.map((entry) => entry.key).toList();
        });
      }
    } catch (e) {
      print("Error fetching user profiles: $e");
    }
  }

  // TODO: Implement your matchmaking algorithm here
  List<MapEntry<MatchmakingProfile, double>> _rankMatches(
      List<MatchmakingProfile> profiles) {
    // This is where you'll implement your custom matchmaking scoring algorithm
    // Each profile should be paired with a match score
    // Example placeholder implementation:
    print("here");
    return profiles
        .map((profile) => MapEntry(profile, _calculateMatchScore(profile)))
        .toList()
      ..sort((a, b) => b.value
          .compareTo(a.value)); // Sort in descending order of match score
  }

  // Placeholder match score calculation
  double _calculateMatchScore(MatchmakingProfile profile) {
    if (currentUserProfile == null) {
      print("Error: currentUserProfile is null when calculating match score!");
      return 0.0;
    }

    print(currentUserProfile?.personality);
    print("hereeeoii");
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
    print(score);
    score += n1 *
        (_calculatePersonalityOverlap(
            currentUserProfile!.personality, profile.personality));

    //print("hereiii");
    //print(currentUserProfile?.gender);
    print(100.0 *
        score /
        (2000.0 * n1 + n2 + n3 + 2 * n4 + n5 + 3 * n6 + n7 + n8 + n9 + n10));
    //print(currentUserProfile?.entryNumber);
    score += n2 *
        (ismatchyear(currentUserProfile!.entryNumber, profile.entryNumber));
    // Compare interests
    //print(profile.entryNumber);
    //print("ohh fuck");
    //print(currentUserProfile!.entryNumber);
    print(100.0 *
        score /
        (2000.0 * n1 + n2 + n3 + 2 * n4 + n5 + 3 * n6 + n7 + n8 + n9 + n10));
    score += n3 *
        (ismatchdept(currentUserProfile!.entryNumber, profile.entryNumber));
    print(100.0 *
        score /
        (2000.0 * n1 + n2 + n3 + 2 * n4 + n5 + 3 * n6 + n7 + n8 + n9 + n10));
    //print("oh bsdk");
    score += n4 *
        (ismatchpopularity(currentUserProfile!.popularity, profile.popularity));
    print(100.0 *
        score /
        (2000.0 * n1 + n2 + n3 + 2 * n4 + n5 + 3 * n6 + n7 + n8 + n9 + n10));
    score += n5 *
        (ismatchhangout(currentUserProfile!.hangoutSpot, profile.hangoutSpot));
    print(100.0 *
        score /
        (2000.0 * n1 + n2 + n3 + 2 * n4 + n5 + 3 * n6 + n7 + n8 + n9 + n10));
    //print('hereeeeiiiii');
    score += n6 *
        ismatchrelationship(
            currentUserProfile!.relationshipType, profile.relationshipType);
    print(100.0 *
        score /
        (2000.0 * n1 + n2 + n3 + 2 * n4 + n5 + 3 * n6 + n7 + n8 + n9 + n10));
    //print("mcccc");
    score += n7 *
        _calculateInterestOverlap(currentUserProfile!.sports, profile.sports) *
        2;
    print(100.0 *
        score /
        (2000.0 * n1 + n2 + n3 + 2 * n4 + n5 + 3 * n6 + n7 + n8 + n9 + n10));
    score += n8 *
        _calculateInterestOverlap(currentUserProfile!.clubs, profile.clubs);

    print(100.0 *
        score /
        (2000.0 * n1 + n2 + n3 + 2 * n4 + n5 + 3 * n6 + n7 + n8 + n9 + n10));
    score += n9 *
        _calculateInterestOverlap(
            currentUserProfile!.movieGenres, profile.movieGenres);

    print(100.0 *
        score /
        (2000.0 * n1 + n2 + n3 + 2 * n4 + n5 + 3 * n6 + n7 + n8 + n9 + n10));
    score += n10 *
        _calculateInterestOverlap(
            currentUserProfile!.musicGenres, profile.musicGenres);
    //print("hereiiiiiiiiiiiii");

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

  void _moveToNextMatch() {
    setState(() {
      currentMatchIndex = (currentMatchIndex + 1) % potentialMatches.length;
    });
  }

  void _moveToPreviousMatch() {
    setState(() {
      currentMatchIndex = (currentMatchIndex - 1 + potentialMatches.length) %
          potentialMatches.length;
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

  Widget _formatProfileDescription(String description) {
    // Trim and split the description into paragraphs
    List<String> paragraphs = description.trim().split('\n\n');

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Insights',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
              decoration: TextDecoration.underline,
            ),
          ),
          SizedBox(height: 8),
          ...paragraphs
              .map((paragraph) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      paragraph,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (potentialMatches.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.brown[50],
        appBar: AppBar(
          title: Text('Matchmaking'),
          backgroundColor: Colors.red[700],
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
    String s = currentMatch.tagline;
    String house = currentMatch.hostel;

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: Text('Potential Matches'),
        centerTitle: true,
        backgroundColor: Colors.red[700],
      ),
      body: FutureBuilder<String>(
        future: _generateProfileDescription(currentMatch),
        builder: (context, snapshot) {
          return GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy > 0) {
                _moveToPreviousMatch();
              } else if (details.velocity.pixelsPerSecond.dy < 0) {
                _moveToNextMatch();
              }
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: 390,
                  height: 860,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFFFFD700), width: 10),
                    image: DecorationImage(
                      image: AssetImage('assets/images/poke.png'),
                      fit: BoxFit.cover,
                    ),
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
                      // Stage and HP
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$house hostel',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          currentMatch.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Profile Image
                      SizedBox(height: 8),
                      Container(
                        width: 340,
                        height: 270,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(currentMatch.profilePicture),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      // Name and Details

                      // Pokemon Power / Special Ability
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            s,
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Times',
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      // Attack
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_fire_department,
                                color: Colors.red),
                            Text(
                              'Match Score: ${matchScore.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Description section
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: snapshot.connectionState ==
                                  ConnectionState.waiting
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.deepOrange,
                                  ),
                                )
                              : snapshot.hasError
                                  ? Center(
                                      child: Text(
                                        snapshot.error.toString(),
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      child: Container(
                                        padding: EdgeInsets.all(
                                            15), // Increased padding
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade400,
                                          borderRadius: BorderRadius.circular(
                                              15), // Slightly larger border radius
                                          border: Border.all(
                                              color: Colors.orange.shade200,
                                              width: 1.5),
                                        ),
                                        constraints: BoxConstraints(
                                            minHeight:
                                                180), // Increased minimum height
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Description:',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              snapshot.data ?? '',
                                              style: TextStyle(
                                                fontSize:
                                                    14, // Slightly larger font size
                                                color: Colors.black87,
                                                height:
                                                    1.6, // Increased line height for better readability
                                              ),
                                              textAlign: TextAlign.justify,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
