import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SmartItineraryScreen extends StatefulWidget {
  final String tripId;
  const SmartItineraryScreen({super.key, required this.tripId});

  @override
  State<SmartItineraryScreen> createState() => _SmartItineraryScreenState();
}

class _SmartItineraryScreenState extends State<SmartItineraryScreen>
    with SingleTickerProviderStateMixin {
  // Theme Colors
  static const primaryOrange = Color(0xFFFF9F66);
  static const darkOrange = Color(0xFFFF8243);
  static const lightOrange = Color(0xFFFFB88C);
  static const palePeach = Color(0xFFFFF4ED);
  static const accentOrange = Color(0xFFFF7A3D);

  // State
  bool loading = true;
  bool regenerating = false;
  bool optimizing = false;
  bool showMap = true;
  ViewMode viewMode = ViewMode.list;

  String destination = '';
  Map<String, dynamic> preferences = {};
  List<DayItinerary> days = [];
  Map<int, List<String>> dayNotes = {};
  Map<int, List<String>> dayPhotos = {};
  Map<int, DayWeather> dayWeather = {};
  Map<int, double> dayExpenses = {};

  int currentVersion = 1;
  int selectedDay = 0;
  late TabController _tabController;
  
  // API Keys
  late final String geminiApiKey;
  late final String weatherApiKey;
  late final String mapsApiKey;

  // Emergency Info
  EmergencyInfo? emergencyInfo;
  
  // Packing List
  List<PackingItem> packingList = [];
  
  // Trip Readiness
  TripReadiness? tripReadiness;

  // Nearby Places Cache
  Map<int, List<NearbyPlace>> nearbyPlacesCache = {};

  @override
  void initState() {
    super.initState();
    geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    weatherApiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
    mapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    _tabController = TabController(length: 5, vsync: this);
    _initFlow();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =============== INITIALIZATION ===============

  Future<void> _initFlow() async {
    setState(() => loading = true);
    
    try {
      await _loadTripMeta();
      final loaded = await _loadFromCache();
      
      if (!loaded) {
        await _generateAndCache();
      }
      
      // Load additional data in parallel
      await Future.wait([
        _loadDayNotes(),
        _loadDayExpenses(),
        _fetchWeatherForAllDays(),
        _generateEmergencyInfo(),
        _generatePackingList(),
      ]);
      
      await _calculateTripReadiness();
      
    } catch (e) {
      debugPrint('Error in init flow: $e');
      _showSnackBar('Error loading trip: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _loadTripMeta() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .get();

      if (!snap.exists) {
        throw Exception('Trip not found');
      }

      final data = snap.data() ?? {};
      destination = data['destination']?.toString() ?? 'Unknown Destination';
      preferences = Map<String, dynamic>.from(data);
      
      debugPrint('Loaded trip meta: $destination');
    } catch (e) {
      debugPrint('Error loading trip meta: $e');
      rethrow;
    }
  }

  // =============== OFFLINE CACHE ===============

  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('smart_itinerary_${widget.tripId}');
      
      if (raw == null) {
        debugPrint('No cache found');
        return false;
      }

      final decoded = jsonDecode(raw);
      final cachedAt = DateTime.tryParse(decoded['cachedAt'] ?? '');
      
      // Check if cache is older than 24 hours
      if (cachedAt != null && 
          DateTime.now().difference(cachedAt).inHours > 24) {
        debugPrint('Cache expired');
        return false;
      }

      days = (decoded['days'] as List)
          .map((e) => DayItinerary.fromJson(e))
          .toList();
      currentVersion = decoded['version'] ?? 1;
      
      debugPrint('Loaded ${days.length} days from cache (v$currentVersion)');
      return true;
    } catch (e) {
      debugPrint('Error loading cache: $e');
      return false;
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'smart_itinerary_${widget.tripId}',
        jsonEncode({
          'days': days.map((d) => d.toJson()).toList(),
          'preferences': preferences,
          'version': currentVersion,
          'cachedAt': DateTime.now().toIso8601String(),
        }),
      );
      debugPrint('Saved to cache: ${days.length} days (v$currentVersion)');
    } catch (e) {
      debugPrint('Error saving cache: $e');
    }
  }

  // =============== AI GENERATION WITH GEMINI ===============

  Future<void> _generateAndCache() async {
    if (geminiApiKey.isEmpty) {
      _showSnackBar('Gemini API key not configured', isError: true);
      return;
    }

    try {
      debugPrint('Starting itinerary generation with Gemini...');
      
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: geminiApiKey,
      );

      final startDate = DateTime.parse(
        preferences['startDate'] ?? DateTime.now().toIso8601String()
      );
      final endDate = DateTime.parse(
        preferences['endDate'] ?? DateTime.now().add(const Duration(days: 3)).toIso8601String()
      );
      final numDays = endDate.difference(startDate).inDays + 1;

      // Build comprehensive prompt
      final prompt = _buildItineraryPrompt(numDays, startDate);

      debugPrint('Calling Gemini API...');
      
      final res = await model.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.8,
          maxOutputTokens: 8192,
        ),
      );

      if (res.text == null || res.text!.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      debugPrint('Received response from Gemini: ${res.text!.length} chars');

      // Parse JSON response
      final decoded = jsonDecode(res.text!);
      final List rawDays = decoded['days'] ?? [];

      if (rawDays.isEmpty) {
        throw Exception('No days generated in response');
      }

      days = rawDays.map((e) => DayItinerary.fromJson(e)).toList();
      
      debugPrint('Successfully parsed ${days.length} days');

      // Save to cache and Firestore
      await _saveToCache();
      await _saveDaysToFirestore();
      
      _showSnackBar('✨ Generated ${days.length}-day itinerary!');
      
    } catch (e) {
      debugPrint('Error generating itinerary: $e');
      _showSnackBar('Failed to generate itinerary: $e', isError: true);
      rethrow;
    }
  }

  String _buildItineraryPrompt(int numDays, DateTime startDate) {
    final mustVisit = preferences['mustVisitPlaces'] as List? ?? [];
    final avoid = preferences['avoidCategories'] as List? ?? [];
    final activities = preferences['activityPreferences'] as List? ?? [];

    return '''
Generate a detailed ${numDays}-day travel itinerary for $destination in PURE JSON format.

TRIP DETAILS:
- Destination: $destination
- Start Date: ${DateFormat('yyyy-MM-dd').format(startDate)}
- Duration: $numDays days
- Total Budget: ₹${preferences['budget']}
- Number of Travelers: ${preferences['travelers']}
- Travel Style: ${preferences['travelStyle'] ?? 'Cultural'}
- Pace: ${preferences['pace'] ?? 'Moderate'}
- Accommodation Type: ${preferences['accommodationType'] ?? 'Hotel'}
- Transport: ${preferences['transportPreference'] ?? 'Cab'}
- Meal Preference: ${preferences['mealPreference'] ?? 'Vegetarian'}
${mustVisit.isNotEmpty ? '- Must Visit Places: ${mustVisit.join(', ')}' : ''}
${avoid.isNotEmpty ? '- Avoid: ${avoid.join(', ')}' : ''}
${activities.isNotEmpty ? '- Preferred Activities: ${activities.join(', ')}' : ''}

REQUIREMENTS:
1. Create exactly $numDays days of itinerary
2. Each day should have morning (09:00-12:00), afternoon (12:00-17:00), and evening (17:00-21:00) activities
3. Provide realistic GPS coordinates (lat/lng) for each location in $destination
4. Estimate realistic costs per activity in Indian Rupees (₹)
5. Include popular restaurants and cafes for meals
6. Calculate travel time between locations
7. Balance activities based on "${preferences['pace']}" pace
8. Stay within budget of ₹${preferences['budget']} total
9. Include at least one activity from must-visit places each day if provided
10. Respect meal preference: ${preferences['mealPreference']}

IMPORTANT: Return ONLY valid JSON, no markdown formatting or code blocks.

JSON FORMAT:
{
  "days": [
    {
      "day": 1,
      "date": "${DateFormat('yyyy-MM-dd').format(startDate)}",
      "title": "Arrival & City Exploration",
      "morning": [
        {
          "time": "09:00",
          "activity": "Breakfast at Local Cafe",
          "location": "Cafe Name, Area",
          "lat": 0.0,
          "lng": 0.0,
          "duration": 60,
          "cost": 500,
          "category": "food"
        },
        {
          "time": "10:30",
          "activity": "Visit Famous Monument",
          "location": "Monument Name",
          "lat": 0.0,
          "lng": 0.0,
          "duration": 120,
          "cost": 300,
          "category": "sightseeing"
        }
      ],
      "afternoon": [
        {
          "time": "13:00",
          "activity": "Lunch at Restaurant",
          "location": "Restaurant Name",
          "lat": 0.0,
          "lng": 0.0,
          "duration": 90,
          "cost": 800,
          "category": "food"
        }
      ],
      "evening": [
        {
          "time": "18:00",
          "activity": "Sunset at Beach/Park",
          "location": "Location Name",
          "lat": 0.0,
          "lng": 0.0,
          "duration": 120,
          "cost": 0,
          "category": "leisure"
        }
      ],
      "estimatedDayCost": 3500,
      "travelTime": 90,
      "notes": "Pack comfortable walking shoes"
    }
  ]
}

Generate realistic, exciting itinerary now:
''';
  }

  Future<void> _saveDaysToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user logged in, skipping Firestore save');
        return;
      }

      final tripRef = FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId);

      // Save each day
      final batch = FirebaseFirestore.instance.batch();
      
      for (var day in days) {
        final dayRef = tripRef.collection('days').doc('day_${day.day}');
        batch.set(dayRef, day.toJson(), SetOptions(merge: true));
      }

      // Update trip metadata
      batch.update(tripRef, {
        'status': 'GENERATED',
        'generatedAt': FieldValue.serverTimestamp(),
        'dayCount': days.length,
        'currentVersion': currentVersion,
      });

      await batch.commit();
      debugPrint('Saved ${days.length} days to Firestore');
      
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
      // Don't throw - allow offline functionality
    }
  }

  // =============== WEATHER INTEGRATION ===============

  Future<void> _fetchWeatherForAllDays() async {
    if (weatherApiKey.isEmpty) {
      debugPrint('Weather API key not configured');
      return;
    }

    for (var day in days) {
      if (day.date != null) {
        try {
          final weather = await _fetchWeather(day.date!);
          if (weather != null && mounted) {
            setState(() => dayWeather[day.day] = weather);
          }
        } catch (e) {
          debugPrint('Error fetching weather for day ${day.day}: $e');
        }
      }
    }
  }

  Future<DayWeather?> _fetchWeather(DateTime date) async {
    try {
      final coords = _getDestinationCoords();
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?'
        'lat=${coords['lat']}&lon=${coords['lng']}'
        '&appid=$weatherApiKey&units=metric'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['list'] as List;
        
        if (list.isNotEmpty) {
          final forecast = list.first;
          return DayWeather(
            condition: forecast['weather'][0]['main'],
            temp: forecast['main']['temp'].toDouble(),
            humidity: forecast['main']['humidity'],
            windSpeed: forecast['wind']['speed'].toDouble(),
            icon: forecast['weather'][0]['icon'],
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
    }
    return null;
  }

  Map<String, double> _getDestinationCoords() {
    if (days.isNotEmpty && days.first.morning.isNotEmpty) {
      final activity = days.first.morning.first;
      return {'lat': activity.lat, 'lng': activity.lng};
    }
    return {'lat': 0.0, 'lng': 0.0};
  }

  // =============== BUDGET TRACKING ===============

  Future<void> _loadDayExpenses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .collection('expenses')
          .get();

      final Map<int, double> expenses = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final day = data['day'] as int? ?? 0;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        expenses[day] = (expenses[day] ?? 0.0) + amount;
      }

      if (mounted) {
        setState(() => dayExpenses = expenses);
      }
      
      debugPrint('Loaded expenses for ${expenses.length} days');
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    }
  }

  double _getTotalBudget() {
    return days.fold(0.0, (sum, day) => sum + day.estimatedDayCost);
  }

  double _getTotalSpent() {
    return dayExpenses.values.fold(0.0, (sum, amount) => sum + amount);
  }

  double _getBudgetPercentage() {
    final total = _getTotalBudget();
    if (total == 0) return 0.0;
    return (_getTotalSpent() / total).clamp(0.0, 1.0);
  }

  // =============== DAY COMPLETION ===============

  Future<void> _toggleDayCompletion(int day) async {
    try {
      final dayIndex = days.indexWhere((d) => d.day == day);
      if (dayIndex == -1) return;

      final newStatus = !days[dayIndex].completed;
      
      setState(() => days[dayIndex].completed = newStatus);

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .collection('days')
          .doc('day_$day')
          .update({'completed': newStatus});

      // Update trip stats
      final completedCount = days.where((d) => d.completed).length;
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update({
            'stats.completedDays': completedCount,
            'stats.totalDays': days.length,
            'status': completedCount == days.length ? 'COMPLETED' : 
                     completedCount > 0 ? 'IN_PROGRESS' : 'GENERATED',
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      await _saveToCache();
      await _calculateTripReadiness();

      _showSnackBar(
        newStatus ? 'Day ${day} marked complete! 🎉' : 'Day ${day} unmarked',
      );
      
    } catch (e) {
      debugPrint('Error toggling completion: $e');
      _showSnackBar('Failed to update status', isError: true);
    }
  }

  // =============== NOTES MANAGEMENT ===============

  Future<void> _loadDayNotes() async {
    try {
      for (var day in days) {
        final snapshot = await FirebaseFirestore.instance
            .collection('trips')
            .doc(widget.tripId)
            .collection('days')
            .doc('day_${day.day}')
            .collection('notes')
            .orderBy('createdAt', descending: true)
            .get();

        final notes = snapshot.docs
            .map((doc) => doc.data()['text'] as String)
            .toList();
        
        if (mounted) {
          setState(() => dayNotes[day.day] = notes);
        }
      }
      
      debugPrint('Loaded notes for all days');
    } catch (e) {
      debugPrint('Error loading notes: $e');
    }
  }

  Future<void> _addNote(int day, String note) async {
    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .collection('days')
          .doc('day_$day')
          .collection('notes')
          .add({
            'text': note,
            'createdAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        dayNotes[day] = [note, ...(dayNotes[day] ?? [])];
      });

      _showSnackBar('Note added to Day $day');
    } catch (e) {
      debugPrint('Error adding note: $e');
      _showSnackBar('Failed to add note', isError: true);
    }
  }

  // =============== OPTIMIZATION ===============

  Future<void> _optimizeDay(int dayNumber) async {
    if (geminiApiKey.isEmpty) {
      _showSnackBar('Gemini API key not configured', isError: true);
      return;
    }

    setState(() => optimizing = true);

    try {
      final dayIndex = days.indexWhere((d) => d.day == dayNumber);
      if (dayIndex == -1) return;

      final day = days[dayIndex];
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: geminiApiKey,
      );

      final prompt = '''
Optimize this day's itinerary to minimize travel time and improve flow.

Current itinerary for Day ${day.day}:
${jsonEncode(day.toJson())}

Requirements:
1. Reorder activities to minimize total travel distance
2. Group nearby activities together
3. Balance morning/afternoon/evening sections
4. Keep total cost similar to current: ₹${day.estimatedDayCost}
5. Maintain all activities, just reorder them optimally
6. Update coordinates if needed for better routing

Return ONLY valid JSON in the exact same format as input.
''';

      final res = await model.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      if (res.text == null) {
        throw Exception('Empty response from Gemini');
      }

      final optimized = DayItinerary.fromJson(jsonDecode(res.text!));
      
      setState(() {
        days[dayIndex] = optimized;
      });

      await _saveToCache();
      await _saveDaysToFirestore();

      _showSnackBar('Day $dayNumber optimized! ✨');
      
    } catch (e) {
      debugPrint('Error optimizing day: $e');
      _showSnackBar('Failed to optimize: $e', isError: true);
    } finally {
      setState(() => optimizing = false);
    }
  }

  // =============== NEARBY PLACES ===============

  Future<void> _fetchNearbyPlaces(int day) async {
    if (nearbyPlacesCache.containsKey(day)) return;
    if (mapsApiKey.isEmpty) return;

    try {
      final dayData = days.firstWhere((d) => d.day == day);
      if (dayData.morning.isEmpty) return;

      final activity = dayData.morning.first;
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=${activity.lat},${activity.lng}'
        '&radius=1000'
        '&type=restaurant|cafe|hospital|police'
        '&key=$mapsApiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        
        final places = results.take(10).map((p) => NearbyPlace(
          name: p['name'],
          type: (p['types'] as List).first,
          lat: p['geometry']['location']['lat'],
          lng: p['geometry']['location']['lng'],
          rating: (p['rating'] ?? 0.0).toDouble(),
        )).toList();

        setState(() => nearbyPlacesCache[day] = places);
      }
    } catch (e) {
      debugPrint('Error fetching nearby places: $e');
    }
  }

  // =============== EMERGENCY INFO ===============

  Future<void> _generateEmergencyInfo() async {
    if (geminiApiKey.isEmpty) return;

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: geminiApiKey,
      );

      final prompt = '''
Generate emergency contact information for travelers visiting: $destination

Return ONLY valid JSON format:
{
  "police": "local emergency number",
  "ambulance": "ambulance number",
  "fireService": "fire service number",
  "embassy": "Indian embassy number (if applicable)",
  "hospitals": ["Hospital 1 with address", "Hospital 2 with address"],
  "policeStations": ["Station 1 with address", "Station 2 with address"]
}
''';

      final res = await model.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      if (res.text != null) {
        final data = jsonDecode(res.text!);
        setState(() {
          emergencyInfo = EmergencyInfo.fromJson(data);
        });
      }
    } catch (e) {
      debugPrint('Error generating emergency info: $e');
    }
  }

  // =============== PACKING LIST ===============

  Future<void> _generatePackingList() async {
    if (geminiApiKey.isEmpty) return;

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: geminiApiKey,
      );

      final weatherConditions = dayWeather.values
          .map((w) => w.condition)
          .toSet()
          .join(', ');

      final activities = preferences['activityPreferences'] as List? ?? [];

      final prompt = '''
Generate a comprehensive packing list for a trip to $destination.

Trip Details:
- Duration: ${days.length} days
- Expected Weather: $weatherConditions
- Activities: ${activities.join(', ')}
- Travel Style: ${preferences['travelStyle']}
- Accommodation: ${preferences['accommodationType']}

Return ONLY valid JSON:
{
  "items": [
    {"name": "Sunscreen SPF 50", "category": "Essentials", "packed": false},
    {"name": "Comfortable walking shoes", "category": "Clothing", "packed": false},
    {"name": "Camera", "category": "Electronics", "packed": false}
  ]
}

Include at least 20-30 relevant items across categories: Essentials, Clothing, Electronics, Documents, Toiletries, Medications.
''';

      final res = await model.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      if (res.text != null) {
        final data = jsonDecode(res.text!);
        
        // Load saved packing status
        final prefs = await SharedPreferences.getInstance();
        final savedList = prefs.getString('packing_list_${widget.tripId}');
        
        final items = (data['items'] as List)
            .map((item) => PackingItem.fromJson(item))
            .toList();

        // Restore packed status if available
        if (savedList != null) {
          try {
            final saved = jsonDecode(savedList) as List;
            final savedMap = {for (var item in saved) item['name']: item['packed']};
            
            for (var item in items) {
              if (savedMap.containsKey(item.name)) {
                item.packed = savedMap[item.name] ?? false;
              }
            }
          } catch (e) {
            debugPrint('Error restoring packing status: $e');
          }
        }

        setState(() {
          packingList = items;
        });
      }
    } catch (e) {
      debugPrint('Error generating packing list: $e');
    }
  }

  Future<void> _togglePackingItem(int index) async {
    setState(() {
      packingList[index].packed = !packingList[index].packed;
    });
    
    // Save to local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'packing_list_${widget.tripId}',
        jsonEncode(packingList.map((i) => i.toJson()).toList()),
      );
      
      await _calculateTripReadiness();
    } catch (e) {
      debugPrint('Error saving packing list: $e');
    }
  }

  // =============== TRIP READINESS ===============

  Future<void> _calculateTripReadiness() async {
    try {
      final hasItinerary = days.isNotEmpty;
      final hasPackingList = packingList.isNotEmpty;
      final packedPercentage = packingList.isEmpty ? 0.0 :
          packingList.where((i) => i.packed).length / packingList.length;
      final budgetSet = _getTotalBudget() > 0;
      final underBudget = _getTotalSpent() <= _getTotalBudget();

      final score = (
        (hasItinerary ? 0.3 : 0) +
        (hasPackingList ? 0.2 : 0) +
        (packedPercentage * 0.25) +
        (budgetSet ? 0.15 : 0) +
        (underBudget ? 0.1 : 0)
      );

      if (mounted) {
        setState(() {
          tripReadiness = TripReadiness(
            score: score,
            hasItinerary: hasItinerary,
            hasPackingList: hasPackingList,
            packedPercentage: packedPercentage,
            budgetSet: budgetSet,
            underBudget: underBudget,
          );
        });
      }
    } catch (e) {
      debugPrint('Error calculating readiness: $e');
    }
  }

  // =============== SHARING ===============

  Future<void> _shareItinerary() async {
    try {
      final StringBuffer content = StringBuffer();
      content.writeln('🌍 $destination Travel Itinerary\n');
      content.writeln('Generated by TripPlanner Pro\n');
      content.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      content.writeln('📅 Duration: ${days.length} Days');
      content.writeln('💰 Total Budget: ₹${_formatAmount(_getTotalBudget().toInt())}');
      content.writeln('👥 Travelers: ${preferences['travelers']}');
      content.writeln('🎯 Style: ${preferences['travelStyle']}\n');
      content.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
      for (var day in days) {
        content.writeln('\n📍 DAY ${day.day}: ${day.title.toUpperCase()}');
        if (day.date != null) {
          content.writeln('📆 ${DateFormat('EEEE, MMM d, yyyy').format(day.date!)}');
        }
        content.writeln('💵 Estimated Cost: ₹${day.estimatedDayCost.toInt()}');
        content.writeln('');
        
        if (day.morning.isNotEmpty) {
          content.writeln('🌅 MORNING:');
          for (var activity in day.morning) {
            content.writeln('  ⏰ ${activity.time}');
            content.writeln('     ${activity.activity}');
            if (activity.location.isNotEmpty) {
              content.writeln('     📍 ${activity.location}');
            }
            if (activity.cost > 0) {
              content.writeln('     💰 ₹${activity.cost}');
            }
            content.writeln('');
          }
        }
        
        if (day.afternoon.isNotEmpty) {
          content.writeln('☀️ AFTERNOON:');
          for (var activity in day.afternoon) {
            content.writeln('  ⏰ ${activity.time}');
            content.writeln('     ${activity.activity}');
            if (activity.location.isNotEmpty) {
              content.writeln('     📍 ${activity.location}');
            }
            if (activity.cost > 0) {
              content.writeln('     💰 ₹${activity.cost}');
            }
            content.writeln('');
          }
        }
        
        if (day.evening.isNotEmpty) {
          content.writeln('🌙 EVENING:');
          for (var activity in day.evening) {
            content.writeln('  ⏰ ${activity.time}');
            content.writeln('     ${activity.activity}');
            if (activity.location.isNotEmpty) {
              content.writeln('     📍 ${activity.location}');
            }
            if (activity.cost > 0) {
              content.writeln('     💰 ₹${activity.cost}');
            }
            content.writeln('');
          }
        }
        
        if (day.notes.isNotEmpty) {
          content.writeln('📝 Note: ${day.notes}');
        }
        
        content.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      content.writeln('\n\n💡 TRIP TIPS:');
      content.writeln('• Total estimated cost: ₹${_formatAmount(_getTotalBudget().toInt())}');
      content.writeln('• Pack according to weather forecast');
      content.writeln('• Keep emergency numbers handy');
      content.writeln('• Book accommodations in advance\n');
      
      content.writeln('Happy Traveling! 🎒✈️');

      // Save to file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${destination}_itinerary.txt');
      await file.writeAsString(content.toString());

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '$destination ${days.length}-Day Itinerary',
        text: 'Check out my $destination travel plan!',
      );
      
      _showSnackBar('Itinerary shared successfully! 📤');
      
    } catch (e) {
      debugPrint('Error sharing itinerary: $e');
      _showSnackBar('Failed to share itinerary', isError: true);
    }
  }

  // =============== VERSION MANAGEMENT ===============

  Future<void> saveTrip() async {
    try {
      currentVersion++;

      final tripRef = FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId);

      // Save main trip data
      await tripRef.set({
        'destination': destination,
        'preferences': preferences,
        'currentVersion': currentVersion,
        'updatedAt': FieldValue.serverTimestamp(),
        'stats': {
          'totalDays': days.length,
          'completedDays': days.where((d) => d.completed).length,
          'totalBudget': _getTotalBudget(),
          'totalSpent': _getTotalSpent(),
        },
      }, SetOptions(merge: true));

      // Save version snapshot
      await tripRef.collection('versions').doc('v$currentVersion').set({
        'version': currentVersion,
        'itinerary': {
          'days': days.map((d) => d.toJson()).toList(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'snapshot': {
          'destination': destination,
          'totalDays': days.length,
          'totalBudget': _getTotalBudget(),
        },
      });

      await _saveToCache();

      _showSnackBar('Trip saved as version $currentVersion ✅');
      
    } catch (e) {
      debugPrint('Error saving trip: $e');
      _showSnackBar('Failed to save trip', isError: true);
    }
  }

  Future<void> regenerate() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Itinerary?'),
        content: Text(
          'This will create a completely new itinerary. '
          'Your current version will be saved as v$currentVersion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => regenerating = true);

    try {
      // Save current version before regenerating
      await saveTrip();
      
      // Clear current data
      days.clear();
      dayNotes.clear();
      dayExpenses.clear();
      dayWeather.clear();
      
      // Generate new itinerary
      await _generateAndCache();
      
      // Reload supporting data
      await Future.wait([
        _fetchWeatherForAllDays(),
        _generatePackingList(),
        _calculateTripReadiness(),
      ]);
      
      _showSnackBar('New itinerary generated! 🎉');
      
    } catch (e) {
      debugPrint('Error regenerating: $e');
      _showSnackBar('Failed to regenerate', isError: true);
    } finally {
      setState(() => regenerating = false);
    }
  }

  // =============== UI BUILD ===============

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: palePeach,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  color: primaryOrange,
                  strokeWidth: 6,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Creating your perfect itinerary...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This may take a few moments',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palePeach,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHeaderStats()),
          SliverToBoxAdapter(child: _buildBudgetMeter()),
          SliverToBoxAdapter(child: _buildTabBar()),
          _buildTabContent(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // App Bar
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: primaryOrange),
          onPressed: _shareItinerary,
          tooltip: 'Share Itinerary',
        ),
        IconButton(
          icon: regenerating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryOrange,
                  ),
                )
              : const Icon(Icons.refresh, color: primaryOrange),
          onPressed: regenerating ? null : regenerate,
          tooltip: 'Regenerate',
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.black54),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'save',
              child: const Row(
                children: [
                  Icon(Icons.save, size: 20, color: primaryOrange),
                  SizedBox(width: 12),
                  Text('Save Version'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'view_mode',
              child: Row(
                children: [
                  Icon(
                    viewMode == ViewMode.list ? Icons.timeline : Icons.list,
                    size: 20,
                    color: primaryOrange,
                  ),
                  const SizedBox(width: 12),
                  Text(viewMode == ViewMode.list ? 'Timeline View' : 'List View'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'save') {
              saveTrip();
            } else if (value == 'view_mode') {
              setState(() {
                viewMode = viewMode == ViewMode.list
                    ? ViewMode.timeline
                    : ViewMode.list;
              });
            }
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          destination,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, palePeach.withOpacity(0.3)],
            ),
          ),
        ),
      ),
    );
  }

  // Header Stats
  Widget _buildHeaderStats() {
    final completedDays = days.where((d) => d.completed).length;
    final progress = days.isEmpty ? 0.0 : completedDays / days.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryOrange, darkOrange],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.calendar_today, '${days.length}', 'Days'),
              _buildDivider(),
              _buildStatItem(Icons.check_circle, '$completedDays', 'Done'),
              _buildDivider(),
              _buildStatItem(
                Icons.percent,
                '${(progress * 100).toInt()}',
                'Progress',
              ),
            ],
          ),
          if (tripReadiness != null) ...[
            const SizedBox(height: 20),
            _buildReadinessIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildReadinessIndicator() {
    final score = tripReadiness!.score;
    final percentage = (score * 100).toInt();
    
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.verified_user, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Trip Readiness',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: score,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ],
    );
  }

  // Budget Meter
  Widget _buildBudgetMeter() {
    final totalBudget = _getTotalBudget();
    final totalSpent = _getTotalSpent();
    final percentage = _getBudgetPercentage();
    final remaining = totalBudget - totalSpent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Budget Tracker',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: remaining >= 0 ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  remaining >= 0 ? 'On Track' : 'Over Budget',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBudgetDetail(
                'Budget',
                '₹${_formatAmount(totalBudget.toInt())}',
                primaryOrange,
              ),
              _buildBudgetDetail(
                'Spent',
                '₹${_formatAmount(totalSpent.toInt())}',
                Colors.red.shade400,
              ),
              _buildBudgetDetail(
                'Remaining',
                '₹${_formatAmount(remaining.toInt())}',
                Colors.green.shade400,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 12,
              backgroundColor: palePeach,
              valueColor: AlwaysStoppedAnimation(
                percentage > 0.9 ? Colors.red : primaryOrange,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(percentage * 100).toInt()}% of budget used',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetDetail(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Tab Bar
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [primaryOrange, lightOrange]),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        tabs: const [
          Tab(text: 'Itinerary'),
          Tab(text: 'Map'),
          Tab(text: 'Packing'),
          Tab(text: 'Emergency'),
          Tab(text: 'More'),
        ],
      ),
    );
  }

  // Tab Content
  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildItineraryTab(),
          _buildMapTab(),
          _buildPackingTab(),
          _buildEmergencyTab(),
          _buildMoreTab(),
        ],
      ),
    );
  }

  // Itinerary Tab
  Widget _buildItineraryTab() {
    if (days.isEmpty) {
      return _buildEmptyState(
        'No itinerary yet',
        Icons.event_busy,
        'Tap the refresh button to generate one!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      itemBuilder: (context, index) => _buildDayCard(days[index]),
    );
  }

  // Day Card
  Widget _buildDayCard(DayItinerary day) {
    final weather = dayWeather[day.day];
    final spent = dayExpenses[day.day] ?? 0.0;
    final notes = dayNotes[day.day] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: day.completed
            ? Border.all(color: Colors.green, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: day.completed
                ? Colors.green.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: day.completed
                    ? [Colors.green.shade400, Colors.green.shade600]
                    : [lightOrange, primaryOrange],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (day.date != null)
                        Text(
                          DateFormat('MMM d, yyyy').format(day.date!),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      if (weather != null)
                        Row(
                          children: [
                            Icon(
                              _getWeatherIcon(weather.condition),
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${weather.temp.toInt()}°C • ${weather.condition}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    day.completed ? Icons.check_circle : Icons.circle_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => _toggleDayCompletion(day.day),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'optimize',
                      child: Row(
                        children: [
                          Icon(Icons.auto_fix_high, size: 20),
                          SizedBox(width: 12),
                          Text('Optimize Day'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'note',
                      child: Row(
                        children: [
                          Icon(Icons.note_add, size: 20),
                          SizedBox(width: 12),
                          Text('Add Note'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'nearby',
                      child: Row(
                        children: [
                          Icon(Icons.place, size: 20),
                          SizedBox(width: 12),
                          Text('Nearby Places'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'optimize') {
                      _optimizeDay(day.day);
                    } else if (value == 'note') {
                      _showAddNoteDialog(day.day);
                    } else if (value == 'nearby') {
                      _showNearbyPlaces(day.day);
                    }
                  },
                ),
              ],
            ),
          ),

          // Budget Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCostChip(
                      'Estimated',
                      day.estimatedDayCost.toInt(),
                      primaryOrange,
                    ),
                    _buildCostChip(
                      'Spent',
                      spent.toInt(),
                      spent > day.estimatedDayCost ? Colors.red : Colors.green,
                    ),
                  ],
                ),

                // Activities
                const SizedBox(height: 16),
                if (day.morning.isNotEmpty)
                  _buildTimeSection('Morning', day.morning, Icons.wb_sunny_outlined),
                if (day.afternoon.isNotEmpty)
                  _buildTimeSection('Afternoon', day.afternoon, Icons.wb_sunny),
                if (day.evening.isNotEmpty)
                  _buildTimeSection('Evening', day.evening, Icons.nightlight_outlined),

                // Notes
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNotesSection(notes),
                ],

                // Travel Time
                if (day.travelTime > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.directions_car, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Total travel time: ${day.travelTime} mins',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostChip(String label, int amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${_formatAmount(amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection(String time, List<Activity> activities, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palePeach,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: primaryOrange),
              const SizedBox(width: 8),
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...activities.map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: primaryOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${activity.time} - ${activity.activity}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (activity.location.isNotEmpty)
                          Text(
                            '📍 ${activity.location}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        Row(
                          children: [
                            if (activity.duration > 0)
                              Text(
                                '⏱️ ${activity.duration} mins',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            if (activity.cost > 0) ...[
                              const SizedBox(width: 12),
                              Text(
                                '₹${activity.cost}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: primaryOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNotesSection(List<String> notes) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.note, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...notes.map((note) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $note',
                  style: const TextStyle(fontSize: 12),
                ),
              )),
        ],
      ),
    );
  }

  // Map Tab
  Widget _buildMapTab() {
    final markers = days
        .expand((day) => [
              ...day.morning,
              ...day.afternoon,
              ...day.evening,
            ])
        .where((a) => a.lat != 0 && a.lng != 0)
        .map((a) => Marker(
              markerId: MarkerId(a.activity),
              position: LatLng(a.lat, a.lng),
              infoWindow: InfoWindow(
                title: a.activity,
                snippet: '₹${a.cost}',
              ),
            ))
        .toSet();

    if (markers.isEmpty) {
      return _buildEmptyState(
        'No locations yet',
        Icons.map_outlined,
        'Activities will appear on the map once generated',
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: markers.first.position,
        zoom: 12,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

  // Packing Tab
  Widget _buildPackingTab() {
    if (packingList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.luggage, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Generating packing list...'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generatePackingList,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = <String, List<PackingItem>>{};
    for (var item in packingList) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final packed = packingList.where((i) => i.packed).length;
    final total = packingList.length;
    final percentage = total > 0 ? packed / total : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryOrange, darkOrange],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Packing Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$packed/$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...entry.value.asMap().entries.map((itemEntry) {
                final index = packingList.indexOf(itemEntry.value);
                final item = itemEntry.value;
                return CheckboxListTile(
                  value: item.packed,
                  onChanged: (value) => _togglePackingItem(index),
                  title: Text(item.name),
                  activeColor: primaryOrange,
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: item.packed ? palePeach : null,
                );
              }),
              const SizedBox(height: 12),
            ],
          );
        }),
      ],
    );
  }

  // Emergency Tab
  Widget _buildEmergencyTab() {
    if (emergencyInfo == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_hospital, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Loading emergency information...'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateEmergencyInfo,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEmergencyCard(
          'Emergency Numbers',
          Icons.phone_in_talk,
          Colors.red,
          [
            'Police: ${emergencyInfo!.police}',
            'Ambulance: ${emergencyInfo!.ambulance}',
            'Fire Service: ${emergencyInfo!.fireService}',
            if (emergencyInfo!.embassy.isNotEmpty)
              'Embassy: ${emergencyInfo!.embassy}',
          ],
        ),
        const SizedBox(height: 16),
        _buildEmergencyCard(
          'Hospitals',
          Icons.local_hospital,
          Colors.green,
          emergencyInfo!.hospitals,
        ),
        const SizedBox(height: 16),
        _buildEmergencyCard(
          'Police Stations',
          Icons.local_police,
          Colors.blue,
          emergencyInfo!.policeStations,
        ),
      ],
    );
  }

  Widget _buildEmergencyCard(
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: color),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // More Tab
  Widget _buildMoreTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMoreOption(
          'Version History',
          Icons.history,
          () => _showSnackBar('Version $currentVersion'),
        ),
        _buildMoreOption(
          'Export as PDF',
          Icons.picture_as_pdf,
          () => _showSnackBar('Coming soon!'),
        ),
        _buildMoreOption(
          'Offline Access',
          Icons.offline_bolt,
          () => _showSnackBar('Already enabled! Itinerary cached locally.'),
        ),
        _buildMoreOption(
          'Collaborative Editing',
          Icons.people,
          () => _showSnackBar('Coming soon!'),
        ),
      ],
    );
  }

  Widget _buildMoreOption(String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: primaryOrange),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // FAB
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _shareItinerary,
      backgroundColor: primaryOrange,
      icon: const Icon(Icons.share, color: Colors.white),
      label: const Text(
        'Share',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Dialogs
  Future<void> _showAddNoteDialog(int day) async {
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Note for Day $day'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your note...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _addNote(day, controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNearbyPlaces(int day) async {
    await _fetchNearbyPlaces(day);
    
    final places = nearbyPlacesCache[day] ?? [];
    
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nearby Places - Day $day',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (places.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No nearby places found'),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return ListTile(
                      leading: Icon(
                        _getPlaceIcon(place.type),
                        color: primaryOrange,
                      ),
                      title: Text(place.name),
                      subtitle: Text('${place.rating} ⭐'),
                      dense: true,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helpers
  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny;
      case 'cloudy':
      case 'clouds':
        return Icons.cloud;
      case 'rain':
      case 'rainy':
        return Icons.water_drop;
      default:
        return Icons.wb_cloudy;
    }
  }

  IconData _getPlaceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.local_cafe;
      case 'hospital':
        return Icons.local_hospital;
      case 'police':
        return Icons.local_police;
      default:
        return Icons.place;
    }
  }

  Widget _buildEmptyState(String title, IconData icon, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palePeach,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: lightOrange),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toString();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : primaryOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }
}

