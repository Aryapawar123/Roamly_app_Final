import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmartItineraryScreen extends StatefulWidget {
  final String tripId;
  const SmartItineraryScreen({super.key, required this.tripId});

  @override
  State<SmartItineraryScreen> createState() => _SmartItineraryScreenState();
}

class _SmartItineraryScreenState extends State<SmartItineraryScreen> {
  bool loading = true;
  bool regenerating = false;
  bool showMap = true;

  String destination = '';
  Map<String, dynamic> preferences = {};
  List<Map<String, dynamic>> days = [];

  int currentVersion = 1;
  late final String apiKey;

  @override
  void initState() {
    super.initState();
    apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _initFlow();
  }

  // ---------------- INIT FLOW ----------------

  Future<void> _initFlow() async {
    await _loadTripMeta();
    final loaded = await _loadFromCache();
    if (!loaded) {
      await _generateAndCache();
    }
    setState(() => loading = false);
  }

  Future<void> _loadTripMeta() async {
    final snap = await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .get();

    final data = snap.data() ?? {};
    destination = data['destination']?.toString() ?? '';
    preferences = Map<String, dynamic>.from(data);
  }

  // ---------------- OFFLINE CACHE ----------------

  Future<bool> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('smart_itinerary_${widget.tripId}');
    if (raw == null) return false;

    final decoded = jsonDecode(raw);
    days = List<Map<String, dynamic>>.from(decoded['days']);
    currentVersion = decoded['version'] ?? 1;
    return true;
  }

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'smart_itinerary_${widget.tripId}',
      jsonEncode({
        'days': days,
        'preferences': preferences,
        'version': currentVersion,
      }),
    );
  }

  // ---------------- AI GENERATION ----------------

  Future<void> _generateAndCache() async {
    if (apiKey.isEmpty) return;

    final model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
    );

    final prompt = '''
Generate a FULL detailed travel itinerary in PURE JSON.

Destination: $destination
Budget: ${preferences['budget']}
Travel Style: ${preferences['travelStyle']}
Pace: ${preferences['pace']}

Return format:
{
 "days":[
   {
     "day":1,
     "title":"Title",
     "activities":["Activity"],
     "lat":12.97,
     "lng":77.59,
     "estimatedCost":1200
   }
 ]
}
''';

    final res = await model.generateContent(
      [Content.text(prompt)],
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    final decoded = jsonDecode(res.text ?? '{}');
    final List rawDays = decoded['days'] ?? [];

    days = rawDays.map<Map<String, dynamic>>((e) {
      return {
        'day': e['day'] ?? 0,
        'title': e['title']?.toString() ?? 'Day Plan',
        'activities': List<String>.from(e['activities'] ?? []),
        'lat': (e['lat'] ?? 0).toDouble(),
        'lng': (e['lng'] ?? 0).toDouble(),
        'estimatedCost': e['estimatedCost'] ?? 0,
      };
    }).toList();

    await _saveToCache();
  }

  // ---------------- SAVE VERSION ----------------

  Future<void> saveTrip() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    currentVersion++;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savedTrips')
        .doc(widget.tripId);

    await ref.set({
      'destination': destination,
      'preferences': preferences,
      'currentVersion': currentVersion,
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'NOT_STARTED',
    }, SetOptions(merge: true));

    await ref.collection('versions').doc('v$currentVersion').set({
      'itinerary': {'days': days},
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Trip saved')));
  }

  // ---------------- REGENERATE ----------------

  Future<void> regenerate() async {
    setState(() => regenerating = true);
    await _generateAndCache();
    setState(() => regenerating = false);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Itinerary'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: regenerate),
          IconButton(icon: const Icon(Icons.bookmark), onPressed: saveTrip),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(destination,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Version $currentVersion • NOT STARTED'),
          const SizedBox(height: 16),

          ...days.map(_dayCard),

          const SizedBox(height: 16),
          _mapView(),
        ],
      ),
    );
  }

  Widget _dayCard(Map<String, dynamic> day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Day ${day['day']} • ${day['title']}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List<String>.from(day['activities'])
                .map((e) => Text('• $e')),
            const SizedBox(height: 6),
            Text('₹${day['estimatedCost']}'),
          ],
        ),
      ),
    );
  }

  Widget _mapView() {
    final markers = days
        .where((d) => d['lat'] != 0 && d['lng'] != 0)
        .map(
          (d) => Marker(
            markerId: MarkerId('day${d['day']}'),
            position: LatLng(d['lat'], d['lng']),
            infoWindow: InfoWindow(title: d['title']),
          ),
        )
        .toSet();

    if (markers.isEmpty) return const SizedBox();

    return SizedBox(
      height: 300,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: markers.first.position,
          zoom: 11,
        ),
        markers: markers,
      ),
    );
  }
}