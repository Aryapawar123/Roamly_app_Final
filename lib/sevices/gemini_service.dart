import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY']!;

  static Future<Map<String, dynamic>> generateItinerary({
    required String destination,
    required String startDate,
    required String endDate,
    required int travelers,
    required String budget,
    required String travelStyle,
    required String pace,
    required String startingCity,
    required bool surpriseMe,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey',
    );

    final prompt = '''
You are an expert Indian travel planner.

Create a personalized itinerary:
Destination: $destination
Starting City: $startingCity
Dates: $startDate to $endDate
Travelers: $travelers
Budget: $budget
Style: $travelStyle
Pace: $pace
Surprise: ${surpriseMe ? "Yes" : "No"}

Rules:
- Day-wise plan
- Morning/Afternoon/Evening
- Include food & transport
- Hidden gems if surprise = true
- Output STRICT JSON ONLY

JSON format:
{
  "summary": "",
  "days": [
    {
      "day": 1,
      "activities": [
        {
          "time": "",
          "title": "",
          "type": "",
          "notes": ""
        }
      ]
    }
  ]
}
''';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    final decoded = jsonDecode(response.body);
    final text =
        decoded['candidates'][0]['content']['parts'][0]['text'];

    return jsonDecode(text.replaceAll('```json', '').replaceAll('```', ''));
  }
}
