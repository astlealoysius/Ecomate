import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get geminiApiKey {
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }
} 