import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/views/matchmaking.dart';

// Achievement model class
class Achievement1 {
  final String name;
  final String description;
  final int currentProgress;
  final int totalRequired;
  final int benchmark1;
  final int benchmark2;
  final int benchmark3;

  Achievement1({
    required this.name,
    required this.description,
    required this.currentProgress,
    required this.totalRequired,
    required this.benchmark1,
    required this.benchmark2,
    required this.benchmark3,
  });

  bool get isComplete => currentProgress >= totalRequired;
}

class AchievementsView extends StatelessWidget {
  final MatchmakingProfile profile;

  const AchievementsView({Key? key, required this.profile}) : super(key: key);

  Future<List<Achievement1>> _fetchAchievements() async {
    int numberofleftswipes = profile.Heleftwiped?.length ?? 0;

    DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
        .collection('surveys')
        .doc(profile.userId)
        .get();

    MatchmakingProfile currentUserProfile =
        MatchmakingProfile.fromFirestore(currentUserDoc);

    List<String> myRightSwipes = currentUserProfile.rightswipedby ?? [];

    QuerySnapshot potentialMatches = await FirebaseFirestore.instance
        .collection('surveys')
        .where('rightswipedby', arrayContains: profile.userId)
        .get();

    List<String> loadedMatches = [];

    for (var doc in potentialMatches.docs) {
      String otherUserId = doc.id;
      if (otherUserId != profile.userId &&
          myRightSwipes.contains(otherUserId)) {
        loadedMatches.add(otherUserId);
      }
    }

    return [
      Achievement1(
        name: "The First Order of Business",
        description:
            "Complete the survey and prove your mastery over forms, checkboxes, and mildly invasive questions!",
        currentProgress: 1,
        totalRequired: 1,
        benchmark1: 1,
        benchmark2: 1,
        benchmark3: 1,
      ),
      Achievement1(
        name: "Sigma Male",
        description: "Pass on profiles",
        currentProgress: numberofleftswipes,
        totalRequired: 15,
        benchmark1: 5,
        benchmark2: 10,
        benchmark3: 15,
      ),
      Achievement1(
        name: "Play Boy",
        description: "Get many matches",
        currentProgress: loadedMatches.length,
        totalRequired: 15,
        benchmark1: 5,
        benchmark2: 10,
        benchmark3: 15,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: FutureBuilder<List<Achievement1>>(
        future: _fetchAchievements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No achievements found.'));
          }

          final achievements = snapshot.data!;
          return Container(
            color: Colors.grey[200],
            child: ListView.builder(
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return _buildAchievementCard(achievement);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementCard(Achievement1 achievement) {
    int starsEarned = 0;
    if (achievement.currentProgress >= achievement.benchmark1) starsEarned += 1;
    if (achievement.currentProgress >= achievement.benchmark2) starsEarned += 1;
    if (achievement.currentProgress >= achievement.benchmark3) starsEarned += 1;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(3, (index) {
                return Icon(
                  Icons.star,
                  size: 24,
                  color: index < starsEarned ? Colors.amber : Colors.grey,
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(achievement.description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            if (!achievement.isComplete) ...[
              Text(
                '${achievement.currentProgress}/${achievement.totalRequired}',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.right,
              ),
              LinearProgressIndicator(
                value: achievement.currentProgress / achievement.totalRequired,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ] else ...[
              const Text(
                'Achievement Complete!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
