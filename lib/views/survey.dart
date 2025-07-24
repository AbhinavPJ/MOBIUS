import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/auth/keys.dart';
import 'package:groq/groq.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class SurveyView extends StatefulWidget {
  const SurveyView({super.key});

  @override
  State<SurveyView> createState() => _SurveyViewState();
}

class _SurveyViewState extends State<SurveyView> {
  late Groq groq;
  bool isApiReady = false;
  File? _imageFile;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _imageUrl;

  String _userDescription = "";
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _entryNumberController = TextEditingController();
  final TextEditingController _phonenumbercontroller = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _gendercontroller = TextEditingController();
  late TextEditingController _descriptionController = TextEditingController();
  List<String> _selectedGenders = [];
  final List<String> _genderOptions = ['Men', 'Women'];
  final FocusNode _genderFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _branchFocusNode = FocusNode();
  final FocusNode _yearFocusNode = FocusNode();
  final FocusNode _phoneNumberFocusNode = FocusNode();

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

  int _currentPage = 0;

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
    "SAC",
    "CCD",
    "Nescafe",
    "Amul",
    "Night mess",
    "Hostel VR/CR",
    "BT Lawn"
  ];

  @override
  void initState() {
    super.initState();
    initializeGroq();
  }

  Future<void> initializeGroq() async {
    await Secrets.loadSecrets();
    setState(() {
      groq = Groq(apiKey: Secrets.groqApiKey, model: "llama-3.3-70b-versatile");
      isApiReady = true;
    });
  }

  @override
  void dispose() {
    _phonenumbercontroller.dispose();
    _entryNumberController.dispose();
    _descriptionController.dispose();
    _genderFocusNode.dispose();
    _nameFocusNode.dispose();
    _branchFocusNode.dispose();
    _yearFocusNode.dispose();
    _phoneNumberFocusNode.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 5) setState(() => _currentPage++);
  }

  void _prevPage() {
    if (_currentPage > 0) setState(() => _currentPage--);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = null;
            _imageUrl = null;
          });
        } else {
          setState(() {
            _imageFile = File(pickedFile.path);
            _webImage = null;
            _imageUrl = null;
          });
        }
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null && _webImage == null) {
      _showSnackBar("Please select an image first", isError: true);
      return;
    }
    setState(() => _isUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final fileName =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(fileName);

      late UploadTask uploadTask;
      if (kIsWeb) {
        if (_webImage == null) throw Exception("No image selected for web");
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        uploadTask = storageRef.putData(_webImage!, metadata);
      } else {
        if (_imageFile == null) throw Exception("No image selected for mobile");
        uploadTask = storageRef.putFile(_imageFile!);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _imageUrl = downloadUrl;
        _isUploading = false;
      });
      _showSnackBar("Image uploaded successfully");
    } catch (e) {
      setState(() => _isUploading = false);
      _showSnackBar("Error uploading image: $e", isError: true);
    }
  }

  Future<String> getLLMReply(String prompt) async {
    if (!isApiReady) return "LLM is not ready yet.";
    groq.startChat();
    GroqResponse response = await groq.sendMessage(prompt);
    return response.choices.first.message.content;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
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
"Envogue": Fashion club,
"Enactus":NGO social service etc. club,
"Debsoc":Debate society,
"Lit club":Literary club (discuss books,word games),
"QC": Quizzing club,
"Design club":Do pretty stuff like UI/UX design,photo editing,graphics, VFX ,
"Dance club":they dance
"Drama club":Drama club,
"Spic Macay":Classical dance,
"HS": Hindi Samiti,
""";
    groq.startChat();
    GroqResponse response = await groq.sendMessage(promptu);
    return response.choices.first.message.content;
  }

  Future<void> _submitSurvey() async {
    if (_entryNumberController.text.isEmpty) {
      _showSnackBar("Year/Branch is required", isError: true);
      return;
    }

    if (_selectedMovieGenres.isEmpty) {
      _showSnackBar("Please select at least one movie genre", isError: true);
      return;
    }

    if (_selectedMusicGenres.isEmpty) {
      _showSnackBar("Please select at least one music genre", isError: true);
      return;
    }

    if (_selectedSports.isEmpty) {
      _showSnackBar("Please select at least one sport", isError: true);
      return;
    }

    if (_selectedClubs.isEmpty) {
      _showSnackBar("Please select at least one club", isError: true);
      return;
    }

    if (_gender == '') {
      _showSnackBar("Please select your gender", isError: true);
      return;
    }

    if (_personality == null) {
      _showSnackBar("Please select a personality type", isError: true);
      return;
    }

    if (_hangoutSpot == null) {
      _showSnackBar("Please select a preferred hangout spot", isError: true);
      return;
    }

    if (_popularity == null) {
      _showSnackBar("Please rate your popularity", isError: true);
      return;
    }

    if (_relationshipType == null) {
      _showSnackBar("Please select a relationship type", isError: true);
      return;
    }

    if (_imageUrl == null) {
      _showSnackBar("Please upload a profile image", isError: true);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("You need to be logged in", isError: true);
      return;
    }

    String descip = _userDescription.isEmpty || _userDescription == "AI"
        ? await _generateProfileDescription(
            _nameController.text,
            _gender!,
            _selectedClubs,
            _selectedSports,
            _selectedMovieGenres,
            _selectedMusicGenres,
            _hangoutSpot!,
            _relationshipType!)
        : _userDescription;

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
      await FirebaseFirestore.instance
          .collection("surveys")
          .doc(user.uid)
          .set(surveyData);
      _showSnackBar("Survey Submitted Successfully!");
      if (mounted) Navigator.pushNamed(context, '/home');
    } catch (e) {
      _showSnackBar("Error submitting survey: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mobius Survey',
          style: TextStyle(
            color: Color(0xFF2E2E2E),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF2E2E2E)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
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
              Color(0xFFF3E5F5), // Soft lavender
              Colors.white,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      "Complete your profile to start matching",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF424242),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / 6,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF6C63FF)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Page ${_currentPage + 1} of 6",
                      style: const TextStyle(
                        color: Color(0xFF424242),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey(_currentPage), // Unique key for each page
                  child: AnimationLimiter(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      children: _buildSurveyPage(_currentPage),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      _buildButton("Back", _prevPage)
                    else
                      const SizedBox(width: 120),
                    _buildButton(_currentPage == 5 ? "Submit" : "Next",
                        _handleNextPressed),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNextPressed() {
    if (_currentPage == 1) {
      setState(() {
        _selectedMovieGenres = List.from(_tempMovieGenres);
        _selectedMusicGenres = List.from(_tempMusicGenres);
      });
    } else if (_currentPage == 2) {
      setState(() {
        _selectedSports = List.from(_tempSports);
        _selectedClubs = List.from(_tempClubs);
      });
    }
    if (_currentPage == 5) {
      _submitSurvey();
    } else {
      _nextPage();
    }
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 120,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  List<Widget> _buildSurveyPage(int index) {
    switch (index) {
      case 0:
        return _buildProfileForm();
      case 1:
        return _buildGenreSelectorPage();
      case 2:
        return _buildSportsPage();
      case 3:
        return _buildPersonalityPage();
      case 4:
        return _buildDescriptionPage();
      case 5:
        return _buildFinalPage();
      default:
        return _buildProfileForm();
    }
  }

  Widget _buildCard({required Widget child, required int index}) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        horizontalOffset: 50.0,
        child: FadeInAnimation(
          child: Card(
            elevation: 6,
            shadowColor: Colors.black38,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE3F2FD),
                    Color(0xFFF3E5F5),
                    Color(0xFFFFFFFF),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProfileForm() {
    return [
      _buildCard(
        index: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Name",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              decoration: InputDecoration(
                hintText: "Enter your name",
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
      _buildCard(
        index: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Year & Branch",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _yearController.text.isEmpty
                        ? null
                        : _yearController.text,
                    decoration: InputDecoration(
                      hintText: "Entry Year",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      '2019',
                      '2020',
                      '2021',
                      '2022',
                      '2023',
                      '2024',
                    ]
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _yearController.text = value ?? '';
                        _updateEntryNumber();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _branchController.text.isEmpty
                        ? null
                        : _branchController.text,
                    decoration: InputDecoration(
                      hintText: "Branch",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      'AM',
                      'BB',
                      'CE',
                      'CH',
                      'CS',
                      'CY',
                      'DD',
                      'EE',
                      'ES',
                      'ME',
                      'MS',
                      'MT',
                      'PH',
                      'TT'
                    ]
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _branchController.text = value ?? '';
                        _updateEntryNumber();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      _buildCard(
        index: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Contact ",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phonenumbercontroller,
              focusNode: _phoneNumberFocusNode,
              decoration: InputDecoration(
                hintText: "Phone Number",
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            buildDatingPreferenceCard()
          ],
        ),
      ),
    ];
  }

  Widget buildDatingPreferenceCard() {
    return _buildCard(
      index: 2, // increment index accordingly
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Whom are you interested in dating?",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E2E2E)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genderOptions
                .map((gender) => _buildChip(
                      gender,
                      selected: _selectedGenders.contains(gender),
                      onTap: () {
                        setState(() {
                          if (_selectedGenders.contains(gender)) {
                            _selectedGenders.remove(gender);
                          } else {
                            _selectedGenders.add(gender);
                          }

                          if (_selectedGenders.contains('Men') &&
                              _selectedGenders.contains('Women')) {
                            _gender = 'Both';
                          } else if (_selectedGenders.contains('Men')) {
                            _gender = 'Female';
                          } else if (_selectedGenders.contains('Women')) {
                            _gender = 'Male';
                          } else {
                            _gender = '';
                          }

                          _gendercontroller.text = _selectedGenders.join(', ');
                        });
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _updateEntryNumber() {
    final yearPrefix = _getYearPrefix(_yearController.text);
    final branchCode = _branchController.text;
    _entryNumberController.text = "$yearPrefix$branchCode";
  }

  String _getYearPrefix(String yearSelection) {
    return yearSelection;
  }

  List<Widget> _buildGenreSelectorPage() {
    final movieGenres = [
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
    final musicGenres = [
      "Pop",
      "K-Pop",
      "Hip-hop",
      "Rap",
      "Metal",
      "Indie Pop",
      "Bollywood",
      "Old Hindi",
      "Punjabi",
      "Classical",
      "Southern cinema music",
      "Rock"
    ];

    return [
      _buildCard(
        index: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Favourite Movie Genres?",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: movieGenres
                  .map((genre) => _buildChip(genre,
                      selected: _tempMovieGenres.contains(genre),
                      onTap: () => _toggleSelection(genre, _tempMovieGenres)))
                  .toList(),
            ),
          ],
        ),
      ),
      _buildCard(
        index: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Favourite Music Genres?",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: musicGenres
                  .map((genre) => _buildChip(genre,
                      selected: _tempMusicGenres.contains(genre),
                      onTap: () => _toggleSelection(genre, _tempMusicGenres)))
                  .toList(),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildSportsPage() {
    final sportsOptions = [
      "Badminton",
      "Squash",
      "Tennis",
      "Table tennis",
      "Athletics",
      "Volleyball",
      "Cricket",
      "Football",
      "Basketball",
      "Chess",
      "Weightlifting",
      "Competitive programming",
      "Aquatics"
    ];
    final clubsOptions = [
      "Aeromodelling",
      "AXLR8R",
      "PAC",
      "ANCC",
      "DevClub",
      "Economics club",
      "Infinity Hyperloop",
      "Business and Consulting club",
      "Robotics",
      "eDc",
      "ARIES",
      "IGTS",
      "iGEM",
      "BlocSoc",
      "PFC",
      "Music Club",
      "FACC",
      "HS",
      "Envogue",
      "Enactus",
      "Debsoc",
      "Lit club",
      "QC",
      "Design club",
      "Dance club",
      "Drama club",
      "Spic Macay"
    ];

    return [
      _buildCard(
        index: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Favourite Sports?",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sportsOptions
                  .map((sport) => _buildChip(sport,
                      selected: _tempSports.contains(sport),
                      onTap: () => _toggleSelection(sport, _tempSports)))
                  .toList(),
            ),
          ],
        ),
      ),
      _buildCard(
        index: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Favourite Clubs?",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: clubsOptions
                  .map((club) => _buildChip(club,
                      selected: _tempClubs.contains(club),
                      onTap: () => _toggleSelection(club, _tempClubs)))
                  .toList(),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildPersonalityPage() {
    return [
      _buildCard(
        index: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Popularity",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _popularity,
              decoration: InputDecoration(
                hintText: "How popular are you?",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _popularityOptions
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => _popularity = value),
            ),
          ],
        ),
      ),
      _buildCard(
        index: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Personality",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E)),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _personality ?? 5.0,
              onChanged: (value) => setState(() => _personality = value),
              min: 0,
              max: 10,
              divisions: 100,
              label: (_personality ?? 5.0).toStringAsFixed(1),
              activeColor: const Color(0xFF6C63FF),
            ),
            Text(
              "0 (Introvert) - 10 (Extrovert): ${_personality?.toStringAsFixed(1) ?? '5.0'}",
              style: TextStyle(color: Colors.black.withOpacity(0.7)),
            ),
          ],
        ),
      ),
      _buildCard(
        index: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hangout Spot",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _hangoutSpot,
              decoration: InputDecoration(
                hintText: "Favorite hangout spot",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _hangoutOptions
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => _hangoutSpot = value),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildDescriptionPage() {
    return [
      _buildCard(
        index: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Describe yourself,or type AI to let AI describe you.",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: "AI",
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) => setState(() => _userDescription = value),
            ),
            const SizedBox(height: 8),
            Text(
              "${_userDescription.length}/500 characters",
              style: TextStyle(
                  color: _userDescription.length > 500
                      ? Colors.red
                      : Colors.black.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildFinalPage() {
    return [
      _buildCard(
        index: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Relationship Type",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _relationshipType,
              decoration: InputDecoration(
                hintText: "What are you looking for?",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _relationshipOptions
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => _relationshipType = value),
            ),
          ],
        ),
      ),
      _buildCard(
        index: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Profile Picture",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E)),
            ),
            const SizedBox(height: 16),
            _buildImageUploadWidget(),
          ],
        ),
      ),
    ];
  }

  Widget _buildChip(String label,
      {bool selected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor: selected
            ? const Color(0xFF6C63FF).withOpacity(0.2)
            : Colors.grey[200],
        labelStyle:
            TextStyle(color: selected ? const Color(0xFF6C63FF) : Colors.black),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  void _toggleSelection(String item, List<String> list) {
    setState(() {
      if (list.contains(item)) {
        list.remove(item);
      } else if (list.length < 5) {
        list.add(item);
      }
    });
  }

  Widget _buildImageUploadWidget() {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF6C63FF), width: 2),
            borderRadius: BorderRadius.circular(75),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(75),
            child: _getImageWidget(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickImage,
              icon: const Icon(Icons.photo_library, size: 20),
              label: const Text("Select"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
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
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_upload, size: 20),
              label: Text(_isUploading ? "Uploading..." : "Upload"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
        if (_imageUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle,
                    color: Color(0xFF6C63FF), size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Uploaded!",
                  style: TextStyle(
                      color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _getImageWidget() {
    if (_isUploading && (_webImage != null || _imageFile != null)) {
      // Show local preview during upload
      if (_webImage != null) {
        return Image.memory(_webImage!,
            fit: BoxFit.cover, width: 150, height: 150);
      } else if (_imageFile != null) {
        return Image.file(_imageFile!,
            fit: BoxFit.cover, width: 150, height: 150);
      }
    }

    if (_imageUrl != null) {
      return Image.network(
        _imageUrl!,
        fit: BoxFit.cover,
        width: 150,
        height: 150,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else if (_webImage != null) {
      return Image.memory(_webImage!,
          fit: BoxFit.cover, width: 150, height: 150);
    } else if (_imageFile != null) {
      return Image.file(_imageFile!,
          fit: BoxFit.cover, width: 150, height: 150);
    }

    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.person, size: 80, color: Colors.white),
    );
  }
}
