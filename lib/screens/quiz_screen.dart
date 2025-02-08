import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  final Map<String, dynamic> quiz;

  const QuizScreen({Key? key, required this.quiz}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _quizCompleted = false;
  List<int> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    _userAnswers = List.filled(
      (widget.quiz['questions'] as List).length,
      -1,
    );
  }

  void _handleAnswer(int selectedAnswer) {
    if (_userAnswers[_currentQuestionIndex] != -1) return;

    setState(() {
      _userAnswers[_currentQuestionIndex] = selectedAnswer;
      if (selectedAnswer ==
          widget.quiz['questions'][_currentQuestionIndex]['correctAnswer']) {
        _score++;
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (_currentQuestionIndex < widget.quiz['questions'].length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
      } else {
        setState(() {
          _quizCompleted = true;
        });
      }
    });
  }

  Color _getOptionColor(int optionIndex) {
    if (_userAnswers[_currentQuestionIndex] == -1) {
      return Colors.white;
    }

    if (_userAnswers[_currentQuestionIndex] == optionIndex) {
      if (optionIndex ==
          widget.quiz['questions'][_currentQuestionIndex]['correctAnswer']) {
        return Colors.green.shade100;
      }
      return Colors.red.shade100;
    }

    if (optionIndex ==
        widget.quiz['questions'][_currentQuestionIndex]['correctAnswer']) {
      return Colors.green.shade100;
    }

    return Colors.white;
  }

  Widget _buildQuestionCard() {
    final question = widget.quiz['questions'][_currentQuestionIndex];
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1}/${widget.quiz['questions'].length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              question['question'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ...(question['options'] as List).asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: _userAnswers[_currentQuestionIndex] == -1
                        ? () => _handleAnswer(index)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: _getOptionColor(index),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _userAnswers[_currentQuestionIndex] == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                          width: _userAnswers[_currentQuestionIndex] == index ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _userAnswers[_currentQuestionIndex] == index
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                              color: _userAnswers[_currentQuestionIndex] == index
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                            ),
                            child: _userAnswers[_currentQuestionIndex] == index
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: _userAnswers[_currentQuestionIndex] == index
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            if (_userAnswers[_currentQuestionIndex] != -1) ...[
              const SizedBox(height: 16),
              Text(
                question['explanation'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz['title']),
      ),
      body: _quizCompleted ? _buildResultCard() : _buildQuestionCard(),
    );
  }
}