// =============== DATA MODELS ===============

enum ViewMode { list, timeline }

class DayItinerary {
  final int day;
  final DateTime? date;
  final String title;
  final List<Activity> morning;
  final List<Activity> afternoon;
  final List<Activity> evening;
  final double estimatedDayCost;
  final int travelTime;
  bool completed;
  final String notes;

  DayItinerary({
    required this.day,
    this.date,
    required this.title,
    required this.morning,
    required this.afternoon,
    required this.evening,
    required this.estimatedDayCost,
    this.travelTime = 0,
    this.completed = false,
    this.notes = '',
  });

  factory DayItinerary.fromJson(Map<String, dynamic> json) {
    return DayItinerary(
      day: json['day'] ?? 0,
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      title: json['title'] ?? '',
      morning: (json['morning'] as List?)
              ?.map((e) => Activity.fromJson(e))
              .toList() ??
          [],
      afternoon: (json['afternoon'] as List?)
              ?.map((e) => Activity.fromJson(e))
              .toList() ??
          [],
      evening: (json['evening'] as List?)
              ?.map((e) => Activity.fromJson(e))
              .toList() ??
          [],
      estimatedDayCost: (json['estimatedDayCost'] ?? 0).toDouble(),
      travelTime: json['travelTime'] ?? 0,
      completed: json['completed'] ?? false,
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'date': date?.toIso8601String(),
      'title': title,
      'morning': morning.map((a) => a.toJson()).toList(),
      'afternoon': afternoon.map((a) => a.toJson()).toList(),
      'evening': evening.map((a) => a.toJson()).toList(),
      'estimatedDayCost': estimatedDayCost,
      'travelTime': travelTime,
      'completed': completed,
      'notes': notes,
    };
  }
}

