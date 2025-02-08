import 'package:flutter/material.dart';
import '../services/progress_service.dart';

class QuizScreen extends StatefulWidget {
  final Map<String, dynamic> quiz;

  const QuizScreen({
    Key? key,
    required this.quiz,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<int?> _selectedAnswers = [];
  int _score = 0;
  bool _quizCompleted = false;

  @override
  void initState() {
    super.initState();
    _selectedAnswers = List<int?>.filled(
      (widget.quiz['questions'] as List).length,
      null,
    );
    _loadPreviousScore();
  }

  Future<void> _loadPreviousScore() async {
    final previousScore = await ProgressService.getQuizScore(widget.quiz['title']);
    if (previousScore != null) {
      setState(() {
        _score = previousScore;
      });
    }
  }

  void _selectAnswer(int questionIndex, int optionIndex) {
    setState(() {
      _selectedAnswers[questionIndex] = optionIndex;
      if (optionIndex == widget.quiz['questions'][questionIndex]['correctAnswer']) {
        _score++;
      }
      
      // Check if all questions are answered
      if (!_selectedAnswers.contains(null)) {
        _showResults(); // Automatically show results when all questions are answered
      }
    });
  }

  void _showResults() {
    if (_quizCompleted) return; // Prevent showing results multiple times
    
    setState(() {
      _quizCompleted = true;
    });
    
    // Save the quiz progress
    ProgressService.markQuizAsCompleted(widget.quiz['title'], _score);
    
    // Show results dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _score > (widget.quiz['questions'] as List).length / 2 
                  ? Icons.emoji_events 
                  : Icons.stars,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Your Score: $_score/${(widget.quiz['questions'] as List).length}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _getResultMessage(_score, (widget.quiz['questions'] as List).length),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _getResultMessage(int score, int total) {
    final percentage = (score / total) * 100;
    if (percentage >= 90) {
      return 'Excellent! You\'re a sustainability expert! 🌟';
    } else if (percentage >= 70) {
      return 'Great job! You have good knowledge about eco-friendly practices! 🌱';
    } else if (percentage >= 50) {
      return 'Good effort! Keep learning about sustainability! 💪';
    } else {
      return 'Keep practicing! Every step towards sustainability counts! 🌍';
    }
  }

  Widget _buildQuestionCard(BuildContext context, Map<String, dynamic> question, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Question ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                question['question'],
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ...List.generate(
                (question['options'] as List).length,
                (optionIndex) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildOptionButton(
                    context,
                    question['options'][optionIndex],
                    optionIndex,
                    index,
                  ),
                ),
              ),
              if (_selectedAnswers[index] != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedAnswers[index] == question['correctAnswer']
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _selectedAnswers[index] == question['correctAnswer']
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: _selectedAnswers[index] == question['correctAnswer']
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedAnswers[index] == question['correctAnswer']
                                ? 'Correct!'
                                : 'Incorrect',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: _selectedAnswers[index] == question['correctAnswer']
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question['explanation'],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, String option, int optionIndex, int questionIndex) {
    final bool isSelected = _selectedAnswers[questionIndex] == optionIndex;
    final bool isCorrect = _selectedAnswers[questionIndex] != null &&
        optionIndex == widget.quiz['questions'][questionIndex]['correctAnswer'];
    final bool isWrong = isSelected && !isCorrect;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton(
        onPressed: _selectedAnswers[questionIndex] == null
            ? () => _selectAnswer(questionIndex, optionIndex)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? (isCorrect
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.error.withOpacity(0.1))
              : Theme.of(context).colorScheme.surface,
          foregroundColor: isSelected
              ? (isCorrect
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error)
              : Theme.of(context).colorScheme.onSurface,
          elevation: isSelected ? 0 : 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected
                  ? (isCorrect
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error)
                  : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? (isCorrect
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + optionIndex),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isSelected
                      ? (isCorrect
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error)
                      : null,
                ),
              ),
            ),
            if (_selectedAnswers[questionIndex] != null)
              Icon(
                isCorrect
                    ? Icons.check_circle_outline
                    : (isWrong ? Icons.cancel_outlined : null),
                color: isCorrect
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final percentage = (_score / widget.quiz['questions'].length) * 100;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'Quiz Completed!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'You scored $_score out of ${widget.quiz['questions'].length}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${percentage.round()}%',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: percentage >= 70 ? Colors.green : Colors.red,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back to Quizzes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizHeader() {
    return FutureBuilder<int?>(
      future: ProgressService.getQuizScore(widget.quiz['title']),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Previous Best Score: ${snapshot.data}/${widget.quiz['questions'].length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz['title']),
        actions: [
          TextButton.icon(
            onPressed: _showResults,
            icon: const Icon(Icons.assessment_outlined),
            label: const Text('Results'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuizHeader(),
          Expanded(
            child: _quizCompleted
                ? _buildResultCard()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: widget.quiz['questions'].length,
                    itemBuilder: (context, index) => _buildQuestionCard(
                      context,
                      widget.quiz['questions'][index],
                      index,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
