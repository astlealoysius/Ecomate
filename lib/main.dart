import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/map_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/report_screen.dart';
import 'screens/educational_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseDatabase.instance.databaseURL =
      'https://ecomate-64a5b-default-rtdb.firebaseio.com/';
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
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/map': (context) => const MapScreen(isFullScreen: true),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final _authService = AuthService();

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt,
                  color: AppTheme.lightTheme.primaryColor),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _openScannerWithImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library,
                  color: AppTheme.lightTheme.primaryColor),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _openScannerWithImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openScannerWithImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ScannerScreen(initialImage: File(pickedFile.path)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return snapshot.hasData ? _buildMainContent() : const AuthScreen();
      },
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoMate',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade100],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MapScreen(isFullScreen: false),
                const SizedBox(height: 20),
                Text('Welcome to EcoMate',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 10),
                Text('Your companion for sustainable living',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildActionCard(
                        Icons.document_scanner,
                        'Scan Waste',
                        'Classify and get disposal suggestions',
                        _showImagePickerOptions),
                    _buildActionCard(Icons.chat_bubble_outline, 'Chat',
                        'Ask questions about waste management', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatScreen(),
                        ),
                      );
                    }),
                    _buildActionCard(Icons.report_problem_outlined,
                        'Report Dumping', 'Report illegal waste dumping', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportScreen(),
                        ),
                      );
                    }),
                    _buildActionCard(Icons.school_outlined, 'Learn',
                        'Educational content and quizzes', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EducationalScreen(),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
      IconData icon, String title, String subtitle, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
