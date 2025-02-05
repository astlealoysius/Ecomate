import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final String? initialMessage;

  const ChatScreen({
    Key? key,
    this.initialMessage,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
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

    if (widget.initialMessage != null) {
      _addMessage(
        ChatMessage(
          text: widget.initialMessage!,
          isUser: false,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      _addMessage(
        ChatMessage(
          text: "I've analyzed your waste item. What would you like to know more about? I can help with:\n"
               "• Specific disposal methods\n"
               "• Recycling alternatives\n"
               "• Environmental impact\n"
               "• Local disposal facilities",
          isUser: false,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.isEmpty) return;

    _textController.clear();
    _addMessage(
      ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    try {
      final prompt = '''
        Act as an expert waste management AI assistant. The user is asking about: $text

        Consider the context of any previous waste classification results and provide:
        1. Direct, practical answers
        2. Specific disposal instructions if relevant
        3. Local recycling options when applicable
        4. Environmental impact information
        5. Alternative eco-friendly suggestions

        Keep responses clear, actionable, and focused on waste management best practices.
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      
      _addMessage(
        ChatMessage(
          text: response.text ?? 'I apologize, I could not process your request.',
          isUser: false,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (e) {
      _addMessage(
        ChatMessage(
          text: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoMate Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (_, int index) => _messages[_messages.length - 1 - index],
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Ask about waste management',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final int timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              child: Icon(
                isUser ? Icons.person : Icons.eco,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? 'You' : 'EcoMate',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: Text(text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 