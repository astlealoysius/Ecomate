import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'screens/map_screen.dart';
import 'widgets/waste_classifier_card.dart';
import 'utils/constants.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _imageFile;
  String _responseText = "Select or capture an image to begin analysis";
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() {
        _imageFile = File(pickedFile.path);
        _isProcessing = true;
      });

      await _processImageWithGemini(_imageFile!);
    } catch (e) {
      _showError('Image Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _processImageWithGemini(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      const prompt = """
      Act as a waste management expert. Analyze the image and provide:
      1. Object identification (primary item shown)
      2. Waste classification: [Recyclable/Non-Recyclable/Toxic/Biological]
      3. Proper disposal method
      4. Recycling instructions (if applicable)
      5. Environmental impact notes

      Format response as:
      🗑️ Object: [name]
      ♻️ Classification: [type]
      🚮 Disposal: [instructions]
      🌱 Impact: [environmental notes]
      """;

      final response = await _model.generateContent([
        Content.text(prompt),
        Content.data('image/jpeg', imageBytes),
      ]);

      setState(() {
        _responseText = response.text ?? 'Could not analyze image';
      });
    } catch (e) {
      _showError('Analysis Error: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[800],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 24), // Add your logo
            const SizedBox(width: 8),
            const Text('EcoMate'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const MapScreen(isFullScreen: false),
            WasteClassifierCard(
              isProcessing: _isProcessing,
              onImagePick: _pickImage,
              responseText: _responseText,
              imageFile: _imageFile,
            ),
          ],
        ),
      ),
    );
  }
}
