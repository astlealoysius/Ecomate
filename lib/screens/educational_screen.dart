import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import 'video_lesson_screen.dart';
import 'quiz_screen.dart';
import '../services/progress_service.dart';
import 'progress_screen.dart'; // Import ProgressScreen

class EducationalScreen extends StatefulWidget {
  const EducationalScreen({Key? key}) : super(key: key);

  @override
  _EducationalScreenState createState() => _EducationalScreenState();
}

class _EducationalScreenState extends State<EducationalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _dailyTips = [];
  List<Map<String, dynamic>> _quizzes = [];
  Set<int> _usedTipIndices = {};
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDailyTips();
    _loadQuizzes();
  }

  Future<void> _loadDailyTips() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/daily_tips.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      setState(() {
        _dailyTips = List<Map<String, dynamic>>.from(jsonData['tips']);
        _usedTipIndices.clear(); // Reset used indices when reloading tips
      });
    } catch (e) {
      debugPrint('Error loading daily tips: $e');
    }
  }

  Future<void> _loadQuizzes() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/quizzes.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      setState(() {
        _quizzes = List<Map<String, dynamic>>.from(jsonData['quizzes']);
      });
    } catch (e) {
      debugPrint('Error loading quizzes: $e');
    }
  }

  Map<String, dynamic>? _getRandomUniqueTip() {
    if (_dailyTips.isEmpty) return null;
    if (_usedTipIndices.length >= _dailyTips.length) {
      // All tips have been used, reset the tracking
      _usedTipIndices.clear();
    }

    int randomIndex;
    do {
      randomIndex = _random.nextInt(_dailyTips.length);
    } while (_usedTipIndices.contains(randomIndex));

    _usedTipIndices.add(randomIndex);
    return _dailyTips[randomIndex];
  }

  List<Map<String, dynamic>> _getRandomTips(int count) {
    List<Map<String, dynamic>> selectedTips = [];
    
    for (int i = 0; i < count; i++) {
      final tip = _getRandomUniqueTip();
      if (tip != null) {
        selectedTips.add(tip);
      }
    }
    
    return selectedTips;
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'lightbulb_outline':
        return Icons.lightbulb_outline;
      case 'info_outline':
        return Icons.info_outline;
      case 'assignment_outlined':
        return Icons.assignment_outlined;
      default:
        return Icons.eco;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTipCard(String title, String content, IconData icon) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialCard(Map<String, dynamic> tutorial) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              tutorial['icon'] as IconData,
              color: Theme.of(context).colorScheme.secondary,
              size: 24,
            ),
          ),
          title: Text(
            tutorial['title'],
            style: Theme.of(context).textTheme.titleLarge,
          ),
          children: (tutorial['lessons'] as List<Map<String, dynamic>>)
              .map((lesson) => _buildLessonCard(lesson))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson) {
    return FutureBuilder<bool>(
      future: ProgressService.isVideoViewed(lesson['videoId']),
      builder: (context, snapshot) {
        final bool isViewed = snapshot.data ?? false;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoLessonScreen(
                    title: lesson['title'],
                    videoId: lesson['videoId'],
                    description: lesson['description'],
                    keyPoints: List<String>.from(lesson['keyPoints']),
                    onVideoComplete: () {
                      ProgressService.markVideoAsViewed(lesson['videoId']);
                    },
                  ),
                ),
              );
            },
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    lesson['title'],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (isViewed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Viewed',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  lesson['description'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      lesson['duration'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Icon(
              Icons.play_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTutorialsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tutorials.length,
      itemBuilder: (context, index) {
        final tutorial = tutorials[index];
        return _buildTutorialCard(tutorial);
      },
    );
  }

  Widget _buildDailyTipsTab() {
    final randomTips = _getRandomTips(3);
    
    if (randomTips.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: randomTips.map((tip) {
        // Ensure each tip has a unique type label
        String displayType = tip['type'];
        if (randomTips.where((t) => t['type'] == tip['type']).length > 1) {
          displayType = '${tip['type']} #${randomTips.indexOf(tip) + 1}';
        }

        return Column(
          children: [
            _buildTipCard(
              displayType,
              tip['content'] as String,
              _getIconData(tip['icon'] as String),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildQuizzesTab() {
    if (_quizzes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(quiz: quiz),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        quiz['title'],
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Icon(
                        Icons.quiz,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(quiz['description']),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text('${(quiz['questions'] as List).length} questions'),
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(quiz: quiz),
                            ),
                          );
                        },
                        child: const Text('Start Quiz'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn & Grow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'View Progress',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProgressScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.school_outlined),
              text: 'Tutorials',
            ),
            Tab(
              icon: Icon(Icons.tips_and_updates_outlined),
              text: 'Daily Tips',
            ),
            Tab(
              icon: Icon(Icons.quiz_outlined),
              text: 'Quizzes',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTutorialsTab(),
          _buildDailyTipsTab(),
          _buildQuizzesTab(),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> tutorials = [
    {
      'title': 'Recycling Basics',
      'icon': Icons.recycling,
      'lessons': [
        {
          'title': 'Why Recycle?',
          'description': 'Discover how recycling conserves resources and reduces environmental pollution.',
          'duration': '6 mins',
          'videoId': 'VlRVPum9cp4',
          'keyPoints': [
            'Closed-loop material lifecycle',
            'Energy savings through recycling',
            'Reducing landfill dependence',
            'Community impact of proper recycling',
          ],
        },
        {
          'title': 'Advanced Sorting',
          'description': 'Deep dive into modern recycling sorting techniques and technology',
          'duration': '4 mins',
          'videoId': 'M7hI3sjyw8M',
          'keyPoints': [
            'Automated sorting systems',
            'Optical recognition technology',
            'Handling contaminated materials',
            'Post-sorting quality control',
          ],
        },
        {
          'title': 'Decoding Symbols',
          'description': 'Comprehensive guide to international recycling identification codes',
          'duration': '5 mins',
          'videoId': 'ZRIXqAbfjaU',
          'keyPoints': [
            'Resin identification codes 1-7',
            'Glass and paper symbols',
            'Biodegradable vs compostable labels',
            'Global standardization efforts',
          ],
        },
      ],
    },
    {
      'title': 'Composting Guide',
      'icon': Icons.eco,
      'lessons': [
        {
          'title': 'Compost Science',
          'description': 'Understand the biological processes behind effective composting',
          'duration': '3 mins',
          'videoId': 'oFlsjRXbnSk',
          'keyPoints': [
            'Carbon-nitrogen balance',
            'Microorganism roles',
            'Temperature phases',
            'Aeration requirements',
          ],
        },
        {
          'title': 'Advanced Composting',
          'description': 'Professional techniques for rapid nutrient-rich compost production',
          'duration': '6 mins',
          'videoId': 'kA3q07paNNE',
          'keyPoints': [
            'Hot composting methods',
            'Vermicomposting setup',
            'Troubleshooting odor issues',
            'Compost maturity testing',
          ],
        },
      ],
    },
    {
      'title': 'Zero Waste Living',
      'icon': Icons.delete_outline,
      'lessons': [
        {
          'title': 'Waste Audit',
          'description': 'Conduct a personal waste analysis and create reduction strategies',
          'duration': '9 mins',
          'videoId': 'GH7yy5amiGw',
          'keyPoints': [
            '7-day tracking method',
            'Identifying waste patterns',
            'Setting reduction goals',
            'Sustainable alternatives mapping',
          ],
        },
        {
          'title': 'Bulk Shopping',
          'description': 'Master the art of package-free grocery shopping and storage',
          'duration': '7 mins',
          'videoId': 'aS84qi14WWc',
          'keyPoints': [
            'Container preparation checklist',
            'Store selection criteria',
            'Quantity optimization',
            'Long-term storage solutions',
          ],
        },
      ],
    },
  ];
}
