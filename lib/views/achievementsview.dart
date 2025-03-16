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

// Function to create a new achievement
Achievement1 makeAchievement1({
  required String name,
  required String description,
  required int currentProgress,
  required int totalRequired,
  required int benchmark1,
  required int benchmark2,
  required int benchmark3,
}) {
  return Achievement1(
    name: name,
    description: description,
    currentProgress: currentProgress,
    totalRequired: totalRequired,
    benchmark1: benchmark1,
    benchmark2: benchmark2,
    benchmark3: benchmark3,
  );
}

class AchievementsView extends StatelessWidget {
  final MatchmakingProfile profile;
  const AchievementsView({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final achievements = [
      makeAchievement1(
        name: "The First Order of Business",
        description:
            "Complete the survey and prove your mastery over forms, checkboxes, and mildly invasive questions!",
        currentProgress: 1,
        totalRequired: 1,
        benchmark1: 1,
        benchmark2: 1,
        benchmark3: 1,
      ),
      makeAchievement1(
        name: "Sigma Male",
        description: "Pass on profiles",
        currentProgress: 7,
        totalRequired: 15,
        benchmark1: 5,
        benchmark2: 10,
        benchmark3: 15,
      ),
      makeAchievement1(
        name: "Play Boy",
        description: "Get many matches",
        currentProgress: 7,
        totalRequired: 15,
        benchmark1: 5,
        benchmark2: 10,
        benchmark3: 15,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: Container(
        color: Colors.grey[200],
        child: ListView.builder(
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return _buildAchievementCard(achievement);
          },
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement1 achievement) {
    var starsEarned = 0;
    if (achievement.currentProgress >= achievement.benchmark1) {
      starsEarned += 1;
    }
    if (achievement.currentProgress >= achievement.benchmark2) {
      starsEarned += 1;
    }
    if (achievement.currentProgress >= achievement.benchmark2) {
      starsEarned += 1;
    }
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stars row
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

            // Title and description
            Text(
              achievement.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              achievement.description,
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 12),

            // Progress section
            if (!achievement.isComplete) ...[
              // Progress text
              Text(
                '${achievement.currentProgress}/${achievement.totalRequired}',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.right,
              ),

              // Progress bar
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
