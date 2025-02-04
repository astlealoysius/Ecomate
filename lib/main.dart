import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/map_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/waste_classifier_card.dart';
import 'theme/app_theme.dart';
import 'screens/scanner_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/report_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configure the database URL
  FirebaseDatabase.instance.databaseURL = 'https://ecomate-64a5b-default-rtdb.firebaseio.com/';
  
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return snapshot.hasData ? const HomeScreen() : const AuthScreen();
        },
      ),
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
  final _authService = AuthService();

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

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppTheme.lightTheme.primaryColor),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.lightTheme.primaryColor),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openScannerWithImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScannerScreen(initialImage: File(pickedFile.path)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoMate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const MapScreen(isFullScreen: false),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.document_scanner,
                          title: 'Scan Waste',
                          subtitle: 'Classify and get disposal suggestions',
                          onTap: _showImagePickerOptions,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.chat_bubble_outline,
                          title: 'Chat',
                          subtitle: 'Ask questions about waste management',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.report_problem_outlined,
                          title: 'Report Dumping',
                          subtitle: 'Report illegal waste dumping',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReportScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: AppTheme.lightTheme.primaryColor),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
