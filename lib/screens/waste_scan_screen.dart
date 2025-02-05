import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/waste_scanning.dart';

class WasteScanScreen extends StatefulWidget {
  const WasteScanScreen({Key? key}) : super(key: key);

  @override
  _WasteScanScreenState createState() => _WasteScanScreenState();
}

class _WasteScanScreenState extends State<WasteScanScreen> {
  final WasteScanningService _scanningService = WasteScanningService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  String? _error;
  ScanResult? _result;
  File? _selectedImage;

  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      
      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      final imageBytes = await pickedFile.readAsBytes();
      await _handleScan(imageBytes);
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
      print('Image selection error: $error');
    }
  }

  Future<void> _handleScan(Uint8List imageBytes) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      _scanningService.validateImage(imageBytes);
      final result = await _scanningService.scanWaste(imageBytes);
      
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });

        // Navigate to chat screen with the result
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              initialMessage: result.fullClassification,
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
      print('Scan error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent accidental back navigation while loading
        return !_isLoading;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Waste Scanner'),
          automaticallyImplyLeading: !_isLoading, // Disable back button while loading
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Upload an image or take a photo to classify the waste',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              
              // Show selected image
              if (_selectedImage != null) ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Image selection buttons
              if (!_isLoading) Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _handleImageSelection(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _handleImageSelection(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose Image'),
                  ),
                ],
              ),

              if (_isLoading) ...[
                const SizedBox(height: 20),
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Analyzing image with AI...'),
                    ],
                  ),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _error = null;
                          _selectedImage = null;
                        }),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ],

              if (_result != null) ...[
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Classification Results:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(_result!.classification),
                        const SizedBox(height: 10),
                        Text(
                          'Scanned at: ${_result!.timestamp.toString()}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/chat');
                          },
                          child: const Text('Ask Questions in Chat'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 