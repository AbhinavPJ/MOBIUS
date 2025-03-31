import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/auth/keys.dart';
import 'package:groq/groq.dart';
import 'package:image_picker/image_picker.dart';

class SurveyView extends StatefulWidget {
  const SurveyView({super.key});

  @override
  State<SurveyView> createState() => _SurveyViewState();
}

class _SurveyViewState extends State<SurveyView> {
  late Groq groq;
  bool isApiReady = false;
  // Image related variables
  File? _imageFile;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _imageUrl;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _entryNumberController = TextEditingController();
  final TextEditingController _musicGenresController = TextEditingController();
  final TextEditingController _movieGenresController = TextEditingController();
  final TextEditingController _hobbiesController = TextEditingController();
  final TextEditingController _sportsController = TextEditingController();
  final TextEditingController _phonenumbercontroller = TextEditingController();

  // Focus nodes for each text field
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _entryNumberFocusNode = FocusNode();
  final FocusNode _phoneNumberFocusNode = FocusNode();
  final FocusNode _musicGenresFocusNode = FocusNode();
  final FocusNode _movieGenresFocusNode = FocusNode();
  final FocusNode _hobbiesFocusNode = FocusNode();
  final FocusNode _sportsFocusNode = FocusNode();

  // Dropdown selections
  String? _popularity;
  double? _personality;
  String? _relationshipType;
  String? _hangoutSpot;
  String? _gender;
  List<String> _tempMovieGenres = [];
  List<String> _tempMusicGenres = [];
  List<String> _selectedMovieGenres = [];
  List<String> _selectedMusicGenres = [];
  List<String> _tempSports = [];
  List<String> _tempClubs = [];
  List<String> _selectedSports = [];
  List<String> _selectedClubs = [];
  String? number;
  // Multi-page survey tracking
  int _currentPage = 0;

  // Dropdown options
  final List<String> _popularityOptions = [
    "Not very popular",
    "Somewhat popular",
    "Very popular"
  ];

  final List<String> _relationshipOptions = [
    "Serious relationship",
    "Casual dating",
    "One-time",
    "Friendship"
  ];

  final List<String> _hangoutOptions = [
    "CCD",
    "Nescafe",
    "Amul",
    "Night mess",
    "Hostel VR/CR"
  ];

  final List<String> _genders = ["MALE", "FEMALE"];

