import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/auth/keys.dart';
import 'package:flutter_application_2/views/matchmaking.dart';
import 'package:groq/groq.dart';

class ProfileView extends StatefulWidget {
  final MatchmakingProfile profile;
  final VoidCallback onProfileUpdated;

  const ProfileView({
    Key? key,
    required this.profile,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late Groq groq;
  bool isApiReady = false;
  bool _isEditingHangout = false;
  bool _isEditingClubs = false;
  bool _isEditingMovieGenres = false;
  bool _isEditingMusicGenres = false;
  bool _isEditingSports = false;
  String profilepictureurl = "";
  List<String> _selectedClubs = [];
  List<String> _selectedMovieGenres = [];
  List<String> _selectedMusicGenres = [];
  List<String> _selectedSports = [];
  late String _selectedHangoutSpot;

  final List<String> _hangoutSpots = [
    "CCD",
    "Nescafe",
    "Amul",
    "Night mess",
    "Hostel VR/CR"
  ];
  final List<String> _allSports = [
    "Badminton",
    "Squash",
    "Tennis",
    "Table tennis",
    "Athletics",
    "Volleyball",
    "Basketball",
    "Chess",
    "Weightlifting",
    "Competitive programming",
    "Aquatics",
  ];
  final List<String> _allClubs = [
    "Aeromodelling",
    "AXLR8R",
    "PAC",
    "ANCC",
    "DevClub",
    "Economics club",
    "Infinity Hyperloop",
    "Business and Consulting club",
    "Robotics",
    "ARIES",
    "IGTS",
    "iGEM",
    "BlocSoc",
    "PFC",
    "Music Club",
    "FACC",
    "Debsoc",
    "Lit club",
    "QC",
    "Design club",
    "Dance club",
    "Drama club",
    "Spic Macay"
  ];
  final List<String> _allMovieGenres = [
    "Action",
    "Comedy",
    "Drama",
    "Horror",
    "Sci-Fi",
    "Romance",
    "Thriller",
    "Fantasy",
    "Documentary",
    "Mystery",
    "Musical",
    "Adventure"
  ];
  final List<String> _allMusicGenres = [
    "Pop",
    "K-Pop",
    "Hip-hop",
    "Rap",
    "Metal",
    "Indie Pop",
    "Bollywood",
    "Punjabi",
    "Classical",
    "Southern cinema music",
    "Rock",
  ];

  @override
  void initState() {
    super.initState();
    initializeGroq();
    _selectedClubs = List<String>.from(widget.profile.clubs);
    _selectedMovieGenres = List<String>.from(widget.profile.movieGenres);
    _selectedMusicGenres = List<String>.from(widget.profile.musicGenres);
    _selectedHangoutSpot = widget.profile.hangoutSpot;
    profilepictureurl = widget.profile.profilePicture;
    _selectedSports = List<String>.from(widget.profile.sports);
  }

  Future<void> _saveProfile(String field, dynamic value) async {
    try {
      await FirebaseFirestore.instance
          .collection('surveys')
          .doc(widget.profile.userId)
          .update({field: value});
      String new_description = await _generateProfileDescription(
          widget.profile.name,
          widget.profile.gender,
          _selectedClubs,
          _selectedSports,
          _selectedMovieGenres,
          _selectedMusicGenres,
          _selectedHangoutSpot,
          widget.profile.relationshipType);
      await FirebaseFirestore.instance
          .collection('surveys')
          .doc(widget.profile.userId)
          .update({"description": new_description});

      widget.onProfileUpdated();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    }
  }

  Future<void> initializeGroq() async {
    await Secrets.loadSecrets();
    setState(() {
      groq = Groq(
        apiKey: Secrets.groqApiKey, // Load API key securely
        model: "llama-3.3-70b-versatile",
      );
      isApiReady = true;
    });
  }

  Future<String> _generateProfileDescription(
      String name,
      String gender,
      List<String> clubs,
      List<String> sports,
      List<String> movieGenres,
      List<String> musicGenres,
      String hangoutSpot,
      String relationshipType) async {
    if (!isApiReady) {
      return "LLM is not ready yet.";
    }

    String promptu = """
Generate a short,sweet,insightful,fun,quirky,positive description of a person based on the following characteristics.The goal is to create a relationship
 between the person described and the person reading this.
 Try to infer from the fields below what a person might actually be like in person:

Name: ${name}
Gender: ${gender}

Interests:
- Clubs: ${clubs.join(', ')}
- Sports: ${sports.join(', ')}
- Movie Genres: ${movieGenres.join(', ')}
- Music Genres: ${musicGenres.join(', ')}
- Hangout Spot: ${hangoutSpot}
- Relationship Type: ${relationshipType}

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
    groq.startChat();
    GroqResponse response = await groq.sendMessage(promptu);
    return response.choices.first.message.content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(165, 18, 178, 0.604),
              Color.fromRGBO(189, 148, 215, 1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Edit Profile",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Centered profile image with loading indicator
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: ClipOval(
                    child: profilepictureurl.isNotEmpty
                        ? Image.network(
                            profilepictureurl,
                            width: 180,
                            height: 180,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Profile Edit Sections
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      _buildSingleSelectField(
                        label: "Hangout Spot",
                        isEditing: _isEditingHangout,
                        options: _hangoutSpots,
                        selectedValue: _selectedHangoutSpot,
                        onEdit: () {
                          if (_isEditingHangout) {
                            _saveProfile('hangout_spot', _selectedHangoutSpot);
                          }
                          setState(
                              () => _isEditingHangout = !_isEditingHangout);
                        },
                        onSelectionChanged: (newSelection) => setState(() {
                          _selectedHangoutSpot = newSelection;
                        }),
                      ),
                      _buildMultiSelectField(
                          "Clubs", _isEditingClubs, _allClubs, _selectedClubs,
                          () {
                        if (_isEditingClubs) {
                          _saveProfile('clubs', _selectedClubs);
                        }
                        setState(() => _isEditingClubs = !_isEditingClubs);
                      }),
                      _buildMultiSelectField(
                          "Movie Genres",
                          _isEditingMovieGenres,
                          _allMovieGenres,
                          _selectedMovieGenres, () {
                        if (_isEditingMovieGenres) {
                          _saveProfile('movie_genres', _selectedMovieGenres);
                        }
                        setState(() =>
                            _isEditingMovieGenres = !_isEditingMovieGenres);
                      }),
                      _buildMultiSelectField(
                          "Music Genres",
                          _isEditingMusicGenres,
                          _allMusicGenres,
                          _selectedMusicGenres, () {
                        if (_isEditingMusicGenres) {
                          _saveProfile('music_genres', _selectedMusicGenres);
                        }
                        setState(() =>
                            _isEditingMusicGenres = !_isEditingMusicGenres);
                      }),
                      _buildMultiSelectField("Sports", _isEditingSports,
                          _allSports, _selectedSports, () {
                        if (_isEditingSports) {
                          _saveProfile('sports', _selectedSports);
                        }
                        setState(() => _isEditingSports = !_isEditingSports);
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Logout Button
                _buildButton("Logout", Colors.white, Colors.black, () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectField(String label, bool isEditing,
      List<String> options, List<String> selectedValues, VoidCallback onEdit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white)),
            const Spacer(),
            IconButton(
              icon: Icon(isEditing ? Icons.check : Icons.edit,
                  color: Colors.white),
              onPressed: onEdit,
            ),
          ],
        ),
        isEditing
            ? Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: options
                    .map((option) => FilterChip(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          selectedColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selectedValues.contains(option)
                                ? Colors.black
                                : Colors.black,
                          ),
                          label: Text(option),
                          selected: selectedValues.contains(option),
                          onSelected: (selected) {
                            setState(() {
                              selected
                                  ? selectedValues.add(option)
                                  : selectedValues.remove(option);
                            });
                          },
                        ))
                    .toList(),
              )
            : Text(selectedValues.join(', '),
                style: const TextStyle(fontSize: 16, color: Colors.white)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildButton(
      String text, Color bgColor, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: 200,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSingleSelectField({
    required String label,
    required bool isEditing,
    required List<String> options,
    required String selectedValue,
    required VoidCallback onEdit,
    required Function(String) onSelectionChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white)),
            const Spacer(),
            IconButton(
              icon: Icon(isEditing ? Icons.check : Icons.edit,
                  color: Colors.white),
              onPressed: onEdit,
            ),
          ],
        ),
        isEditing
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: DropdownButtonFormField<String>(
                  dropdownColor: const Color.fromRGBO(165, 18, 178, 0.604),
                  value: selectedValue,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: options.map((option) {
                    return DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          style: const TextStyle(color: Colors.white),
                        ));
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      onSelectionChanged(newValue);
                    }
                  },
                ),
              )
            : Text(selectedValue,
                style: const TextStyle(fontSize: 16, color: Colors.white)),
        const SizedBox(height: 16),
      ],
    );
  }
}
