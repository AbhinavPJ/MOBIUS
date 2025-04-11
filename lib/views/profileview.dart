import 'dart:io' as io;
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/auth/keys.dart';
import 'package:flutter_application_2/views/matchmaking.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:groq/groq.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class CustomProfileImageCacheManager {
  static const key = 'profileImagesCache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod:
          const Duration(days: 7), // Images considered stale after 7 days
      maxNrOfCacheObjects: 100, // Maximum number of images to cache
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

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

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
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
  bool _isEditingDescription = false;
  late TextEditingController _descriptionController;
  List<String> _selectedClubs = [];
  List<String> _selectedMovieGenres = [];
  List<String> _selectedMusicGenres = [];
  List<String> _selectedSports = [];
  late String _selectedHangoutSpot;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;

  final List<String> _hangoutSpots = [
    "SAC",
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
    "eDc",
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
    "Old Hindi"
        "Punjabi",
    "Classical",
    "Southern cinema music",
    "Rock",
  ];

  @override
  void initState() {
    super.initState();
    initializeGroq();
    _descriptionController =
        TextEditingController(text: widget.profile.description);
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(text: widget.profile.number);
    _selectedClubs = List<String>.from(widget.profile.clubs);
    _selectedMovieGenres = List<String>.from(widget.profile.movieGenres);
    _selectedMusicGenres = List<String>.from(widget.profile.musicGenres);
    _selectedHangoutSpot = widget.profile.hangoutSpot;
    profilepictureurl = widget.profile.profilePicture;
    _selectedSports = List<String>.from(widget.profile.sports);

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "About Me",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF424242),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                _isEditingDescription ? Icons.check : Icons.edit,
                color: const Color(0xFF6C63FF),
              ),
              onPressed: () {
                if (_isEditingDescription) {
                  _saveProfile('description', _descriptionController.text);
                }
                setState(() => _isEditingDescription = !_isEditingDescription);
              },
            ),
          ],
        ),
        _isEditingDescription
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Color(0xFF424242)),
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: "Write something about yourself...",
                    hintStyle: TextStyle(color: Colors.black54),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _descriptionController.text.isNotEmpty
                      ? _descriptionController.text
                      : "No description yet. Add one to tell others about yourself!",
                  style:
                      const TextStyle(fontSize: 16, color: Color(0xFF424242)),
                ),
              ),
      ],
    );
  }

  Widget _buildDescriptionActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.edit_note, color: Colors.white),
          label: const Text(
            "Edit Manually",
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            setState(() {
              _isEditingDescription = true;
            });
          },
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(width: 10),
        TextButton.icon(
          icon: const Icon(Icons.auto_awesome, color: Colors.white),
          label: const Text(
            "Generate",
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () async {
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF6C63FF),
                  ),
                );
              },
            );

            try {
              String generatedDescription = await _generateProfileDescription(
                widget.profile.name,
                widget.profile.gender,
                _selectedClubs,
                _selectedSports,
                _selectedMovieGenres,
                _selectedMusicGenres,
                _selectedHangoutSpot,
                widget.profile.relationshipType,
              );

              setState(() {
                _descriptionController.text = generatedDescription;
              });

              // Save the generated description
              await _saveProfile('description', generatedDescription);

              // Close the loading dialog
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Description generated successfully!'),
                backgroundColor: Color(0xFF6C63FF),
              ));
            } catch (e) {
              // Close the loading dialog
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Error generating description: $e'),
                backgroundColor: Colors.red,
              ));
            }
          },
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
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

      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${widget.profile.userId}.jpg');

      UploadTask uploadTask;
      DocumentReference userRef = FirebaseFirestore.instance
          .collection('surveys')
          .doc(widget.profile.userId);
      userRef.update({'hasUpdated': true});

      if (kIsWeb) {
        // Web: use readAsBytes()
        final Uint8List data = await pickedFile.readAsBytes();
        uploadTask = storageRef.putData(
          data,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // Mobile: use File
        final io.File imageFile = io.File(pickedFile.path);
        uploadTask = storageRef.putFile(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile updated!'),
        backgroundColor: Color(0xFF6C63FF),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating profile: $e'),
        backgroundColor: Colors.red,
      ));
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
                color: Color(0xFF424242),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                _isEditingName ? Icons.check : Icons.edit,
                color: const Color(0xFF6C63FF),
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
            ? TextField(
                controller: _nameController,
                style: const TextStyle(color: Color(0xFF424242)),
                decoration: InputDecoration(
                  hintText: "Enter name",
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.5),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF6C63FF),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide:
                        const BorderSide(color: Color(0xFF6C63FF), width: 2),
                  ),
                ),
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: Color(0xFF6C63FF),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _nameController.text,
                      style: const TextStyle(
                          fontSize: 16, color: Color(0xFF424242)),
                    ),
                  ],
                ),
              ),
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
              "Phone Number",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF424242),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                _isEditingphone ? Icons.check : Icons.edit,
                color: const Color(0xFF6C63FF),
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
            ? TextField(
                controller: _phoneController,
                style: const TextStyle(color: Color(0xFF424242)),
                decoration: InputDecoration(
                  hintText: "Enter phone number",
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.5),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: Color(0xFF6C63FF),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide:
                        const BorderSide(color: Color(0xFF6C63FF), width: 2),
                  ),
                ),
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      color: Color(0xFF6C63FF),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _phoneController.text,
                      style: const TextStyle(
                          fontSize: 16, color: Color(0xFF424242)),
                    ),
                  ],
                ),
              ),
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
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF424242),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                isEditing ? Icons.check : Icons.edit,
                color: const Color(0xFF6C63FF),
              ),
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
                          backgroundColor: Colors.white.withOpacity(0.5),
                          selectedColor:
                              const Color(0xFF6C63FF).withOpacity(0.7),
                          labelStyle: TextStyle(
                            color: selectedValues.contains(option)
                                ? Colors.white
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
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  selectedValues.isNotEmpty
                      ? selectedValues.join(', ')
                      : "None selected",
                  style:
                      const TextStyle(fontSize: 16, color: Color(0xFF424242)),
                ),
              ),
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
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF424242),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                isEditing ? Icons.check : Icons.edit,
                color: const Color(0xFF6C63FF),
              ),
              onPressed: onEdit,
            ),
          ],
        ),
        isEditing
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  value: selectedValue,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  style: const TextStyle(color: Color(0xFF424242)),
                  items: options.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      onSelectionChanged(newValue);
                    }
                  },
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  selectedValue,
                  style:
                      const TextStyle(fontSize: 16, color: Color(0xFF424242)),
                ),
              ),
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
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              text == "Logout" ? Icons.logout : Icons.delete_forever,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showError(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF424242)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Color(0xFF424242),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: AnimationLimiter(
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 600),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      const SizedBox(height: 24),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: _isUploadingImage ? null : _pickImage,
                            child: Hero(
                              tag: 'profileImage-${widget.profile.userId}',
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF6C63FF),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: profilepictureurl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: profilepictureurl,
                                          cacheManager:
                                              CustomProfileImageCacheManager
                                                  .instance,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF6C63FF),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.person,
                                              size: 80,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.person,
                                            size: 80,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF6C63FF),
                              shape: BoxShape.circle,
                            ),
                            child: _isUploadingImage
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                    ),
                                    onPressed: _pickImage,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedCard(child: _buildNameField()),
                      _buildAnimatedCard(child: _buildPhoneField()),
                      _buildAnimatedCard(child: _buildDescriptionField()),
                      _buildAnimatedCard(child: _buildDescriptionActions()),
                      _buildAnimatedCard(
                        child: _buildSingleSelectField(
                          label: "Favorite Hangout Spot",
                          isEditing: _isEditingHangout,
                          options: _hangoutSpots,
                          selectedValue: _selectedHangoutSpot,
                          onEdit: () {
                            if (_isEditingHangout) {
                              _saveProfile(
                                  'hangout_spot', _selectedHangoutSpot);
                            }
                            setState(
                                () => _isEditingHangout = !_isEditingHangout);
                          },
                          onSelectionChanged: (value) {
                            setState(() {
                              _selectedHangoutSpot = value;
                            });
                          },
                        ),
                      ),
                      _buildAnimatedCard(
                        child: _buildMultiSelectField(
                          "Clubs",
                          _isEditingClubs,
                          _allClubs,
                          _selectedClubs,
                          () {
                            if (_isEditingClubs) {
                              _saveProfile('clubs', _selectedClubs);
                            }
                            setState(() => _isEditingClubs = !_isEditingClubs);
                          },
                        ),
                      ),
                      _buildAnimatedCard(
                        child: _buildMultiSelectField(
                          "Preferred Movie Genres",
                          _isEditingMovieGenres,
                          _allMovieGenres,
                          _selectedMovieGenres,
                          () {
                            if (_isEditingMovieGenres) {
                              _saveProfile(
                                  'movie_genres', _selectedMovieGenres);
                            }
                            setState(() =>
                                _isEditingMovieGenres = !_isEditingMovieGenres);
                          },
                        ),
                      ),
                      _buildAnimatedCard(
                        child: _buildMultiSelectField(
                          "Preferred Music Genres",
                          _isEditingMusicGenres,
                          _allMusicGenres,
                          _selectedMusicGenres,
                          () {
                            if (_isEditingMusicGenres) {
                              _saveProfile(
                                  'music_genres', _selectedMusicGenres);
                            }
                            setState(() =>
                                _isEditingMusicGenres = !_isEditingMusicGenres);
                          },
                        ),
                      ),
                      _buildAnimatedCard(
                        child: _buildMultiSelectField(
                          "Sports",
                          _isEditingSports,
                          _allSports,
                          _selectedSports,
                          () {
                            if (_isEditingSports) {
                              _saveProfile('sports', _selectedSports);
                            }
                            setState(
                                () => _isEditingSports = !_isEditingSports);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildButton(
                            "Logout",
                            const Color(0xFF6C63FF),
                            Colors.white,
                            () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/',
                                (route) => false,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: _buildButton(
                          "Delete Account",
                          Colors.redAccent.shade400,
                          Colors.white,
                          () async {
                            bool confirmDelete = false;
                            await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Account?"),
                                content: const Text(
                                  "This action cannot be undone. All your data will be permanently removed.",
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text("Cancel"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () {
                                      confirmDelete = true;
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                            );

                            if (confirmDelete) {
                              try {
                                // Delete Firestore document
                                await FirebaseFirestore.instance
                                    .collection('surveys')
                                    .doc(widget.profile.userId)
                                    .delete();

                                // Delete profile picture if exists
                                if (profilepictureurl.isNotEmpty) {
                                  await FirebaseStorage.instance
                                      .refFromURL(profilepictureurl)
                                      .delete();
                                }

                                // Delete user account
                                await FirebaseAuth.instance.currentUser
                                    ?.delete();

                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/',
                                  (route) => false,
                                );
                              } catch (e) {
                                showError("Error deleting account: $e");
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
