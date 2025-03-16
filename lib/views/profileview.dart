import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/views/matchmaking.dart';

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
  bool _isEditingHangout = false;
  bool _isEditingClubs = false;
  bool _isEditingMovieGenres = false;
  bool _isEditingMusicGenres = false;
  bool _isEditingSports = false;

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
    _selectedClubs = List<String>.from(widget.profile.clubs);
    _selectedMovieGenres = List<String>.from(widget.profile.movieGenres);
    _selectedMusicGenres = List<String>.from(widget.profile.musicGenres);
    _selectedHangoutSpot = widget.profile.hangoutSpot;
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

  Future<String> _generateProfileDescription(
      String name,
      String gender,
      List<String> clubs,
      List<String> sports,
      List<String> movieGenres,
      List<String> musicGenres,
      String hangoutSpot,
      String relationshipType) async {
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
    return await getLLMReply(promptu);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 46, 49, 73),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                setState(() => _isEditingHangout = !_isEditingHangout);
              },
              onSelectionChanged: (newSelection) => setState(() {
                _selectedHangoutSpot = newSelection;
              }),
            ),
            _buildMultiSelectField(
                "Clubs", _isEditingClubs, _allClubs, _selectedClubs, () {
              if (_isEditingClubs) {
                _saveProfile('clubs', _selectedClubs);
              }
              setState(() => _isEditingClubs = !_isEditingClubs);
            }),
            _buildMultiSelectField("Movie Genres", _isEditingMovieGenres,
                _allMovieGenres, _selectedMovieGenres, () {
              if (_isEditingMovieGenres) {
                _saveProfile('movie_genres', _selectedMovieGenres);
              }
              setState(() => _isEditingMovieGenres = !_isEditingMovieGenres);
            }),
            _buildMultiSelectField("Music Genres", _isEditingMusicGenres,
                _allMusicGenres, _selectedMusicGenres, () {
              if (_isEditingMusicGenres) {
                _saveProfile('music_genres', _selectedMusicGenres);
              }
              setState(() => _isEditingMusicGenres = !_isEditingMusicGenres);
            }),
            _buildMultiSelectField(
                "Sports", _isEditingSports, _allSports, _selectedSports, () {
              if (_isEditingSports) {
                _saveProfile('sports', _selectedSports);
              }
              setState(() => _isEditingSports = !_isEditingSports);
            }),
            const SizedBox(height: 20),

            // Logout Button
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text("Logout"),
              ),
            ),
          ],
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
                  color: Colors.blue),
              onPressed: onEdit,
            ),
          ],
        ),
        isEditing
            ? Wrap(
                spacing: 8.0,
                children: options
                    .map((option) => FilterChip(
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
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white)),
            Spacer(),
            IconButton(
              icon: Icon(isEditing ? Icons.check : Icons.edit,
                  color: Colors.blue),
              onPressed: onEdit,
            ),
          ],
        ),
        isEditing
            ? DropdownButtonFormField<String>(
                value: selectedValue,
                decoration: InputDecoration(border: OutlineInputBorder()),
                items: options.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    onSelectionChanged(newValue);
                  }
                },
              )
            : Text(selectedValue,
                style: TextStyle(fontSize: 16, color: Colors.white)),
        SizedBox(height: 16),
      ],
    );
  }
}
