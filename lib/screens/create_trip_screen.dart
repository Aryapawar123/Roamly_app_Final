import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'smart_itinerary_screen.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  // Controllers
  final TextEditingController _destinationController = TextEditingController();

  // Basic fields
  DateTime? _startDate;
  DateTime? _endDate;
  int _travelers = 2;
  double _budget = 50000;

  // Preferences
  String _travelStyle = 'Cultural';
  String _selectedPace = 'Balanced';
  String _startingCity = 'Mumbai';
  bool _surpriseMe = false;

  // Enhanced options
  String _accommodationType = 'Hotel';
  String _mealPreference = 'Vegetarian';
  String _transportPreference = 'Cab';

  // Google Maps API Key
  late final String _googleMapsApiKey;

  @override
  void initState() {
    super.initState();
    // Load API key from .env
    _googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  bool _validateInput() {
    if (_destinationController.text.isEmpty) return false;
    if (_startDate == null || _endDate == null) return false;
    if (_startDate!.isAfter(_endDate!)) return false;
    if (_travelers < 1) return false;
    if (_budget < 1000) return false;
    return true;
  }

  Map<String, dynamic> _preprocessTripInput() {
    final tripDurationDays =
        _endDate!.difference(_startDate!).inDays + 1; // inclusive
    final avgBudgetPerDay = _budget / _travelers / tripDurationDays;
    final startingCity = _surpriseMe ? 'Auto-Suggested City' : _startingCity;

    return {
      'destination': _destinationController.text,
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
      'status': 'PENDING',
      'createdAt': DateTime.now().toIso8601String(),
      'googleMapsApiKey': _googleMapsApiKey, // Save API key if needed
    };
  }

  Future<void> _saveTrip() async {
    if (!_validateInput()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final tripData = _preprocessTripInput();
    final tripDoc = FirebaseFirestore.instance.collection('trips').doc();

    await tripDoc.set({
      'userId': 'uid_123', // Replace with actual user uid
      ...tripData,
    });

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SmartItineraryScreen(tripId: tripDoc.id),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? _startDate ?? now : _endDate ?? now.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Destination
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(labelText: 'Destination'),
            ),
            const SizedBox(height: 12),

            // Start & End Dates
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text(_startDate == null
                        ? 'Start Date'
                        : _startDate!.toLocal().toString().split(' ')[0]),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickDate(isStart: false),
                    child: Text(_endDate == null
                        ? 'End Date'
                        : _endDate!.toLocal().toString().split(' ')[0]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Travelers
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of Travelers'),
              onChanged: (v) => _travelers = int.tryParse(v) ?? 1,
            ),
            const SizedBox(height: 12),

            // Budget
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Budget (₹)'),
              onChanged: (v) => _budget = double.tryParse(v) ?? 50000,
            ),
            const SizedBox(height: 12),

            // Preferences Dropdowns
            DropdownButtonFormField(
              value: _travelStyle,
              items: ['Cultural', 'Adventure', 'Relaxation', 'Romantic']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _travelStyle = v!),
              decoration: const InputDecoration(labelText: 'Travel Style'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _selectedPace,
              items: ['Slow', 'Balanced', 'Fast']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedPace = v!),
              decoration: const InputDecoration(labelText: 'Pace'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _accommodationType,
              items: ['Hotel', 'Hostel', 'Guest House', 'Resort']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _accommodationType = v!),
              decoration: const InputDecoration(labelText: 'Accommodation'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _mealPreference,
              items: ['Vegetarian', 'Non-Vegetarian', 'Vegan']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _mealPreference = v!),
              decoration: const InputDecoration(labelText: 'Meal Preference'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _transportPreference,
              items: ['Cab', 'Public Transport', 'Self-drive', 'Bike']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _transportPreference = v!),
              decoration: const InputDecoration(labelText: 'Transport Preference'),
            ),
            const SizedBox(height: 16),

            // Surprise Me Checkbox
            CheckboxListTile(
              title: const Text('Surprise Me (Auto-select starting city)'),
              value: _surpriseMe,
              onChanged: (v) => setState(() => _surpriseMe = v!),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _saveTrip,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.deepOrange,
              ),
              child: const Text('Generate Smart Itinerary'),
            ),
          ],
        ),
      ),
    );
  }
}
