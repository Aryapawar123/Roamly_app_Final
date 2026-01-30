import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SmartItineraryScreen extends StatefulWidget {
  final String tripId;
  const SmartItineraryScreen({super.key, required this.tripId});

  @override
  State<SmartItineraryScreen> createState() => _SmartItineraryScreenState();
}

class _SmartItineraryScreenState extends State<SmartItineraryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _days = [];
  String? _error;
  String? _tripStatus;

  late final String _geminiApiKey;

  @override
  void initState() {
    super.initState();
    _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    try {
      final tripSnap =
          await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).get();
      if (!tripSnap.exists) throw Exception("Trip not found");

      final trip = tripSnap.data()!;
      _tripStatus = trip['status'] ?? 'UPCOMING';

      if (trip['itinerary'] != null) {
        final days = List<Map<String, dynamic>>.from(trip['itinerary']['days']);
        setState(() {
          _days = days;
          _loading = false;
        });
      } else {
        await _generateItinerary(trip);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchVerifiedPlaces(String destination) async {
    final snap = await FirebaseFirestore.instance
        .collection('${destination.toLowerCase()}_places')
        .where('verified', isEqualTo: true)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      return {
        'name': data['name'],
        'category': data['category'],
        'cost': data['cost'],
        'timeNeeded': data['timeNeeded'],
        'coordinates': data['coordinates'],
      };
    }).toList();
  }

  Future<void> _generateItinerary(Map<String, dynamic> trip) async {
    if (_geminiApiKey.isEmpty) {
      setState(() {
        _error = 'Gemini API key missing';
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final verifiedPlaces = await _fetchVerifiedPlaces(trip['destination']);

      final model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: _geminiApiKey,
      );

      final prompt = _buildPrompt(trip, verifiedPlaces);

      final response = await model.generateContent([Content.text(prompt)]);

      final text = response.text ?? '';
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) throw Exception("Invalid Gemini response");

      final jsonString = text.substring(jsonStart, jsonEnd + 1);
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      final days = List<Map<String, dynamic>>.from(decoded['days']);

      // Save to Firestore
      await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).update({
        'itinerary': decoded,
        'status': 'UPCOMING',
        'generatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _days = days;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _buildPrompt(Map<String, dynamic> trip, List<Map<String, dynamic>> places) {
    final placesJson = jsonEncode(places);
    return '''
You are a professional travel AI.

Create a fully detailed, day-wise itinerary for a trip.

Trip Details:
Destination: ${trip['destination']}
Start: ${trip['startDate']}
End: ${trip['endDate']}
Travelers: ${trip['travelers']}
Budget: ${trip['budget']}
Travel Style: ${trip['travelStyle']}
Pace: ${trip['pace']}
Starting City: ${trip['startingCity']}
Accommodation: ${trip['accommodationType']}
Meal: ${trip['mealPreference']}
Transport: ${trip['transportPreference']}

Use these verified places ONLY:
$placesJson

Requirements:
- Suggest morning, afternoon, evening activities
- Include hotels/resorts per night with price & location
- Include meal/restaurant suggestions per day
- Include estimated cost & time for each activity
- Include tips, narrative, and personalization
- Respect budget and user preferences
- Respond with PURE JSON ONLY
- Output first character must be {

JSON Format:
{
"days": [
  {
    "day": 1,
    "title": "Short title",
    "morning": ["Activity 1"],
    "afternoon": ["Activity 1"],
    "evening": ["Activity 1"],
    "hotels": ["Hotel 1 - ₹xxxx"],
    "restaurants": ["Restaurant 1 - Veg/Non-Veg/Vegan"],
    "tips": ["Helpful tip"]
  }
]
}
''';
  }

  Future<void> _regenerateDay(int dayIndex) async {
    final tripSnap =
        await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).get();
    final trip = tripSnap.data()!;
    await _generateItinerary(trip);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Itinerary'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : _itineraryView(),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadTrip();
                },
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      );

  Widget _itineraryView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _days.length,
      itemBuilder: (context, index) {
        final day = _days[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Day ${day['day']} • ${day['title']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.deepOrange),
                    onPressed: () => _regenerateDay(index),
                    tooltip: 'Regenerate Day',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _section('🌅 Morning', day['morning']),
              _section('☀️ Afternoon', day['afternoon']),
              _section('🌙 Evening', day['evening']),
              _section('🏨 Hotels', day['hotels']),
              _section('🍴 Restaurants', day['restaurants']),
              _section('💡 Tips', day['tips']),
            ]),
          ),
        );
      },
    );
  }

  Widget _section(String title, List<dynamic>? items) {
    if (items == null || items.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        ...items.map((e) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text('• $e'),
            )),
      ],
    );
  }
}
