import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'smart_itinerary_screen.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentStep = 0;
  final String _placesSessionToken = DateTime.now().millisecondsSinceEpoch.toString();

  // Controllers
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _mustVisitController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _travelersController = TextEditingController();

  // Theme Colors
  static const primaryOrange = Color(0xFFFF9F66);
  static const darkOrange = Color(0xFFFF8243);
  static const lightOrange = Color(0xFFFFB88C);
  static const palePeach = Color(0xFFFFF4ED);
  static const accentOrange = Color(0xFFFF7A3D);

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
  List<String> _activityPreferences = [];

  // Google Maps API Key
  late final String _googleMapsApiKey;
  String? _destinationPlaceId;

  // Loading states
  bool _isLoading = false;
  bool _isSavingTrip = false;

  // Autocomplete
  List<Map<String, String>> _destinationSuggestions = [];
  Timer? _debounce;
  bool _isLoadingSuggestions = false;

  // Dropdown options
  final Map<String, IconData> travelStyles = {
    'Cultural': Icons.museum,
    'Adventure': Icons.terrain,
    'Relaxation': Icons.spa,
    'Romantic': Icons.favorite,
    'Eco-tourism': Icons.nature,
    'Luxury': Icons.diamond,
    'Backpacking': Icons.backpack,
    'Foodie': Icons.restaurant,
    'Wellness': Icons.self_improvement,
  };

  final Map<String, IconData> paceOptions = {
    'Relaxed': Icons.self_improvement,
    'Moderate': Icons.directions_walk,
    'Fast': Icons.directions_run,
  };

  final Map<String, IconData> accommodationOptions = {
    'Hotel': Icons.hotel,
    'Hostel': Icons.bed,
    'Guest House': Icons.house,
    'Resort': Icons.beach_access,
    'Airbnb': Icons.home,
    'Homestay': Icons.cottage,
    'Boutique Hotel': Icons.villa,
  };

  final Map<String, IconData> transportOptions = {
    'Cab': Icons.local_taxi,
    'Public Transport': Icons.directions_bus,
    'Self-drive': Icons.directions_car,
    'Bike': Icons.pedal_bike,
    'Train': Icons.train,
    'Flight': Icons.flight,
  };

  final Map<String, IconData> mealOptions = {
    'Vegetarian': Icons.eco,
    'Non-Vegetarian': Icons.restaurant_menu,
    'Vegan': Icons.grass,
    'Gluten-Free': Icons.no_meals,
    'Keto': Icons.food_bank,
    'Halal': Icons.mosque,
    'Dairy-Free': Icons.no_food,
    'Pescatarian': Icons.set_meal,
  };

  final Map<String, IconData> tripTypes = {
    'Solo': Icons.person,
    'Couple': Icons.favorite,
    'Friends': Icons.group,
    'Family': Icons.family_restroom,
    'Group': Icons.groups,
  };

  final Map<String, IconData> activityOptions = {
    'Hiking': Icons.hiking,
    'Museum': Icons.museum,
    'Shopping': Icons.shopping_bag,
    'Nightlife': Icons.nightlife,
    'Local Cuisine': Icons.restaurant,
    'Historical Tours': Icons.account_balance,
    'Wildlife': Icons.pets,
    'Beaches': Icons.beach_access,
    'Water Sports': Icons.surfing,
    'Meditation/Wellness': Icons.spa,
    'Festivals/Events': Icons.celebration,
  };

  final List<String> avoidCategoriesOptions = [
    'Beaches',
    'Religious Sites',
    'Crowded Areas',
    'Adventure Activities',
    'Nightlife',
    'High Altitude',
    'Animal Interactions',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    _budgetController.text = '50000';
    _travelersController.text = '2';
    
    // Add listener to destination controller
    _destinationController.addListener(_onDestinationChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _destinationController.removeListener(_onDestinationChanged);
    _destinationController.dispose();
    _mustVisitController.dispose();
    _budgetController.dispose();
    _travelersController.dispose();
    super.dispose();
  }

  // Listen to destination changes and fetch suggestions
  void _onDestinationChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    final query = _destinationController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _destinationSuggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    if (query.length < 2) {
      setState(() => _destinationSuggestions = []);
      return;
    }

    setState(() => _isLoadingSuggestions = true);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final suggestions = await fetchDestinationSuggestions(query);
      if (mounted) {
        setState(() {
          _destinationSuggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  // Validation
  bool _validateStep(int step) {
    switch (step) {
      case 0: // Basic Info
        return _destinationController.text.isNotEmpty &&
            _destinationPlaceId != null &&
            _startDate != null &&
            _endDate != null &&
            _travelers >= 1 &&
            _budget >= 1000;
      case 1: // Preferences
        return true; // All optional
      case 2: // Activities
        return true; // All optional
      case 3: // Review
        return true;
      default:
        return false;
    }
  }

  String? _getStepError(int step) {
    switch (step) {
      case 0:
        if (_destinationController.text.isEmpty) {
          return 'Please enter a destination';
        }
        if (_destinationPlaceId == null) {
          return 'Please select a destination from the suggestions';
        }
        if (_startDate == null) return 'Please select start date';
        if (_endDate == null) return 'Please select end date';
        if (_travelers < 1) return 'At least 1 traveler required';
        if (_budget < 1000) return 'Minimum budget is ₹1000';
        final duration = _endDate!.difference(_startDate!).inDays + 1;
        if (duration < 1) return 'Trip must be at least 1 day';
        if (duration > 21) return 'Maximum trip duration is 21 days';
        return null;
      default:
        return null;
    }
  }

  // Date picker
  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? _startDate ?? now
        : _endDate ?? (_startDate ?? now).add(const Duration(days: 1));
    final firstDate = isStart ? now : _startDate ?? now;
    final lastDate = now.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Fetch destination suggestions from Google Places API
  Future<List<Map<String, String>>> fetchDestinationSuggestions(String input) async {
    if (input.isEmpty || _googleMapsApiKey.isEmpty) return [];
    
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&types=(regions)'
        '&key=$_googleMapsApiKey'
        '&sessiontoken=$_placesSessionToken'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List<dynamic>;
          return predictions
              .map((p) => {
                    'description': p['description'] as String,
                    'place_id': p['place_id'] as String,
                  })
              .toList();
        } else {
          debugPrint('Google Places API error: ${data['status']}');
        }
      }
    } catch (e) {
      debugPrint('Error fetching destinations: $e');
    }
    return [];
  }

  // Fetch must-visit places
  Future<List<String>> fetchMustVisitPlaces(String input) async {
    if (input.isEmpty || _destinationPlaceId == null || _googleMapsApiKey.isEmpty) {
      return [];
    }
    
    try {
      // First get location from place_id
      final detailsUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$_destinationPlaceId'
        '&fields=geometry'
        '&key=$_googleMapsApiKey'
      );
      
      final detailsRes = await http.get(detailsUrl);
      if (detailsRes.statusCode != 200) return [];

      final detailsData = json.decode(detailsRes.body);
      if (detailsData['status'] != 'OK') return [];
      
      final location = detailsData['result']['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];

      // Search for tourist attractions nearby
      final nearbyUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=50000'
        '&type=tourist_attraction'
        '&keyword=${Uri.encodeComponent(input)}'
        '&key=$_googleMapsApiKey'
      );
      
      final nearbyRes = await http.get(nearbyUrl);
      if (nearbyRes.statusCode != 200) return [];

      final nearbyData = json.decode(nearbyRes.body);
      if (nearbyData['status'] != 'OK') return [];
      
      final results = nearbyData['results'] as List<dynamic>;
      return results.map((r) => r['name'].toString()).toList();
    } catch (e) {
      debugPrint('Error fetching must-visit places: $e');
    }
    return [];
  }

  // Preprocess and save trip
  Future<void> _saveTrip() async {
    if (!_validateStep(_currentStep)) {
      final error = _getStepError(_currentStep);
      if (error != null) {
        _showSnackBar(error, isError: true);
      }
      return;
    }

    setState(() => _isSavingTrip = true);

    try {
      final tripDurationDays = _endDate!.difference(_startDate!).inDays + 1;
      final avgBudgetPerDay = _budget / _travelers / tripDurationDays;

      final tripData = {
        'destination': _destinationController.text,
        'destinationPlaceId': _destinationPlaceId,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'travelers': _travelers,
        'budget': _budget,
        'avgBudgetPerDay': avgBudgetPerDay,
        'travelStyle': _travelStyle,
        'pace': _selectedPace,
        'startingCity': _surpriseMe ? 'Auto-Suggested City' : _startingCity,
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

      final tripDoc = FirebaseFirestore.instance.collection('trips').doc();
      await tripDoc.set({
        'userId': 'uid_123', // Replace with actual auth UID
        ...tripData,
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SmartItineraryScreen(tripId: tripDoc.id),
        ),
      );
    } catch (e) {
      _showSnackBar('Error creating trip: $e', isError: true);
    } finally {
      setState(() => _isSavingTrip = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : primaryOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 3) {
      if (_validateStep(_currentStep)) {
        setState(() => _currentStep++);
        _tabController.animateTo(_currentStep);
      } else {
        final error = _getStepError(_currentStep);
        if (error != null) _showSnackBar(error, isError: true);
      }
    } else {
      _saveTrip();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _tabController.animateTo(_currentStep);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palePeach,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildProgressIndicator()),
          SliverToBoxAdapter(child: _buildTabBar()),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(),
                _buildPreferencesStep(),
                _buildActivitiesStep(),
                _buildReviewStep(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // App Bar
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Plan Your Journey',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, palePeach.withOpacity(0.3)],
            ),
          ),
        ),
      ),
    );
  }

  // Progress Indicator
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? primaryOrange
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 3) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Tab Bar
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        onTap: (index) {
          // Only allow going back, not forward
          if (index < _currentStep) {
            setState(() => _currentStep = index);
          }
        },
        tabs: const [
          Tab(text: 'Basic'),
          Tab(text: 'Preferences'),
          Tab(text: 'Activities'),
          Tab(text: 'Review'),
        ],
      ),
    );
  }

  // Step 1: Basic Info
  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader('Where to?', Icons.place),
          const SizedBox(height: 12),
          _buildDestinationAutocomplete(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('When?', Icons.calendar_today),
          const SizedBox(height: 12),
          _buildDateSelector(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Who\'s traveling?', Icons.people),
          const SizedBox(height: 12),
          _buildTravelersSelector(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Budget', Icons.account_balance_wallet),
          const SizedBox(height: 12),
          _buildBudgetSelector(),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // Step 2: Preferences
  Widget _buildPreferencesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader('Travel Style', Icons.style),
          const SizedBox(height: 12),
          _buildIconGrid(travelStyles, _travelStyle, (value) {
            setState(() => _travelStyle = value);
          }),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Trip Type', Icons.group),
          const SizedBox(height: 12),
          _buildIconGrid(tripTypes, _tripType, (value) {
            setState(() => _tripType = value);
          }),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Pace', Icons.speed),
          const SizedBox(height: 12),
          _buildIconGrid(paceOptions, _selectedPace, (value) {
            setState(() => _selectedPace = value);
          }),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Accommodation', Icons.hotel),
          const SizedBox(height: 12),
          _buildIconGrid(accommodationOptions, _accommodationType, (value) {
            setState(() => _accommodationType = value);
          }),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Transport', Icons.directions_car),
          const SizedBox(height: 12),
          _buildIconGrid(transportOptions, _transportPreference, (value) {
            setState(() => _transportPreference = value);
          }),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Meal Preference', Icons.restaurant),
          const SizedBox(height: 12),
          _buildIconGrid(mealOptions, _mealPreference, (value) {
            setState(() => _mealPreference = value);
          }),
          
          const SizedBox(height: 24),
          _buildSurpriseMeSection(),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // Step 3: Activities
  Widget _buildActivitiesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader('Activity Preferences', Icons.explore),
          const SizedBox(height: 12),
          _buildMultiSelectGrid(activityOptions, _activityPreferences, (value) {
            setState(() {
              if (_activityPreferences.contains(value)) {
                _activityPreferences.remove(value);
              } else {
                _activityPreferences.add(value);
              }
            });
          }),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Must-Visit Places', Icons.location_on),
          const SizedBox(height: 12),
          _buildMustVisitSection(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Avoid Categories', Icons.block),
          const SizedBox(height: 12),
          _buildAvoidCategoriesSection(),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // Step 4: Review
  Widget _buildReviewStep() {
    final duration = _startDate != null && _endDate != null
        ? _endDate!.difference(_startDate!).inDays + 1
        : 0;
    final avgBudgetPerDay = duration > 0 ? (_budget / _travelers / duration).toInt() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader('Review Your Trip', Icons.check_circle),
          const SizedBox(height: 16),
          
          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryOrange, darkOrange],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryOrange.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(Icons.calendar_today, '$duration', 'Days'),
                _buildDivider(),
                _buildSummaryItem(Icons.people, '$_travelers', 'Travelers'),
                _buildDivider(),
                _buildSummaryItem(Icons.account_balance_wallet, '₹${_formatAmount(_budget.toInt())}', 'Budget'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Details Cards
          _buildReviewCard('Trip Details', [
            _buildReviewRow('Destination', _destinationController.text),
            _buildReviewRow(
              'Dates',
              _startDate != null && _endDate != null
                  ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}'
                  : 'Not selected',
            ),
            _buildReviewRow('Duration', '$duration days'),
            _buildReviewRow('Daily Budget', '₹${_formatAmount(avgBudgetPerDay)}'),
          ]),
          
          const SizedBox(height: 16),
          
          _buildReviewCard('Preferences', [
            _buildReviewRow('Travel Style', _travelStyle),
            _buildReviewRow('Trip Type', _tripType),
            _buildReviewRow('Pace', _selectedPace),
            _buildReviewRow('Accommodation', _accommodationType),
            _buildReviewRow('Transport', _transportPreference),
            _buildReviewRow('Meals', _mealPreference),
          ]),
          
          if (_activityPreferences.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildReviewCard('Activities', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _activityPreferences
                    .map((activity) => Chip(
                          label: Text(
                            activity,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: palePeach,
                          labelStyle: const TextStyle(color: primaryOrange),
                        ))
                    .toList(),
              ),
            ]),
          ],
          
          if (_mustVisitPlaces.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildReviewCard('Must-Visit Places', [
              ..._mustVisitPlaces.map(
                (place) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: primaryOrange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(place)),
                    ],
                  ),
                ),
              ),
            ]),
          ],
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: palePeach,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryOrange, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Destination Autocomplete with Google Maps Places API
  Widget _buildDestinationAutocomplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
          child: TextField(
            controller: _destinationController,
            decoration: InputDecoration(
              hintText: 'Search destinations...',
              prefixIcon: const Icon(Icons.search, color: primaryOrange),
              suffixIcon: _isLoadingSuggestions
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryOrange,
                        ),
                      ),
                    )
                  : _destinationController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _destinationController.clear();
                              _destinationPlaceId = null;
                              _destinationSuggestions = [];
                            });
                          },
                        )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        
        // Suggestions List
        if (_destinationSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              itemCount: _destinationSuggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = _destinationSuggestions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: primaryOrange),
                  title: Text(
                    suggestion['description']!,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () {
                    setState(() {
                      _destinationController.text = suggestion['description']!;
                      _destinationPlaceId = suggestion['place_id'];
                      _destinationSuggestions = [];
                      _mustVisitPlaces.clear(); // Clear when destination changes
                    });
                  },
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                );
              },
            ),
          ),
        ],
        
        // Selected indicator
        if (_destinationPlaceId != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Destination selected: ${_destinationController.text}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Date Selector
  Widget _buildDateSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildDateButton(
            label: _startDate == null
                ? 'Start Date'
                : DateFormat('MMM d, yyyy').format(_startDate!),
            icon: Icons.calendar_today,
            onTap: () => _pickDate(isStart: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateButton(
            label: _endDate == null
                ? 'End Date'
                : DateFormat('MMM d, yyyy').format(_endDate!),
            icon: Icons.event,
            onTap: () => _pickDate(isStart: false),
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryOrange.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryOrange, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Travelers Selector
  Widget _buildTravelersSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          const Icon(Icons.people, color: primaryOrange),
          const SizedBox(width: 12),
          const Text(
            'Number of Travelers',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: primaryOrange,
            onPressed: _travelers > 1
                ? () => setState(() {
                      _travelers--;
                      _travelersController.text = _travelers.toString();
                    })
                : null,
          ),
          SizedBox(
            width: 50,
            child: TextField(
              controller: _travelersController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed >= 1 && parsed <= 10) {
                  setState(() => _travelers = parsed);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: primaryOrange,
            onPressed: _travelers < 10
                ? () => setState(() {
                      _travelers++;
                      _travelersController.text = _travelers.toString();
                    })
                : null,
          ),
        ],
      ),
    );
  }

  // Budget Selector
  Widget _buildBudgetSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: primaryOrange),
              const SizedBox(width: 12),
              const Text(
                'Total Budget',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryOrange,
            ),
            decoration: const InputDecoration(
              prefix: Text(
                '₹ ',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryOrange,
                ),
              ),
              border: InputBorder.none,
              hintText: '50000',
            ),
            onChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed != null) {
                setState(() => _budget = parsed);
              }
            },
          ),
          const SizedBox(height: 12),
          Slider(
            value: _budget.clamp(1000, 500000),
            min: 1000,
            max: 500000,
            divisions: 100,
            activeColor: primaryOrange,
            inactiveColor: palePeach,
            onChanged: (value) {
              setState(() {
                _budget = value;
                _budgetController.text = value.toInt().toString();
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹1K',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Text(
                '₹500K',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Icon Grid for single selection
  Widget _buildIconGrid(
    Map<String, IconData> options,
    String selectedValue,
    Function(String) onSelected,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.entries.map((entry) {
        final isSelected = selectedValue == entry.key;
        return GestureDetector(
          onTap: () => onSelected(entry.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? primaryOrange : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primaryOrange : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  entry.value,
                  color: isSelected ? Colors.white : primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  entry.key,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Multi-select Grid
  Widget _buildMultiSelectGrid(
    Map<String, IconData> options,
    List<String> selectedValues,
    Function(String) onToggle,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.entries.map((entry) {
        final isSelected = selectedValues.contains(entry.key);
        return GestureDetector(
          onTap: () => onToggle(entry.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? primaryOrange : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primaryOrange : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  entry.value,
                  color: isSelected ? Colors.white : primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  entry.key,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Must-Visit Section
  Widget _buildMustVisitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_mustVisitPlaces.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _mustVisitPlaces
                .map((place) => Chip(
                      label: Text(place),
                      onDeleted: () =>
                          setState(() => _mustVisitPlaces.remove(place)),
                      backgroundColor: palePeach,
                      deleteIconColor: primaryOrange,
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (_destinationPlaceId != null)
          Container(
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
            child: TextField(
              controller: _mustVisitController,
              decoration: InputDecoration(
                hintText: 'Add must-visit places...',
                prefixIcon: const Icon(Icons.add_location, color: primaryOrange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty && !_mustVisitPlaces.contains(value)) {
                  setState(() {
                    _mustVisitPlaces.add(value);
                    _mustVisitController.clear();
                  });
                }
              },
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select a destination first to add must-visit places',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Avoid Categories Section
  Widget _buildAvoidCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_avoidCategories.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _avoidCategories
                .map((category) => Chip(
                      label: Text(category),
                      onDeleted: () =>
                          setState(() => _avoidCategories.remove(category)),
                      backgroundColor: Colors.red.shade50,
                      deleteIconColor: Colors.red,
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: avoidCategoriesOptions.map((category) {
            final isSelected = _avoidCategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _avoidCategories.add(category);
                  } else {
                    _avoidCategories.remove(category);
                  }
                });
              },
              selectedColor: Colors.red.shade100,
              checkmarkColor: Colors.red,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? Colors.red : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Surprise Me Section
  Widget _buildSurpriseMeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryOrange.withOpacity(0.1), palePeach],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Surprise Me!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Let AI choose the best starting city',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _surpriseMe,
            onChanged: (value) => setState(() => _surpriseMe = value),
            activeColor: primaryOrange,
          ),
        ],
      ),
    );
  }

  // Review Card
  Widget _buildReviewCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
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

  // Bottom Navigation
  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: primaryOrange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryOrange,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSavingTrip ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: primaryOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSavingTrip
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep < 3
                                ? 'Continue'
                                : 'Generate Itinerary',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentStep < 3
                                ? Icons.arrow_forward
                                : Icons.auto_awesome,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
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
}