class Activity {
  final String time;
  final String activity;
  final String location;
  final double lat;
  final double lng;
  final int duration;
  final int cost;
  final String category;

  Activity({
    required this.time,
    required this.activity,
    required this.location,
    required this.lat,
    required this.lng,
    required this.duration,
    required this.cost,
    required this.category,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      time: json['time'] ?? '',
      activity: json['activity'] ?? '',
      location: json['location'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      cost: json['cost'] ?? 0,
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'activity': activity,
      'location': location,
      'lat': lat,
      'lng': lng,
      'duration': duration,
      'cost': cost,
      'category': category,
    };
  }
}

class DayWeather {
  final String condition;
  final double temp;
  final int humidity;
  final double windSpeed;
  final String icon;

  DayWeather({
    required this.condition,
    required this.temp,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
  });
}

class PackingItem {
  final String name;
  final String category;
  bool packed;

  PackingItem({
    required this.name,
    required this.category,
    this.packed = false,
  });

  factory PackingItem.fromJson(Map<String, dynamic> json) {
    return PackingItem(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      packed: json['packed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'packed': packed,
    };
  }
}

class EmergencyInfo {
  final String police;
  final String ambulance;
  final String fireService;
  final String embassy;
  final List<String> hospitals;
  final List<String> policeStations;

  EmergencyInfo({
    required this.police,
    required this.ambulance,
    required this.fireService,
    required this.embassy,
    required this.hospitals,
    required this.policeStations,
  });

  factory EmergencyInfo.fromJson(Map<String, dynamic> json) {
    return EmergencyInfo(
      police: json['police'] ?? '',
      ambulance: json['ambulance'] ?? '',
      fireService: json['fireService'] ?? '',
      embassy: json['embassy'] ?? '',
      hospitals: List<String>.from(json['hospitals'] ?? []),
      policeStations: List<String>.from(json['policeStations'] ?? []),
    );
  }
}

class NearbyPlace {
  final String name;
  final String type;
  final double lat;
  final double lng;
  final double rating;

  NearbyPlace({
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.rating,
  });
}

class TripReadiness {
  final double score;
  final bool hasItinerary;
  final bool hasPackingList;
  final double packedPercentage;
  final bool budgetSet;
  final bool underBudget;

  TripReadiness({
    required this.score,
    required this.hasItinerary,
    required this.hasPackingList,
    required this.packedPercentage,
    required this.budgetSet,
    required this.underBudget,
  });
}