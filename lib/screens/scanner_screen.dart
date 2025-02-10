import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/constants.dart';

class ScannerScreen extends StatefulWidget {
  final File? initialImage;
  
  const ScannerScreen({super.key, this.initialImage});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late final GenerativeModel _model;
  bool _isProcessing = false;

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
    
    // Process initial image if provided
    if (widget.initialImage != null) {
      _processImageWithGemini(widget.initialImage!);
    }
  }

  Future<void> _processImageWithGemini(File imageFile) async {
    try {
      setState(() => _isProcessing = true);
      final imageBytes = await imageFile.readAsBytes();

      const prompt = """
      Act as a waste management expert. Analyze the image and provide:
      1. Object identification (primary item shown)
      2. Waste classification: [Recyclable/Non-Recyclable/Toxic/Biological]
      3. Proper disposal method
      4. Recycling instructions (if applicable)
      5. Environmental impact notes

      Format response as:
      Object: [name]
      Classification: [type]
      Disposal: [instructions]
      Impact: [environmental notes]
      """;

      final response = await _model.generateContent([
        Content.text(prompt),
        Content.data('image/jpeg', imageBytes),
      ]);

      setState(() {
        _messages.add(ChatMessage(
          content: response.text ?? 'Could not analyze image',
          isUser: false,
          image: imageFile,
        ));
      });
    } catch (e) {
      _showError('Analysis Error: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleUserQuestion(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(content: text, isUser: true));
      _textController.clear();
    });

    try {
      final response = await _model.generateContent([
        Content.text("As a waste management expert, answer this question: $text"),
      ]);

      setState(() {
        _messages.add(ChatMessage(
          content: response.text ?? 'Could not generate response',
          isUser: false,
        ));
      });
    } catch (e) {
      _showError('Error: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[800],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;
      await _processImageWithGemini(File(pickedFile.path));
    } catch (e) {
      _showError('Image Error: ${e.toString()}');
    }
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
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
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

  Widget _buildResultCard(String title, String content, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content.replaceFirst(RegExp(r'^\w+: '), '')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _showImagePickerOptions,
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: _messages.map((message) {
                final parts = message.content.split('\n');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          message.image!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildResultCard('Object', parts[0], Icons.delete, Colors.blue),
                    _buildResultCard('Classification', parts[1], Icons.recycling, Colors.green),
                    _buildResultCard('Disposal', parts[2], Icons.delete_outline, Colors.red),
                    _buildResultCard('Impact', parts[3], Icons.eco, Colors.brown),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Ask a question...',
                border: InputBorder.none,
              ),
              onSubmitted: _handleUserQuestion,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: () => _handleUserQuestion(_textController.text),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final File? image;

  ChatMessage({
    required this.content,
    required this.isUser,
    this.image,
  });
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  message.image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            if (message.image != null) const SizedBox(height: 8),
            Text(
              message.content,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}