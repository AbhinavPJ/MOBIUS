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
    "Atheltics",
    "Volleyball",
    "Basketabll",
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
    "Rock",
    "Pop",
    "Hip-Hop",
    "Jazz",
    "Classical",
    "Electronic",
    "Blues",
    "Reggae",
    "Country",
    "Metal",
    "Folk",
    "RnB"
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

      widget.onProfileUpdated();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Profile updated!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    }
  }

  Widget _buildMultiSelectField({
    required String label,
    required bool isEditing,
    required List<String> options,
    required List<String> selectedValues,
    required VoidCallback onEdit,
    required Function(List<String>) onSelectionChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Spacer(),
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
                children: options.map((option) {
                  final isSelected = selectedValues.contains(option);
                  return FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      if (selected && selectedValues.length >= 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('You can select up to 5 items only.')),
                        );
                        return;
                      }
                      final updatedSelection =
                          List<String>.from(selectedValues);
                      if (selected) {
                        updatedSelection.add(option);
                      } else {
                        updatedSelection.remove(option);
                      }
                      onSelectionChanged(updatedSelection);
                    },
                  );
                }).toList(),
              )
            : Text(selectedValues.join(', '), style: TextStyle(fontSize: 16)),
        SizedBox(height: 16),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            : Text(selectedValue, style: TextStyle(fontSize: 16)),
        SizedBox(height: 16),
      ],
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
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
                setState(() {
                  _isEditingHangout = !_isEditingHangout;
                });
              },
              onSelectionChanged: (newSelection) => setState(() {
                _selectedHangoutSpot = newSelection;
              }),
            ),
            _buildMultiSelectField(
              label: "Clubs",
              isEditing: _isEditingClubs,
              options: _allClubs,
              selectedValues: _selectedClubs,
              onEdit: () {
                if (_isEditingClubs) {
                  _saveProfile('clubs', _selectedClubs);
                }
                setState(() {
                  _isEditingClubs = !_isEditingClubs;
                });
              },
              onSelectionChanged: (newSelection) => setState(() {
                _selectedClubs = newSelection;
              }),
            ),
            _buildMultiSelectField(
              label: "Movie Genres",
              isEditing: _isEditingMovieGenres,
              options: _allMovieGenres,
              selectedValues: _selectedMovieGenres,
              onEdit: () {
                if (_isEditingMovieGenres) {
                  _saveProfile('movie_genres', _selectedMovieGenres);
                }
                setState(() {
                  _isEditingMovieGenres = !_isEditingMovieGenres;
                });
              },
              onSelectionChanged: (newSelection) => setState(() {
                _selectedMovieGenres = newSelection;
              }),
            ),
            _buildMultiSelectField(
              label: "Music genres",
              isEditing: _isEditingMusicGenres,
              options: _allMusicGenres,
              selectedValues: _selectedMusicGenres,
              onEdit: () {
                if (_isEditingMusicGenres) {
                  _saveProfile('music_genres', _selectedMusicGenres);
                }
                setState(() {
                  _isEditingMusicGenres = !_isEditingMusicGenres;
                });
              },
              onSelectionChanged: (newSelection) => setState(() {
                _selectedMusicGenres = newSelection;
              }),
            ),
            _buildMultiSelectField(
              label: "Sports",
              isEditing: _isEditingSports,
              options: _allSports,
              selectedValues: _selectedSports,
              onEdit: () {
                if (_isEditingSports) {
                  _saveProfile('sports', _selectedSports);
                }
                setState(() {
                  _isEditingSports = !_isEditingSports;
                });
              },
              onSelectionChanged: (newSelection) => setState(() {
                _selectedSports = newSelection;
              }),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _logout,
                child: Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
