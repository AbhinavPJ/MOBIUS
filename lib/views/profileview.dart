import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/auth/keys.dart';
import 'package:flutter_application_2/views/matchmaking.dart';
import 'package:groq/groq.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  bool _isEditingName = false;
  bool _isEditingphone = false;
  bool _isEditingHangout = false;
  bool _isEditingClubs = false;
  bool _isEditingMovieGenres = false;
  bool _isEditingMusicGenres = false;
  bool _isEditingSports = false;
  bool _isUploadingImage = false;
  String profilepictureurl = "";
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  List<String> _selectedClubs = [];
  List<String> _selectedMovieGenres = [];
  List<String> _selectedMusicGenres = [];
  List<String> _selectedSports = [];
  late String _selectedHangoutSpot;
  final ImagePicker _picker = ImagePicker();

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
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(text: widget.profile.number);
    _selectedClubs = List<String>.from(widget.profile.clubs);
    _selectedMovieGenres = List<String>.from(widget.profile.movieGenres);
    _selectedMusicGenres = List<String>.from(widget.profile.musicGenres);
    _selectedHangoutSpot = widget.profile.hangoutSpot;
    profilepictureurl = widget.profile.profilePicture;
    _selectedSports = List<String>.from(widget.profile.sports);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }

      // Upload to Firebase Storage
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${widget.profile.userId}.jpg');

      final File imageFile = File(pickedFile.path);
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get download URL after upload completes
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore with new profile picture URL
      await _saveProfile('profile_picture', downloadUrl);

      setState(() {
        profilepictureurl = downloadUrl;
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  Future<void> _saveProfile(String field, dynamic value) async {
    try {
      await FirebaseFirestore.instance
          .collection('surveys')
          .doc(widget.profile.userId)
          .update({field: value});

      if (field == 'name' ||
          field == 'clubs' ||
          field == 'sports' ||
          field == 'movie_genres' ||
          field == 'music_genres' ||
          field == 'hangout_spot') {
        String new_description = await _generateProfileDescription(
            field == 'name' ? value : widget.profile.name,
            widget.profile.gender,
            field == 'clubs' ? value : _selectedClubs,
            field == 'sports' ? value : _selectedSports,
            field == 'movie_genres' ? value : _selectedMovieGenres,
            field == 'music_genres' ? value : _selectedMusicGenres,
            field == 'hangout_spot' ? value : _selectedHangoutSpot,
            widget.profile.relationshipType);

        await FirebaseFirestore.instance
            .collection('surveys')
            .doc(widget.profile.userId)
            .update({"description": new_description});
      }

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

                // Editable profile image with loading indicator
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: ClipOval(
                        child: _isUploadingImage
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : profilepictureurl.isNotEmpty
                                ? Image.network(
                                    profilepictureurl,
                                    width: 180,
                                    height: 180,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Color.fromRGBO(165, 18, 178, 1),
                          size: 20,
                        ),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Profile Edit Sections
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      // Name field
                      _buildNameField(),
                      _buildPhoneField(),
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
                const SizedBox(height: 30),
                _buildButton("Delete Account", Colors.red, Colors.white,
                    () async {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    try {
                      // Optional: delete user's data from Firestore
                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(user.uid)
                          .delete();
                      await FirebaseFirestore.instance
                          .collection("surveys")
                          .doc(user.uid)
                          .delete();

                      // Delete user from Firebase Auth
                      await user.delete();

                      // Navigate to login
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (route) => false);
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'requires-recent-login') {
                        _showError(
                            "Please log in again to delete your account.");
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login', (route) => false);
                      } else {
                        _showError("Error: ${e.message}");
                      }
                    }
                  }
                }),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Name",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                _isEditingName ? Icons.check : Icons.edit,
                color: Colors.white,
              ),
              onPressed: () {
                if (_isEditingName) {
                  _saveProfile('name', _nameController.text);
                }
                setState(() => _isEditingName = !_isEditingName);
              },
            ),
          ],
        ),
        _isEditingName
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              )
            : Text(
                _nameController.text,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Phone no.",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                _isEditingphone ? Icons.check : Icons.edit,
                color: Colors.white,
              ),
              onPressed: () {
                if (_isEditingphone) {
                  _saveProfile('number', _phoneController.text);
                }
                setState(() => _isEditingphone = !_isEditingphone);
              },
            ),
          ],
        ),
        _isEditingphone
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              )
            : Text(
                _phoneController.text,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
        const SizedBox(height: 16),
      ],
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