  @override
  void initState() {
    super.initState();
    initializeGroq();
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

  void dispose() {
    // Dispose controllers when widget is removed
    _phonenumbercontroller.dispose();
    _entryNumberController.dispose();
    _musicGenresController.dispose();
    _movieGenresController.dispose();
    _hobbiesController.dispose();
    _sportsController.dispose();

    // Dispose focus nodes
    _nameFocusNode.dispose();
    _entryNumberFocusNode.dispose();
    _phoneNumberFocusNode.dispose();
    _musicGenresFocusNode.dispose();
    _movieGenresFocusNode.dispose();
    _hobbiesFocusNode.dispose();
    _sportsFocusNode.dispose();

    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Optimize image quality
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = null;
            _imageUrl = null; // Reset previous uploaded image
          });
        } else {
          setState(() {
            _imageFile = File(pickedFile.path);
            _webImage = null;
            _imageUrl = null; // Reset previous uploaded image
          });
        }
      }
    } catch (e) {
      _showSnackBar("Error picking image: $e", isError: true);
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null && _webImage == null) {
      _showSnackBar("Please select an image first", isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Check user authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Create a unique filename for the image
      final fileName =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(fileName);

      // Upload based on platform
      late UploadTask uploadTask;
      if (kIsWeb) {
        if (_webImage == null) {
          throw Exception("No image selected for web");
        }
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        uploadTask = storageRef.putData(_webImage!, metadata);
      } else {
        if (_imageFile == null) {
          throw Exception("No image selected for mobile");
        }
        uploadTask = storageRef.putFile(_imageFile!);
      }

      // Wait for upload to complete and get download URL
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _imageUrl = downloadUrl;
        _isUploading = false;
      });

      _showSnackBar("Image uploaded successfully");
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      print("$e");
      _showSnackBar("Error uploading image: $e", isError: true);
    }
  }

  Future<String> getLLMReply(String prompt) async {
    if (!isApiReady) {
      return "LLM is not ready yet.";
    }
    groq.startChat();
    GroqResponse response = await groq.sendMessage(prompt);
    return response.choices.first.message.content;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
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

  Future<void> _submitSurvey() async {
    // ✅ Validate Required Fields
    if (_entryNumberController.text.isEmpty) {
      _showSnackBar("Please enter your entry number", isError: true);
      setState(() => _currentPage = 0);
      return;
    }

    if (_selectedMovieGenres.isEmpty) {
      _showSnackBar("Please select at least one movie genre", isError: true);
      setState(() => _currentPage = 1);
      return;
    }

    if (_selectedMusicGenres.isEmpty) {
      _showSnackBar("Please select at least one music genre", isError: true);
      setState(() => _currentPage = 1);
      return;
    }

    if (_selectedSports.isEmpty) {
      _showSnackBar("Please select at least one sport", isError: true);
      setState(() => _currentPage = 2);
      return;
    }

    if (_selectedClubs.isEmpty) {
      _showSnackBar("Please select at least one club", isError: true);
      setState(() => _currentPage = 2);
      return;
    }
    if (_gender == null) {
      _showSnackBar("Please enter your gender", isError: true);
      setState(() {
        _currentPage = 1;
      });
    }
    if (_personality == null || _hangoutSpot == null || _popularity == null) {
      _showSnackBar("Please fill all personality questions", isError: true);
      setState(() => _currentPage = 3);
      return;
    }

    if (_relationshipType == null) {
      _showSnackBar("Please select a relationship type", isError: true);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("You need to be logged in to submit a survey",
          isError: true);
      return;
    }

    // ✅ Upload image if not already uploaded
    if (_imageUrl == null && (_imageFile != null || _webImage != null)) {
      await _uploadImage();
    }

    if (_imageUrl == null) {
      _showSnackBar("Please upload a profile picture before submitting",
          isError: true);
      return;
    }
    String descip = await _generateProfileDescription(
        _nameController.text,
        _gender!,
        _selectedClubs,
        _selectedSports,
        _selectedMovieGenres,
        _selectedMusicGenres,
        _hangoutSpot!,
        _relationshipType!);
    // ✅ Prepare Survey Data
    final surveyData = {
      "name": _nameController.text,
      "entry_number": _entryNumberController.text,
      "gender": _gender,
      "movie_genres": _selectedMovieGenres,
      "music_genres": _selectedMusicGenres,
      "popularity": _popularity,
      "sports": _selectedSports,
      "clubs": _selectedClubs,
      "personality": _personality,
      "relationship_type": _relationshipType,
      "hangout_spot": _hangoutSpot,
      "profilePicture": _imageUrl,
      "timestamp": FieldValue.serverTimestamp(),
      "userId": user.uid,
      "number": _phonenumbercontroller.text,
      "rightswipedby": ["peejayy"],
      "description": descip
    };

    try {
      // ✅ Submit to Firestore
      await FirebaseFirestore.instance
          .collection("surveys")
          .doc(user.uid)
          .set(surveyData);

      _showSnackBar("Survey Submitted Successfully!");

      // ✅ Navigate to matchmaking screen
      if (mounted) {
        Navigator.pushNamed(context, '/home');
      }
    } catch (e) {
      _showSnackBar("Error submitting survey: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(165, 18, 178, 0.604),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Mobius Survey",
                    style: TextStyle(
                      fontSize: 32,
                      fontFamily: 'PlayfairDisplay-Regular',
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Complete your profile to start matching",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(225, 255, 255, 255),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Progress indicator
                    LinearProgressIndicator(
                      value: (_currentPage + 1) / 5,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Page ${_currentPage + 1} of 5",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),

                    // Main survey content
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: _buildSurveyPage(_currentPage),
                      ),
                    ),

                    // Navigation buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentPage > 0)
                            _buildButton(
                                "Back", Colors.white, Colors.black, _prevPage)
                          else
                            const SizedBox(width: 80),
                          _buildButton(
                            _currentPage == 4 ? "Submit" : "Next",
                            Colors.white,
                            Colors.black,
                            _handleNextPressed,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNextPressed() {
    if (_currentPage == 1) {
      // ✅ Save selected movie & music genres before moving to the next page
      setState(() {
        _selectedMovieGenres = List.from(_tempMovieGenres);
        _selectedMusicGenres = List.from(_tempMusicGenres);
      });

      print("Selected Movie Genres: $_selectedMovieGenres");
      print("Selected Music Genres: $_selectedMusicGenres");
    } else if (_currentPage == 2) {
      // ✅ Save selected sports & clubs before moving to the next page
      setState(() {
        _selectedSports = List.from(_tempSports);
        _selectedClubs = List.from(_tempClubs);
      });

      print("Selected Sports: $_selectedSports");
      print("Selected Clubs: $_selectedClubs");
    }

    if (_currentPage == 4) {
      // ✅ If on the last page, submit the survey
      _submitSurvey();
    } else {
      // ✅ Move to the next page
      _nextPage();
    }
  }

  Widget _buildButton(
      String text, Color bgColor, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: 150,
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

  Widget _buildSurveyPage(int index) {
    switch (index) {
      case 0:
        return _buildBasicInfoPage();
      case 1:
        return _buildGenreSelectorPage();
      case 2:
        return _buildSportsPage();
      case 3:
        return _buildPersonalityPage();
      case 4:
        return _buildFinalPage();
      default:
        return _buildBasicInfoPage();
    }
  }

  Widget _buildBasicInfoPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Basic Information",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            "Enter your name",
            _nameController,
            focusNode: _nameFocusNode,
            onSubmitted: (value) {
              FocusScope.of(context).requestFocus(_entryNumberFocusNode);
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            "Enter your Entry Number",
            _entryNumberController,
            focusNode: _entryNumberFocusNode,
            onSubmitted: (value) {
              FocusScope.of(context).requestFocus(_phoneNumberFocusNode);
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            "Enter your phone number",
            _phonenumbercontroller,
            focusNode: _phoneNumberFocusNode,
            onSubmitted: (value) {
              // No more text fields on this page, so we'll handle differently
              // Either focus on the dropdown or just move to next page
              _nextPage();
            },
          ),
          const SizedBox(height: 20),
          _buildDropdown("  What is your Gender?", _genders, (value) {
            setState(() {
              _gender = value;
            });
          }, _gender)
        ],
      ),
    );
  }

  Widget _buildSportsPage() {
    final List<String> _sportsOptions = [
      "Badminton",
      "Squash",
      "Tennis",
      "Table tennis",
      "Atheltics",
      "Volleyball",
      "Cricket",
      "Basketball",
      "Chess",
      "Weightlifting",
      "Competitive programming",
      "Aquatics",
    ];

    final List<String> _clubsOptions = [
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
      "Dance club"
          "Drama club",
      "Spic Macay"
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What sports do you play?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Selected Sports
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tempSports.map((sport) {
              return _buildChip(sport, selected: true);
            }).toList(),
          ),

          const SizedBox(height: 20),
          const Text(
            "What clubs are you mostly into?",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 10),

          // Sports Selection
          SizedBox(
            height: 150,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _sportsOptions.map((sport) {
                  return _buildChip(sport,
                      selected: _tempSports.contains(sport),
                      onTap: () => _toggleSelection(sport, _tempSports));
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 30),
          const Text(
            "What clubs are you mostly into?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Selected Clubs
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tempClubs.map((club) {
              return _buildChip(club, selected: true);
            }).toList(),
          ),

          const SizedBox(height: 20),
          const Text(
            "Choose from the options below:",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 10),

          // Clubs Selection
          SizedBox(
            height: 150,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _clubsOptions.map((club) {
                  return _buildChip(club,
                      selected: _tempClubs.contains(club),
                      onTap: () => _toggleSelection(club, _tempClubs));
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "About Your Personality",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildDropdown("How popular are you?", _popularityOptions, (value) {
            setState(() {
              _popularity = value;
            });
          }, _popularity),
          const SizedBox(height: 20),
          _buildSlider(
            "On a scale of 0.0 to 10.0, where 10.0 is a complete extrovert, which number best describes your personality?",
            (value) {
              setState(() {
                _personality = value;
              });
            },
            _personality ?? 5.0, // Default value in case it's null
          ),
          const SizedBox(height: 20),
          _buildDropdown(
            "What is your favourite hangout spot in IITD?",
            _hangoutOptions,
            (value) {
              setState(() {
                _hangoutSpot = value;
              });
            },
            _hangoutSpot,
          ),
        ],
      ),
    );
  }

  Widget _buildFinalPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Almost Done!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildDropdown("What kind of relationship are you looking for?",
              _relationshipOptions, (value) {
            setState(() {
              _relationshipType = value;
            });
          }, _relationshipType),
          const SizedBox(height: 30),
          const Center(
            child: Text(
              "Upload a Profile Picture",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 15),
          _buildImageUploadWidget(),
        ],
      ),
    );
  }

  Widget _buildGenreSelectorPage() {
    final List<String> movieGenres = [
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

    final List<String> musicGenres = [
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What kind of movies do you prefer watching?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Selected Movie Genres
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tempMovieGenres.map((genre) {
              return _buildChip(genre, selected: true);
            }).toList(),
          ),

          const SizedBox(height: 20),
          const Text(
            "Choose from the options below:",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 10),

          // Movie Genres Selection
          SizedBox(
            height: 150,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: movieGenres.map((genre) {
                  return _buildChip(genre,
                      selected: _tempMovieGenres.contains(genre),
                      onTap: () => _toggleSelection(genre, _tempMovieGenres));
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 30),
          const Text(
            "What kind of music do you generally listen to?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Selected Music Genres
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tempMusicGenres.map((genre) {
              return _buildChip(genre, selected: true);
            }).toList(),
          ),

          const SizedBox(height: 20),
          const Text(
            "Choose from the options below:",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 10),

          // Music Genres Selection
          SizedBox(
            height: 150,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: musicGenres.map((genre) {
                  return _buildChip(genre,
                      selected: _tempMusicGenres.contains(genre),
                      onTap: () => _toggleSelection(genre, _tempMusicGenres));
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(String genre, List<String> list) {
    setState(() {
      if (list.contains(genre)) {
        list.remove(genre);
      } else if (list.length < 5) {
        list.add(genre);
      }
    });
  }

  Widget _buildChip(String label,
      {bool selected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontSize: 12,
          ),
        ),
        backgroundColor:
            selected ? Color.fromARGB(255, 179, 255, 0) : Colors.grey[850],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: selected ? Colors.redAccent : Colors.transparent,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildImageUploadWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(75),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(75),
              child: _getImageWidget(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text("Select"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed:
                  _isUploading || (_imageFile == null && _webImage == null)
                      ? null
                      : _uploadImage,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_isUploading ? "Uploading..." : "Upload"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
        if (_imageUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Image uploaded successfully!",
                  style: TextStyle(color: Colors.green[200]),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _getImageWidget() {
    if (_imageUrl != null) {
      return Image.network(
        _imageUrl!,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _fallbackImage(),
      );
    } else if (_webImage != null) {
      return Image.memory(
        _webImage!,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    } else if (_imageFile != null) {
      return Image.file(
        _imageFile!,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    } else {
      return _fallbackImage();
    }
  }

  Widget _fallbackImage() {
    return Container(
      color: Colors.grey[800],
      width: 150,
      height: 150,
      child: const Icon(
        Icons.person,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller,
      {int maxLines = 1, FocusNode? focusNode, Function(String)? onSubmitted}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }

  Widget _buildDropdown(String title, List<String> options,
      ValueChanged<String?> onChanged, String? selectedValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: const Color.fromRGBO(0, 50, 100, 1),
              value: selectedValue,
              hint: const Text(
                "Select an option",
                style: TextStyle(color: Colors.white),
              ),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: options
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e,
                            style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(
      String title, ValueChanged<double> onChanged, double val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16.0,
            color: Colors.white,
          ),
        ),
        Slider(
          label: val.toStringAsFixed(1),
          value: val,
          onChanged: onChanged,
          min: 0,
          max: 10,
          divisions: 100, // Optional: Adds discrete steps
        ),
        Text(
          "Your Number: ${val.toStringAsFixed(1)}",
          style: const TextStyle(
            fontSize: 18.0,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
