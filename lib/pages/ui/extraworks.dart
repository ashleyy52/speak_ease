import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StoryGenerationScreen extends StatefulWidget {
  const StoryGenerationScreen({super.key});

  @override
  State<StoryGenerationScreen> createState() => _StoryGenerationScreenState();
}

class _StoryGenerationScreenState extends State<StoryGenerationScreen> with TickerProviderStateMixin {
  String? currentStory;
  bool isPracticed = false;
  List<String> favoriteStories = [];
  bool isGenerating = false;
  List<PracticeRecord> practiceRecords = [];
  late TabController _tabController;
  final TextEditingController _difficultyController = TextEditingController();
  String selectedDifficulty = 'Easy';
  String? selectedPracticeFocus;

  late AnimationController _confettiController;

  final Map<String, List<String>> charactersMap = {
    'Easy': [
      'a curious fox',
      'a brave knight',
      'a playful dolphin',
      'a wise owl',
      'a cheerful robot',
    ],
    'Medium': [
      'an adventurous squirrel',
      'a mysterious wizard',
      'a determined astronaut',
      'a clever detective',
      'a mischievous fairy',
    ],
    'Hard': [
      'a philosophical tortoise',
      'an eccentric scientist',
      'a sophisticated dragon',
      'a revolutionary inventor',
      'a contemplative ghost',
    ],
  };

  final Map<String, List<String>> settingsMap = {
    'Easy': [
      'in a magical forest',
      'on a sunny beach',
      'under the deep ocean',
      'in a big city',
      'on a farm',
    ],
    'Medium': [
      'in an ancient castle',
      'on a mysterious island',
      'through a secret garden',
      'during a thunderstorm',
      'aboard a flying ship',
    ],
    'Hard': [
      'in a parallel dimension',
      'amidst the celestial constellations',
      'through the labyrinthine catacombs',
      'during the renaissance period',
      'within a microscopic world',
    ],
  };

  final Map<String, List<String>> actionsMap = {
    'Easy': [
      'found a shiny treasure',
      'made a new friend',
      'learned to fly',
      'built a cozy house',
      'solved a simple puzzle',
    ],
    'Medium': [
      'discovered a hidden map',
      'rescued a trapped animal',
      'invented a helpful gadget',
      'decoded a secret message',
      'organized a grand celebration',
    ],
    'Hard': [
      'orchestrated an elaborate expedition',
      'negotiated peace between rival kingdoms',
      'unraveled a centuries-old mystery',
      'revolutionized transportation methods',
      'established communication with extraterrestrial beings',
    ],
  };

  final List<String> practiceFocusAreas = [
    'Articulation: S sounds',
    'Articulation: R sounds',
    'Articulation: L sounds',
    'Articulation: TH sounds',
    'Fluency: Slow speech',
    'Voice: Projection',
    'Language: Storytelling',
    'Language: Descriptive words',
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadPracticeRecords();
    _tabController = TabController(length: 3, vsync: this);
    _confettiController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    _difficultyController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteStories = prefs.getStringList('favoriteStories') ?? [];
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteStories', favoriteStories);
  }

