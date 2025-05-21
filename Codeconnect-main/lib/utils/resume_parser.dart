import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nitd_code/secret_manager.dart';

class ResumeParser {
  // ✅ Parse resume for Mobile/Desktop using File
  Future<List<String>> parseResume(File resumeFile) async {
    String resumeText = await resumeFile.readAsString();
    return await _generateQuestions(resumeText);
  }

  // ✅ Parse resume for Web using Uint8List
  Future<List<String>> parseWebResume(Uint8List webBytes) async {
    // Convert bytes to text using UTF-8 or other suitable encoding
    String resumeText = utf8.decode(webBytes, allowMalformed: true);
    return await _generateQuestions(resumeText);
  }

  // ✅ Common method to generate AI questions
  Future<List<String>> _generateQuestions(String resumeText) async {
    // ✅ Load the API key from .env
    String? geminiApiKey = SecretsManager().get("GEMINI_API_KEY") ?? dotenv.env['GEMINI_API_KEY'];

    if (geminiApiKey == null || geminiApiKey.isEmpty) {
      throw Exception('API key not found. Please check your .env file.');
    }

    // Gemini API URL with API key from .env
    var url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey');

    // Define prompt for parsing resume and generating questions
    String prompt = '''
Analyze this resume and generate exactly 3 short and relevant questions.

1. Start with a warm and friendly greeting, like "Hi, how are you?" or "Hope you're doing great today!"

2. Ask a technical question based on the candidate's project work. Focus on something specific from one of their listed projects to assess their implementation, decision-making, or problem-solving.

3. Ask another short technical question based on a different project or technical skill mentioned in the resume. Keep it focused and insightful.

Only return the 3 questions in a numbered list. Do not include explanations or additional content.

Resume:
$resumeText
''';


    // Prepare request payload
    var requestBody = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    // Send request to Google Gemini API
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      // Extract generated content (questions)
      List<dynamic> contentParts =
          jsonResponse['candidates'][0]['content']['parts'] as List<dynamic>;
      String generatedText = contentParts[0]['text'];

      // Split the text into a list of questions
      List<String> questions =
          generatedText.split('\n').where((q) => q.trim().isNotEmpty).toList();

      return questions;
    } else {
      throw Exception(
          'Failed to parse resume and generate questions: ${response.body}');
    }
  }
}
