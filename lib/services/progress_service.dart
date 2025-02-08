import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const String _viewedVideosKey = 'viewed_videos';
  static const String _completedQuizzesKey = 'completed_quizzes';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Video Progress
  static Future<List<String>> getViewedVideos() async {
    final prefs = await _prefs;
    return prefs.getStringList(_viewedVideosKey) ?? [];
  }

  static Future<void> markVideoAsViewed(String videoId) async {
    final prefs = await _prefs;
    final viewedVideos = await getViewedVideos();
    if (!viewedVideos.contains(videoId)) {
      viewedVideos.add(videoId);
      await prefs.setStringList(_viewedVideosKey, viewedVideos);
    }
  }

  static Future<bool> isVideoViewed(String videoId) async {
    final viewedVideos = await getViewedVideos();
    return viewedVideos.contains(videoId);
  }

  // Quiz Progress
  static Future<List<String>> getCompletedQuizzes() async {
    final prefs = await _prefs;
    return prefs.getStringList(_completedQuizzesKey) ?? [];
  }

  static Future<void> markQuizAsCompleted(String quizId, int score) async {
    final prefs = await _prefs;
    final completedQuizzes = await getCompletedQuizzes();
    final quizKey = '${quizId}_$score';
    if (!completedQuizzes.contains(quizKey)) {
      completedQuizzes.add(quizKey);
      await prefs.setStringList(_completedQuizzesKey, completedQuizzes);
    }
  }

  static Future<bool> isQuizCompleted(String quizId) async {
    final completedQuizzes = await getCompletedQuizzes();
    return completedQuizzes.any((quiz) => quiz.startsWith('${quizId}_'));
  }

  static Future<int?> getQuizScore(String quizId) async {
    final completedQuizzes = await getCompletedQuizzes();
    final quizResult = completedQuizzes.firstWhere(
      (quiz) => quiz.startsWith('${quizId}_'),
      orElse: () => '',
    );
    if (quizResult.isEmpty) return null;
    return int.parse(quizResult.split('_')[1]);
  }
}