  Future<void> _loadPracticeRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordStrings = prefs.getStringList('practiceRecords') ?? [];
    setState(() {
      practiceRecords = recordStrings
          .map((record) {
        final parts = record.split('|');
        if (parts.length >= 3) {
          return PracticeRecord(
            story: parts[0],
            date: DateTime.parse(parts[1]),
            focusArea: parts.length > 3 ? parts[2] : 'General practice',
            difficulty: parts.length > 3 ? parts[3] : 'Easy',
          );
        }
        return null;
      })
          .whereType<PracticeRecord>()
          .toList();
    });
  }

  Future<void> _savePracticeRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordStrings = practiceRecords
        .map((record) =>
    '${record.story}|${record.date.toIso8601String()}|${record.focusArea}|${record.difficulty}')
        .toList();
    await prefs.setStringList('practiceRecords', recordStrings);
  }

  void _generateStory() {
    setState(() {
      isGenerating = true;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      final random = Random();

      final characters = charactersMap[selectedDifficulty] ?? charactersMap['Easy']!;
      final settings = settingsMap[selectedDifficulty] ?? settingsMap['Easy']!;
      final actions = actionsMap[selectedDifficulty] ?? actionsMap['Easy']!;

      final character = characters[random.nextInt(characters.length)];
      final setting = settings[random.nextInt(settings.length)];
      final action = actions[random.nextInt(actions.length)];

      String story;
      if (selectedDifficulty == 'Easy') {
        story = 'Once upon a time, $character $action $setting. The end.';
      } else if (selectedDifficulty == 'Medium') {
        story =
        'Once upon a time, $character was exploring $setting when something amazing happened. The $character $action and learned an important lesson about friendship. Everyone celebrated and lived happily ever after.';
      } else {
        story =
        'In a time long forgotten, $character embarked on an extraordinary journey $setting. After facing numerous challenges and obstacles, the $character finally $action. This remarkable achievement changed everything, teaching everyone about courage, perseverance, and the importance of believing in oneself. The legend of this adventure would be told for generations to come.';
      }

      setState(() {
        currentStory = story;
        isPracticed = false;
        isGenerating = false;
      });
    });
  }

  void _markAsPracticed() {
    if (currentStory == null) return;

    setState(() {
      isPracticed = true;

      practiceRecords.add(PracticeRecord(
        story: currentStory!,
        date: DateTime.now(),
        focusArea: selectedPracticeFocus ?? 'General practice',
        difficulty: selectedDifficulty,
      ));

      _savePracticeRecords();
    });

    _confettiController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 500), () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 15),
                Text(
                  'Great job!',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7B61FF),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You\'ve practiced this story successfully!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: const Color(0xFF333333),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text(
                  'Keep Going!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF7B61FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }

  void _toggleFavorite() {
    if (currentStory == null) return;
    setState(() {
      if (favoriteStories.contains(currentStory)) {
        favoriteStories.remove(currentStory);
      } else {
        favoriteStories.add(currentStory!);
      }
      _saveFavorites();
    });
  }

  void _copyToClipboard() {
    if (currentStory != null) {
      Clipboard.setData(ClipboardData(text: currentStory!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Story copied to clipboard!',
            style: GoogleFonts.nunito(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF7B61FF),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF333333), size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        // actions: [
        //   IconButton(
        //     icon: Container(
        //       padding: const EdgeInsets.all(8),
        //       decoration: BoxDecoration(
        //         color: Colors.white,
        //         shape: BoxShape.circle,
        //         boxShadow: [
        //           BoxShadow(
        //             color: Colors.black.withOpacity(0.1),
        //             blurRadius: 8,
        //             offset: const Offset(0, 2),
        //           ),
        //         ],
        //       ),
        //       child: const Icon(Icons.search, color: Color(0xFF333333), size: 20),
        //     ),
        //     onPressed: () {},
        //   ),
        //   const SizedBox(width: 10),
        // ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFFFF99CC),
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF666666),
              tabs: const [
                Tab(text: 'Stories'),
                Tab(text: 'Favorites'),
                Tab(text: 'Progress'),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F3FF),
              Color(0xFFE8E4FF),
            ],
          ),
        ),
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStoriesTab(),
              _buildFavoritesTab(),
              _buildProgressTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoriesTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildHeaderWithLottie(),
            const SizedBox(height: 20),
            _buildStorySettings(),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _generateStory,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: const Color(0xFF7B61FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                  shadowColor: Colors.black.withOpacity(0.1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_stories, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'Generate Story',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (isGenerating)
              Center(
                child: Column(
                  children: [

                    const SizedBox(height: 10),
                    Text(
                      'Creating your story...',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              )
            else if (currentStory != null)
              _buildStoryCard()
            else
              _buildPlaceholder(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderWithLottie() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7B61FF),
            Color(0xFF99CCFF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practice Speaking',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Generate fun stories to read aloud!',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Lottie.network(
              'https://assets5.lottiefiles.com/packages/lf20_qp1q7mct.json',
              repeat: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorySettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Story Settings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Difficulty:',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDifficultyOption('Easy', const Color(0xFF99CCFF), Icons.star_border),
              _buildDifficultyOption('Medium', const Color(0xFFFFCC99), Icons.star_half),
              _buildDifficultyOption('Hard', const Color(0xFFE60D0D), Icons.star),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Practice Focus:',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: Colors.white,
                isExpanded: true,
                hint: Text(
                  'Select focus area',
                  style: GoogleFonts.nunito(color: const Color(0xFF666666)),
                ),
                value: selectedPracticeFocus,
                style: GoogleFonts.nunito(
                  color: const Color(0xFF333333),
                  fontSize: 16,
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF7B61FF)),
                items: practiceFocusAreas.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedPracticeFocus = newValue;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyOption(String label, Color color, IconData icon) {
    final isSelected = selectedDifficulty == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDifficulty = label;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(isSelected ? 1.0 : 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 24,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF7B61FF) : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard() {
    final wordCount = currentStory!.split(' ').length;
    final isFavorite = favoriteStories.contains(currentStory);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF7B61FF).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.book,
            color: Color(0xFF7B61FF),
            size: 24,
          ),
        ),
        title: Text(
          'Generated Story',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        subtitle: Text(
          '$wordCount words • $selectedDifficulty',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: const Color(0xFF666666),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? const Color(0xFFFF99CC) : const Color(0xFF666666),
              ),
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.content_copy, color: Color(0xFF7B61FF)),
              onPressed: _copyToClipboard,
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        children: [
          Text(
            currentStory!,
            style: GoogleFonts.nunito(
              fontSize: 16,
              height: 1.5,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 10),
          if (selectedPracticeFocus != null)
            Chip(
              backgroundColor: const Color(0xFF7B61FF).withOpacity(0.2),
              label: Text(
                selectedPracticeFocus!,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: const Color(0xFF7B61FF),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: isPracticed ? null : _markAsPracticed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: isPracticed ? const Color(0xFF666666) : const Color(0xFF7B61FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPracticed ? Icons.check : Icons.mic,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPracticed ? 'Practiced' : 'Mark as Practiced',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    if (favoriteStories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://assets5.lottiefiles.com/packages/lf20_0s6tfbuc.json',
              height: 200,
            ),
            const SizedBox(height: 20),
            Text(
              'No favorite stories yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Generate stories and add them to your favorites for easy access',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: const Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: favoriteStories.length,
      itemBuilder: (context, index) {
        final story = favoriteStories[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF99CC).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                color: Color(0xFFFF99CC),
                size: 24,
              ),
            ),
            title: Text(
              story.length > 30 ? '${story.substring(0, 30)}...' : story,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            subtitle: Text(
              '${story.split(' ').length} words',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFF666666),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.content_copy, color: Color(0xFF7B61FF), size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: story));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Story copied to clipboard!',
                          style: GoogleFonts.nunito(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF7B61FF),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFFF99CC), size: 20),
                  onPressed: () {
                    setState(() {
                      favoriteStories.removeAt(index);
                      _saveFavorites();
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressTab() {
    if (practiceRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://assets8.lottiefiles.com/packages/lf20_5tvifusg.json',
              height: 200,
            ),
            const SizedBox(height: 20),
            Text(
              'No practice sessions yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Practice stories and track your progress over time',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: const Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Sort records by date, most recent first
    final sortedRecords = List<PracticeRecord>.from(practiceRecords)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: _buildProgressStats(),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: sortedRecords.length,
            itemBuilder: (context, index) {
              final record = sortedRecords[index];
              final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(record.date);

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  title: Text(
                    formattedDate,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7B61FF),
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5, right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: record.difficulty == 'Easy'
                              ? const Color(0xFF99CCFF).withOpacity(0.2)
                              : record.difficulty == 'Medium'
                              ? const Color(0xFFFFCC99).withOpacity(0.2)
                              : const Color(0xFFFF99CC).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          record.difficulty,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: record.difficulty == 'Easy'
                                ? const Color(0xFF99CCFF)
                                : record.difficulty == 'Medium'
                                ? const Color(0xFFFFCC99)
                                : const Color(0xFFFF99CC),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          record.focusArea,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: const Color(0xFF666666),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  children: [
                    Text(
                      record.story,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: const Color(0xFF333333),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.content_copy, size: 16, color: Color(0xFF7B61FF)),
                          label: Text(
                            'Copy',
                            style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF7B61FF)),
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: record.story));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Story copied to clipboard!',
                                  style: GoogleFonts.nunito(color: Colors.white),
                                ),
                                backgroundColor: const Color(0xFF7B61FF),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStats() {
    // Calculate stats
    final totalPracticed = practiceRecords.length;

    // Count practices by difficulty
    int easyCount = 0;
    int mediumCount = 0;
    int hardCount = 0;

    for (final record in practiceRecords) {
      if (record.difficulty == 'Easy') {
        easyCount++;
      } else if (record.difficulty == 'Medium') {
        mediumCount++;
      } else if (record.difficulty == 'Hard') {
        hardCount++;
      }
    }

    // Count practices by focus areas
    final focusAreaCounts = <String, int>{};
    for (final record in practiceRecords) {
      focusAreaCounts[record.focusArea] = (focusAreaCounts[record.focusArea] ?? 0) + 1;
    }

    // Find most practiced focus area
    String? mostPracticedFocus;
    int mostPracticedCount = 0;

    focusAreaCounts.forEach((focus, count) {
      if (count > mostPracticedCount) {
        mostPracticedFocus = focus;
        mostPracticedCount = count;
      }
    });

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total', totalPracticed.toString(), Icons.auto_stories),
              _buildStatCard('Easy', easyCount.toString(), Icons.sentiment_satisfied, const Color(0xFF99CCFF)),
              _buildStatCard('Medium', mediumCount.toString(), Icons.sentiment_neutral, const Color(0xFFFFCC99)),
              _buildStatCard('Hard', hardCount.toString(), Icons.sentiment_very_dissatisfied, const Color(0xFFFF99CC)),
            ],
          ),
          if (mostPracticedFocus != null) ...[
            const SizedBox(height: 15),
            Text(
              'Most practiced: $mostPracticedFocus',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFF666666),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? const Color(0xFF7B61FF)).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color ?? const Color(0xFF7B61FF),
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFF7B61FF),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: const Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            'Generate a story to practice',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Customize the difficulty and focus area for your practice needs',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Text(
            'How to Use',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF7B61FF),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpItem(
                  '1. Choose Difficulty',
                  'Select Easy, Medium, or Hard based on your speech skill level',
                  Icons.tune,
                ),
                _buildHelpItem(
                  '2. Select Focus Area',
                  'Choose a specific speech skill you want to practice',
                  Icons.center_focus_strong,
                ),
                _buildHelpItem(
                  '3. Generate Story',
                  'Create a new story that includes elements relevant to your focus area',
                  Icons.auto_stories,
                ),
                _buildHelpItem(
                  '4. Practice Speaking',
                  'Read the story aloud, focusing on your selected speech skills',
                  Icons.record_voice_over,
                ),
                _buildHelpItem(
                  '5. Mark as Practiced',
                  'Record your progress to see improvement over time',
                  Icons.check_circle_outline,
                ),
                _buildHelpItem(
                  '6. Save Favorites',
                  'Keep stories you like for future practice sessions',
                  Icons.favorite,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Got it!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7B61FF),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF7B61FF),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF333333),
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PracticeRecord {
  final String story;
  final DateTime date;
  final String focusArea;
  final String difficulty;

  PracticeRecord({
    required this.story,
    required this.date,
    required this.focusArea,
    required this.difficulty,
  });
}