import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ImageProcessingScreen(),
    );
  }
}

class ImageProcessingScreen extends StatefulWidget {
  @override
  _ImageProcessingScreenState createState() => _ImageProcessingScreenState();
}

class _ImageProcessingScreenState extends State<ImageProcessingScreen> {
  File? _imageFile;
  String _responseText = "Select or capture an image to process";
  final ImagePicker _picker = ImagePicker();

  final GenerativeModel model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: 'AIzaSyDxxAf3ehWNFy2hu0BvZblw1If_6M-T02s', // Replace with your actual API key
  );

  Future<void> _pickImage(bool fromCamera) async {
    final pickedFile = await _picker.pickImage(source: fromCamera ? ImageSource.camera : ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _processImageWithGemini(_imageFile!);
    }
  }

  Future<void> _processImageWithGemini(File imageFile) async {
    try {
      final imageData = await imageFile.readAsBytes();

      const prompt = "You are an expert in waste segregation. Analyze this image and: "
          "1) Identify the object(s) being discarded. "
          "2) Classify the object as recyclable, non-recyclable, toxic, or biological. "
          "3) Suggest a recycling method if applicable. "
          "Format: 'Object: [name], Classification: [classification], Recycling Suggestion: [suggestion]'";

      final response = await model.generateContent([
        Content.text(prompt),
        Content.data('image/jpeg', imageData),
      ]);

      setState(() {
        _responseText = response.text ?? 'Error processing image';
      });
    } catch (e) {
      setState(() {
        _responseText = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Waste Segregation AI")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageFile == null
                ? Text("No image selected", style: TextStyle(fontSize: 18))
                : Image.file(_imageFile!, height: 250),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _pickImage(false),
                  child: Text("Select Image"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _pickImage(true),
                  child: Text("Capture Image"),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              _responseText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
