import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'smart_itinerary_screen.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  // Controllers
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _mustVisitController = TextEditingController();

  // Trip fields
  DateTime? _startDate;
  DateTime? _endDate;
  int _travelers = 2;
  double _budget = 50000;

  // Preferences
  String _travelStyle = 'Cultural';
  String _selectedPace = 'Moderate';
  String _startingCity = 'Mumbai';
  bool _surpriseMe = false;

  // Enhanced options
  String _accommodationType = 'Hotel';
  String _mealPreference = 'Vegetarian';
  String _transportPreference = 'Cab';
  String _tripType = 'Solo';
  String _travelCompanion = 'Solo-Friendly';
  String _seasonPreference = 'Any';
  String _activityIntensity = 'Medium';

  // Must-visit places & avoid categories
  List<String> _mustVisitPlaces = [];
  List<String> _avoidCategories = [];

  // Activity preferences
  List<String> _activityPreferences = [];

  // Google Maps API Key
  late final String _googleMapsApiKey;

  // Selected destination Place ID (for must-visit place restriction)
  String? _destinationPlaceId;

  // Dropdown options
  final List<String> travelStyles = [
    'Cultural','Adventure','Relaxation','Romantic','Eco-tourism','Luxury','Backpacking','Foodie','Wellness'
  ];
  final List<String> paceOptions = ['Relaxed','Moderate','Fast','Custom'];
  final List<String> accommodationOptions = ['Hotel','Hostel','Guest House','Resort','Airbnb','Homestay','Boutique Hotel'];
  final List<String> transportOptions = ['Cab','Public Transport','Self-drive','Bike','Train','Flight'];
  final List<String> mealOptions = ['Vegetarian','Non-Vegetarian','Vegan','Gluten-Free','Keto','Halal','Dairy-Free','Pescatarian'];
  final List<String> tripTypes = ['Solo','Couple','Friends','Family','Group'];
  final List<String> travelCompanions = ['Solo-Friendly','Kid-Friendly','Pet-Friendly','Group-Friendly'];
  final List<String> seasonOptions = ['Any','Avoid Rainy','Avoid Summer','Avoid Winter'];
  final List<String> activityIntensityOptions = ['Low','Medium','High'];
  final List<String> activityOptions = [
    'Hiking','Museum','Shopping','Nightlife','Local Cuisine','Historical Tours','Wildlife','Beaches','Water Sports','Meditation/Wellness','Festivals/Events'
  ];
  final List<String> avoidCategoriesOptions = [
    'Beaches','Religious Sites','Crowded Areas','Adventure Activities','Nightlife','High Altitude','Animal Interactions'
  ];

  @override
  void initState() {
    super.initState();
    _googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _mustVisitController.dispose();
    super.dispose();
  }

  // Validate input
  bool _validateInput() {
    if (_destinationController.text.isEmpty) return false;
    if (_startDate == null || _endDate == null) return false;
    final duration = _endDate!.difference(_startDate!).inDays + 1;
    if (duration < 1 || duration > 21) return false;
    if (_travelers < 1 || _travelers > 10) return false;
    if (_budget < 1000 || _budget > 1000000) return false;
    return true;
  }

  // Preprocess trip data
  Map<String, dynamic> _preprocessTripInput() {
    final tripDurationDays = _endDate!.difference(_startDate!).inDays + 1;
    final avgBudgetPerDay = _budget / _travelers / tripDurationDays;
    final startingCity = _surpriseMe ? 'Auto-Suggested City' : _startingCity;

    return {
      'destination': _destinationController.text,
      'destinationPlaceId': _destinationPlaceId,
      'startDate': _startDate!.toIso8601String(),
      'endDate': _endDate!.toIso8601String(),
      'travelers': _travelers,
      'budget': _budget,
      'avgBudgetPerDay': avgBudgetPerDay,
      'travelStyle': _travelStyle,
      'pace': _selectedPace,
      'startingCity': startingCity,
      'surpriseMe': _surpriseMe,
      'accommodationType': _accommodationType,
      'mealPreference': _mealPreference,
      'transportPreference': _transportPreference,
      'mustVisitPlaces': _mustVisitPlaces,
      'avoidCategories': _avoidCategories,
      'activityPreferences': _activityPreferences,
      'tripType': _tripType,
      'travelCompanion': _travelCompanion,
      'seasonPreference': _seasonPreference,
      'activityIntensity': _activityIntensity,
      'status': 'PENDING',
      'createdAt': DateTime.now().toIso8601String(),
      'googleMapsApiKey': _googleMapsApiKey,
    };
  }

  Future<void> _saveTrip() async {
    if (!_validateInput()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly!')),
      );
      return;
    }

    final tripData = _preprocessTripInput();
    final tripDoc = FirebaseFirestore.instance.collection('trips').doc();

    await tripDoc.set({
      'userId': 'uid_123', // replace with auth UID
      ...tripData,
    });

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SmartItineraryScreen(tripId: tripDoc.id)),
    );
  }

  // Date picker with restriction
  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? _startDate ?? now : _endDate ?? now.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 21)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) _endDate = _startDate!.add(const Duration(days: 1));
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Fetch filtered destination suggestions (only cities/regions)
  Future<List<Map<String,String>>> fetchDestinationSuggestions(String input) async {
    if (input.isEmpty) return [];
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=(regions)&key=$_googleMapsApiKey'
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final predictions = data['predictions'] as List<dynamic>;
      return predictions.map((p) => {
        'description': p['description'] as String,
        'place_id': p['place_id'] as String,
      }).toList();
    }
    return [];
  }

  // Fetch must-visit places restricted to destination
  Future<List<String>> fetchMustVisitPlaces(String input) async {
    if (input.isEmpty || _destinationPlaceId == null) return [];
    // First, get lat/lng of destination
    final detailsUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$_destinationPlaceId&fields=geometry&key=$_googleMapsApiKey'
    );
    final detailsRes = await http.get(detailsUrl);
    if (detailsRes.statusCode != 200) return [];
    final detailsData = json.decode(detailsRes.body);
    final location = detailsData['result']['geometry']['location'];
    final lat = location['lat'];
    final lng = location['lng'];

    // Autocomplete nearby attractions
    final nearbyUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=50000&type=tourist_attraction&keyword=$input&key=$_googleMapsApiKey'
    );
    final nearbyRes = await http.get(nearbyUrl);
    if (nearbyRes.statusCode != 200) return [];
    final nearbyData = json.decode(nearbyRes.body);
    final results = nearbyData['results'] as List<dynamic>;
    return results.map((r) => r['name'].toString()).toList();
  }

  Widget _buildChips(List<String> items, void Function(String) onRemove) {
    return Wrap(
      spacing: 8,
      children: items.map((e) => Chip(label: Text(e), onDeleted: () => onRemove(e), backgroundColor: Colors.orange.shade100)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Trip'), backgroundColor: Colors.deepOrange),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Destination Autocomplete
          Autocomplete<Map<String,String>>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              return await fetchDestinationSuggestions(textEditingValue.text);
            },
            displayStringForOption: (option) => option['description']!,
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              _destinationController.text = controller.text;
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  border: OutlineInputBorder(),
                ),
              );
            },
            onSelected: (selection) {
              if (_destinationController.text != selection['description']) {
                // Reset must-visit places when destination changes
                _mustVisitPlaces.clear();
              }
              _destinationController.text = selection['description']!;
              _destinationPlaceId = selection['place_id'];
            },
          ),
          const SizedBox(height: 12),

          // Dates
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _pickDate(isStart: true),
                  child: Text(_startDate == null ? 'Start Date' : _startDate!.toLocal().toString().split(' ')[0]),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _pickDate(isStart: false),
                  child: Text(_endDate == null ? 'End Date' : _endDate!.toLocal().toString().split(' ')[0]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Travelers
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Number of Travelers', border: OutlineInputBorder()),
            onChanged: (v) => _travelers = int.tryParse(v) ?? 1,
          ),
          const SizedBox(height: 12),

          // Budget
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Budget (₹)', border: OutlineInputBorder()),
            onChanged: (v) => _budget = double.tryParse(v) ?? 50000,
          ),
          const SizedBox(height: 12),

          // Preferences Dropdowns
          DropdownButtonFormField(
            value: _travelStyle,
            items: travelStyles.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _travelStyle = v!),
            decoration: const InputDecoration(labelText: 'Travel Style', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField(
            value: _selectedPace,
            items: paceOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _selectedPace = v!),
            decoration: const InputDecoration(labelText: 'Pace', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),

          // Accommodation
          DropdownButtonFormField(
            value: _accommodationType,
            items: accommodationOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _accommodationType = v!),
            decoration: const InputDecoration(labelText: 'Accommodation', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),

          // Meal
          DropdownButtonFormField(
            value: _mealPreference,
            items: mealOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _mealPreference = v!),
            decoration: const InputDecoration(labelText: 'Meal Preference', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),

          // Transport
          DropdownButtonFormField(
            value: _transportPreference,
            items: transportOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _transportPreference = v!),
            decoration: const InputDecoration(labelText: 'Transport Preference', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),

          // Trip Type & Companion
          DropdownButtonFormField(
            value: _tripType,
            items: tripTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _tripType = v!),
            decoration: const InputDecoration(labelText: 'Trip Type', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: _travelCompanion,
            items: travelCompanions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _travelCompanion = v!),
            decoration: const InputDecoration(labelText: 'Travel Companion', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),

          // Season Preference
          DropdownButtonFormField(
            value: _seasonPreference,
            items: seasonOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _seasonPreference = v!),
            decoration: const InputDecoration(labelText: 'Season Preference', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),

          // Activity Intensity
          DropdownButtonFormField(
            value: _activityIntensity,
            items: activityIntensityOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _activityIntensity = v!),
            decoration: const InputDecoration(labelText: 'Activity Intensity', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),

          // Activity Preferences Multi-Select
          const Text('Activity Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
          _buildChips(_activityPreferences, (e) => setState(() => _activityPreferences.remove(e))),
          DropdownButtonFormField(
            hint: const Text('Add Activity'),
            items: activityOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) {
              if (v != null && !_activityPreferences.contains(v) && !_avoidCategories.contains(v)) {
                setState(() => _activityPreferences.add(v));
              } else if (_avoidCategories.contains(v)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$v conflicts with avoid categories'))
                );
              }
            },
          ),
          const SizedBox(height: 12),

          // Avoid Categories Multi-Select
          const Text('Avoid Categories', style: TextStyle(fontWeight: FontWeight.bold)),
          _buildChips(_avoidCategories, (e) => setState(() => _avoidCategories.remove(e))),
          DropdownButtonFormField(
            hint: const Text('Add Category to Avoid'),
            items: avoidCategoriesOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) {
              if (v != null && !_avoidCategories.contains(v)) setState(() => _avoidCategories.add(v));
            },
          ),
          const SizedBox(height: 12),

          // Must-Visit Places
          const Text('Must-Visit Places', style: TextStyle(fontWeight: FontWeight.bold)),
          _buildChips(_mustVisitPlaces, (e) => setState(() => _mustVisitPlaces.remove(e))),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              return await fetchMustVisitPlaces(textEditingValue.text);
            },
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              _mustVisitController.text = controller.text;
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(labelText: 'Add Must-Visit Place', border: OutlineInputBorder()),
                onSubmitted: (value) {
                  if (value.isNotEmpty && !_mustVisitPlaces.contains(value)) {
                    setState(() => _mustVisitPlaces.add(value));
                    controller.clear();
                  }
                },
              );
            },
            onSelected: (selection) {
              if (!_mustVisitPlaces.contains(selection)) setState(() => _mustVisitPlaces.add(selection));
            },
          ),
          const SizedBox(height: 16),

          // Surprise Me
          CheckboxListTile(
            title: const Text('Surprise Me (Auto-select starting city)'),
            value: _surpriseMe,
            onChanged: (v) => setState(() => _surpriseMe = v!),
          ),
          const SizedBox(height: 24),

          // Generate Itinerary Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _validateInput() ? _saveTrip : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              child: const Text('Generate Smart Itinerary', style: TextStyle(fontSize: 18)),
            ),
          ),
        ]),
      ),
    );
  }
}
