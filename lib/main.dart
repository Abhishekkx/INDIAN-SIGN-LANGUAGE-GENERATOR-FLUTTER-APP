import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Import Google Generative AI package
import 'screens/camera_screen.dart';
import 'screens/gesture_gallery_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISL Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isLoading = false;
  List<String> _steps = [];
  int _currentStep = -1;
  bool _isSpeaking = false;

  // Initialize GeminiService
  final GeminiService _geminiService = GeminiService();

  // Map of words to image paths
  final Map<String, String> _wordToImagePath = {
    'hello': 'assets/images/HI.jpg',
    'thank you': 'assets/gestures/THANKYOU.jpg',
    'promise': 'assets/gestures/PROMISE.jpg',
    'namaste': 'assets/gestures/NAMASTE.jpg',
    'good': 'assets/gestures/GOOD.jpg',
    'wrong':  'assets/gestures/WRONG.jpg',
    // Add more mappings as needed
  };

  String? _matchedImagePath; // Stores the matched image path

  @override
  void initState() {
    super.initState();
    _initSpeechToText();
    _initializeTts();
  }

  Future _initSpeechToText() async {
    bool available = await _speechToText.initialize(
      onError: (error) => print('Speech to Text Error: $error'),
      onStatus: (status) => print('Speech to Text Status: $status'),
    );
    if (!available) {
      print('Speech to Text not available');
    }
  }

  Future _startListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        await _speechToText.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
          },
        );
      }
    }
  }

  Future _stopListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
      await _speechToText.stop();
    }
  }

  Future _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  // Modified method to use Gemini API and check for image matches
  Future<void> _processInstructions(String text) async {
    try {
      setState(() {
        _isLoading = true;
        _steps = [];
        _matchedImagePath = null; // Reset matched image path
      });

      // Check if the input text matches any word in the map
      _wordToImagePath.forEach((word, imagePath) {
        if (text.toLowerCase().contains(word)) {
          _matchedImagePath = imagePath;
        }
      });

      // Generate ISL instructions using GeminiService
      String? islInstructions = await _geminiService.generateISLInstructions(text);

      // Process the generated steps
      final List<String> steps = islInstructions
          .split('\n')
          .where((line) => RegExp(r'^\d+\.').hasMatch(line.trim()))
          .map((line) => line.trim().replaceAll('**', ''))
          .toList();

      setState(() {
        _steps = steps;
        _currentStep = _steps.isEmpty ? -1 : 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future _speakStep(int index) async {
    if (index >= 0 && index < _steps.length) {
      setState(() {
        _currentStep = index;
        _isSpeaking = true;
      });
      await _flutterTts.speak(_steps[index]);
    }
  }

  Future _stopSpeaking() async {
    setState(() {
      _isSpeaking = false;
    });
    await _flutterTts.stop();
  }

  Widget _buildStepCard(String step, int index) {
    bool isCurrentStep = index == _currentStep;
    return Card(
      elevation: isCurrentStep ? 5 : 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isCurrentStep
            ? BorderSide(color: Colors.blue.shade300, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCurrentStep
                ? [Colors.blue.shade100, Colors.white]
                : [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCurrentStep ? Colors.blue : Colors.blue.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step.replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _isSpeaking && isCurrentStep ? Icons.stop : Icons.play_arrow,
                color: Colors.blue,
              ),
              onPressed: () {
                if (_isSpeaking && isCurrentStep) {
                  _stopSpeaking();
                } else {
                  _speakStep(index);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: _currentStep > 0
                ? () => _speakStep(_currentStep - 1)
                : null,
          ),
          IconButton(
            icon: Icon(_isSpeaking ? Icons.stop : Icons.play_arrow),
            onPressed: _steps.isNotEmpty
                ? () {
              if (_isSpeaking) {
                _stopSpeaking();
              } else {
                _speakStep(_currentStep);
              }
            }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: _currentStep < _steps.length - 1
                ? () => _speakStep(_currentStep + 1)
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ISL Generator'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GestureGalleryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
        },
        child: const Icon(Icons.camera_alt),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Enter text or use microphone...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isListening ? _stopListening : _startListening,
                    icon: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                if (_textController.text.isEmpty) return;
                await _processInstructions(_textController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : const Text('Generate Steps'),
            ),
          ),
          if (_matchedImagePath != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Image.asset(
                _matchedImagePath!,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          ],
          if (_steps.isNotEmpty) _buildNavigationControls(),
          const SizedBox(height: 16),
          Expanded(
            child: _steps.isEmpty
                ? Center(
              child: Text(
                _isLoading
                    ? 'Processing...'
                    : 'Enter text and generate steps',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
                : ListView.builder(
              itemCount: _steps.length,
              padding: const EdgeInsets.only(bottom: 16),
              itemBuilder: (context, index) {
                return _buildStepCard(_steps[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _textController.dispose();
    super.dispose();
  }
}

// GeminiService Class (from second code snippet)
class GeminiService {
  static const String apiKey = 'AIzaSyC3Pb91zUk_Co7Gi6qTFA-hplBGYpF75lo'; // Replace with your actual API key
  late final GenerativeModel _model;
  DateTime? _lastRequestTime;
  static const int _minSecondsBetweenRequests = 10; // Minimum seconds between requests

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  }

  Future<String> generateISLInstructions(String text) async {
    try {
      // Check if we need to wait before making another request
      if (_lastRequestTime != null) {
        final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
        if (timeSinceLastRequest.inSeconds < _minSecondsBetweenRequests) {
          final secondsToWait = _minSecondsBetweenRequests - timeSinceLastRequest.inSeconds;
          throw Exception(
            'Please wait $secondsToWait seconds before making another request to avoid API limits.',
          );
        }
      }

      final prompt = '''
Convert the following text to Indian Sign Language (ISL) instructions.
Provide step-by-step hand gestures and movements:

Text: $text

Please provide clear, numbered steps for performing this in ISL. Do not include asterisks or stars in the output.
''';

      final content = [Content.text(prompt)];

      // Update last request time
      _lastRequestTime = DateTime.now();

      final response = await _model.generateContent(content);

      if (response.text == null) {
        throw Exception('Empty response from Gemini API');
      }

      return response.text!;
    } catch (e) {
      if (e.toString().contains('429')) { // HTTP 429 Too Many Requests
        throw Exception(
          'API rate limit reached. Please wait a minute before trying again.',
        );
      } else if (e.toString().contains('quotaExceeded')) {
        throw Exception(
          'Daily API quota exceeded. Please try again tomorrow or upgrade your API key.',
        );
      }
      throw Exception('Failed to generate ISL instructions: $e');
    }
  }

  // Method to check if we can make a request
  bool canMakeRequest() {
    if (_lastRequestTime == null) return true;
    final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
    return timeSinceLastRequest.inSeconds >= _minSecondsBetweenRequests;
  }

  // Method to get remaining wait time in seconds
  int getRemainingWaitTime() {
    if (_lastRequestTime == null) return 0;
    final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
    return _minSecondsBetweenRequests - timeSinceLastRequest.inSeconds;
  }
}