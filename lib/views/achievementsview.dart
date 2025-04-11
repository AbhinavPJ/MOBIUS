import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/views/matchmaking.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// Achievement model class
class Achievement1 {
  final String name;
  final String description;
  final int currentProgress;
  final int totalRequired;
  final int benchmark1;
  final int benchmark2;
  final int benchmark3;
  final IconData icon; // Added icon for visual enhancement

  Achievement1({
    required this.name,
    required this.description,
    required this.currentProgress,
    required this.totalRequired,
    required this.benchmark1,
    required this.benchmark2,
    required this.benchmark3,
    this.icon = Icons.emoji_events, // Default icon
  });

  bool get isComplete => currentProgress >= totalRequired;
}

class AchievementsView extends StatefulWidget {
  final MatchmakingProfile profile;

  const AchievementsView({Key? key, required this.profile}) : super(key: key);

  @override
  _AchievementsViewState createState() => _AchievementsViewState();
}

class _AchievementsViewState extends State<AchievementsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Achievement1>> _fetchAchievements() async {
    print(widget.profile.heleftwiped!);
    int numberofleftswipes = widget.profile.heleftwiped?.length ?? 0;
    DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
        .collection('surveys')
        .doc(widget.profile.userId)
        .get();

    MatchmakingProfile currentUserProfile =
        MatchmakingProfile.fromFirestore(currentUserDoc);

    List<String> myRightSwipes = currentUserProfile.rightswipedby ?? [];

    QuerySnapshot potentialMatches = await FirebaseFirestore.instance
        .collection('surveys')
        .where('rightswipedby', arrayContains: widget.profile.userId)
        .get();
    bool flag = false;
    List<String> loadedMatches = [];
    for (var doc in potentialMatches.docs) {
      String otherUserId = doc.id;
      if (otherUserId != widget.profile.userId &&
          myRightSwipes.contains(otherUserId)) {
        loadedMatches.add(otherUserId);
      }
    }
    if (widget.profile.hasUpdated == null) {
      flag = false;
    } else {
      flag = true;
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
        icon: Icons.task_alt,
      ),
      Achievement1(
        name: "Sigma",
        description: "Pass on profiles",
        currentProgress: numberofleftswipes,
        totalRequired: 15,
        benchmark1: 5,
        benchmark2: 10,
        benchmark3: 15,
        icon: Icons.thumb_down,
      ),
      Achievement1(
        name: "Catfish Radar",
        description: "Heroes don't always swipe. Sometimes, they report",
        currentProgress: (widget.profile.catfishradar == null) ? 0 : 1,
        benchmark1: 1,
        benchmark2: 5,
        benchmark3: 10,
        totalRequired: 10,
        icon: Icons.report_problem,
      ),
      Achievement1(
        name: "Play Boy",
        description: "Get many matches",
        currentProgress: loadedMatches.length,
        totalRequired: 15,
        benchmark1: 5,
        benchmark2: 10,
        benchmark3: 15,
        icon: Icons.favorite,
      ),
      Achievement1(
        currentProgress: flag ? 1 : 0,
        benchmark1: 1,
        benchmark2: 1,
        benchmark3: 1,
        name: "Glow Up",
        totalRequired: 1,
        description:
            "New photo, new vibe. The algorithm notices—and so will they.",
        icon: Icons.face_retouching_natural,
      ),
      Achievement1(
        name: "Seasoned Swiper",
        currentProgress: currentUserProfile.swipeTimestamps == null
            ? 0
            : ((currentUserProfile.swipeTimestamps!).length),
        description:
            "Left, right, left again. You're not choosing—they're choosing you.",
        benchmark1: 10,
        benchmark2: 25,
        benchmark3: 50,
        totalRequired: 50,
        icon: Icons.swipe,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Achievements',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        leading: Hero(
          tag: 'back_button',
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
              onPressed: () {
                // Animate out before popping
                _animationController.reverse().then((_) {
                  Navigator.pop(context);
                });
              },
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
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
          child: FutureBuilder<List<Achievement1>>(
            future: _fetchAchievements(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF6C63FF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Loading achievements...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No achievements found.',
                    style: TextStyle(color: Colors.black54, fontSize: 18),
                  ),
                );
              }

              final achievements = snapshot.data!;
              return AnimationLimiter(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        horizontalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildAchievementCard(achievements[index]),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement1 achievement) {
    int starsEarned = 0;
    if (achievement.currentProgress >= achievement.benchmark1) starsEarned += 1;
    if (achievement.currentProgress >= achievement.benchmark2) starsEarned += 1;
    if (achievement.currentProgress >= achievement.benchmark3) starsEarned += 1;

    // Animation for progress
    double progressValue =
        achievement.currentProgress / achievement.totalRequired;
    if (progressValue > 1.0) progressValue = 1.0;

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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFE3F2FD), // Soft pastel blue
                const Color(0xFFF3E5F5), // Very soft lavender
                const Color(0xFFFFFFFF), // Pure white
              ],
              stops: const [0.0, 0.6, 1.0],
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: achievement.isComplete
                            ? const Color(0xFF6C63FF).withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        achievement.icon,
                        size: 28,
                        color: achievement.isComplete
                            ? const Color(0xFF6C63FF)
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E2E2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            achievement.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(3, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(
                          begin: 0.0,
                          end: index < starsEarned ? 1.0 : 0.0,
                        ),
                        duration: Duration(milliseconds: 400 + (index * 200)),
                        builder: (context, double value, child) {
                          return Icon(
                            Icons.star,
                            size: 28,
                            color: index < starsEarned
                                ? Color.lerp(
                                    Colors.grey[400],
                                    Colors.amber,
                                    value,
                                  )
                                : Colors.grey[400],
                          );
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                if (!achievement.isComplete) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${achievement.currentProgress}/${achievement.totalRequired}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '${(progressValue * 100).toInt()}%',
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
                    tween: Tween<double>(begin: 0.0, end: progressValue),
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
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF6C63FF),
                                      const Color(0xFF8F87FF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6C63FF)
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
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF6C63FF),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Achievement Complete!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
