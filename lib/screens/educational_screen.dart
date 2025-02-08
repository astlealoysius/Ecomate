import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import 'video_lesson_screen.dart';
import 'quiz_screen.dart';

class EducationalScreen extends StatefulWidget {
  const EducationalScreen({Key? key}) : super(key: key);

  @override
  _EducationalScreenState createState() => _EducationalScreenState();
}

class _EducationalScreenState extends State<EducationalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _dailyTips = [];
  List<Map<String, dynamic>> _quizzes = [];
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

  List<Map<String, dynamic>> _getRandomTips(int count) {
    if (_dailyTips.isEmpty) return [];
    final tips = List<Map<String, dynamic>>.from(_dailyTips);
    tips.shuffle(_random);
    return tips.take(count).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn & Grow'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tutorials'),
            Tab(text: 'Daily Tips'),
            Tab(text: 'Quizzes'),
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

  Widget _buildTutorialsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tutorials.length,
      itemBuilder: (context, index) {
        final tutorial = tutorials[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: Icon(
              tutorial['icon'] as IconData,
              color: Theme.of(context).primaryColor,
              size: 32,
            ),
            title: Text(
              tutorial['title'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            children: (tutorial['lessons'] as List<Map<String, dynamic>>)
                .map((lesson) => ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoLessonScreen(
                              title: lesson['title'],
                              videoId: lesson['videoId'],
                              description: lesson['description'],
                              keyPoints: List<String>.from(lesson['keyPoints']),
                            ),
                          ),
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 8,
                      ),
                      title: Text(lesson['title']),
                      subtitle: Text(lesson['description']),
                      trailing: Chip(
                        label: Text(lesson['duration']),
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildDailyTipsTab() {
    final randomTips = _getRandomTips(3);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: randomTips.map((tip) => Column(
        children: [
          _buildTipCard(
            tip['type'] as String,
            tip['content'] as String,
            _getIconData(tip['icon'] as String),
          ),
          const SizedBox(height: 16),
        ],
      )).toList(),
    );
  }

  Widget _buildTipCard(String title, String content, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
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
          elevation: 4,
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.quiz,
                        color: Theme.of(context).primaryColor,
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
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
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
