import 'package:google_generative_ai/google_generative_ai.dart';

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
              'Please wait $secondsToWait seconds before making another request to avoid API limits.'
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
      if (e.toString().contains('429')) {  // HTTP 429 Too Many Requests
        throw Exception(
            'API rate limit reached. Please wait a minute before trying again.'
        );
      } else if (e.toString().contains('quotaExceeded')) {
        throw Exception(
            'Daily API quota exceeded. Please try again tomorrow or upgrade your API key.'
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