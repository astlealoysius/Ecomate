import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WasteScanningService {
  late final GenerativeModel model;
  
  WasteScanningService() {
    model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: dotenv.env['GEMINI_API_KEY']!,
      generationConfig: GenerationConfig(
        temperature: 0.4,
        topK: 32,
        topP: 1,
        maxOutputTokens: 4096,
      ),
    );
  }

  Future<ScanResult> scanWaste(Uint8List imageBytes) async {
    try {
      const prompt = '''
        Act as a waste management expert. Analyze this image and provide a detailed classification:

        Format your response EXACTLY as follows:
        OBJECT: [Identify the main item]
        CATEGORY: [Classify as: Recyclable/Non-Recyclable/Toxic/Organic]
        DISPOSAL: [Step-by-step disposal instructions]
        IMPACT: [Environmental impact if not disposed properly]
        TIPS: [3 practical recycling or eco-friendly tips]

        Be specific and practical in your response.
      ''';

      final content = Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]);

      final response = await model.generateContent(content);
      final text = response.text ?? '';
      
      // Parse the structured response
      final Map<String, String> parsedResult = {};
      final lines = text.split('\n');
      for (var line in lines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          final key = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();
          parsedResult[key] = value;
        }
      }

      return ScanResult(
        object: parsedResult['OBJECT'] ?? 'Unknown object',
        category: parsedResult['CATEGORY'] ?? 'Unknown category',
        disposal: parsedResult['DISPOSAL'] ?? 'No disposal information',
        impact: parsedResult['IMPACT'] ?? 'No impact information',
        tips: parsedResult['TIPS'] ?? 'No tips available',
        timestamp: DateTime.now(),
      );
    } catch (error) {
      print('Gemini scanning error: $error');
      throw Exception('Failed to scan waste: $error');
    }
  }

  bool validateImage(Uint8List imageBytes) {
    // Check file size (5MB limit)
    const maxSize = 5 * 1024 * 1024; // 5MB in bytes
    if (imageBytes.length > maxSize) {
      throw Exception('File too large. Please upload an image smaller than 5MB.');
    }
    return true;
  }
}

class ScanResult {
  final String object;
  final String category;
  final String disposal;
  final String impact;
  final String tips;
  final DateTime timestamp;

  ScanResult({
    required this.object,
    required this.category,
    required this.disposal,
    required this.impact,
    required this.tips,
    required this.timestamp,
  });

  String get fullClassification => '''
    🗑️ Object: $object
    ♻️ Category: $category
    🚮 Disposal: $disposal
    🌍 Impact: $impact
    💡 Tips: $tips
  ''';
} 