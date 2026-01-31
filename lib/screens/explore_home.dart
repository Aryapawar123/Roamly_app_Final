import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:my_flutter_app_fixed/screens/memory_timeline_screen.dart';

import 'goadetails_screen.dart';
import 'search_results_page.dart';
import 'account_details_page.dart';
import 'create_trip_screen.dart';
import 'my_trips_screen.dart';
import 'expense_split_screen.dart';
import 'group_members_screen.dart';

class ExploreHomeScreen extends StatefulWidget {
  const ExploreHomeScreen({super.key});

  @override
  State<ExploreHomeScreen> createState() => _ExploreHomeScreenState();
}

class _ExploreHomeScreenState extends State<ExploreHomeScreen> {
  int _selectedIndex = 0;
  String _selectedLocation = 'Mumbai';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _selectedLocation = 'Location services disabled');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _selectedLocation = 'Location permission denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _selectedLocation = 'Location permission permanently denied');
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      setState(() {
        _selectedLocation = '${place.locality}, ${place.country}';
      });
    } else {
      setState(() => _selectedLocation = 'Unknown location');
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchResultsPage(searchQuery: query),
        ),
      );
    }
  }

  void _onNavItemTap(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0: // Home
        // Already on home, do nothing
        break;
      case 1: // Itinerary
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyTripsScreen()),
        );
        break;
      case 2: // Expenses
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MemoryTimelineScreen()),
        );
        break;
      case 3: // More
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GroupMembersScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildWhereToText(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildPopularDestinations(),
              const SizedBox(height: 20),
              _buildTrendingExperiences(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTripScreen()),
          );
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Color.fromARGB(255, 21, 6, 6)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.explore, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  // Optional: manual location picker
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedLocation,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text('Cloudy • 28°C', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined)),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountDetailsPage()),
                  );
                },
                child: const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhereToText() {
    return const Center(
      child: Text(
        'Where do you\nwanna go?',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onSubmitted: (_) => _onSearch(),
        decoration: InputDecoration(
          hintText: 'Search destinations, trips...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _searchController.clear(),
          ),
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
      ),
    );
  }

  Widget _buildPopularDestinations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Popular Destinations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _destinationCard('Rajasthan', 'Oct 12-18', 'Heritage Tour', () {}),
              const SizedBox(width: 16),
              _destinationCard('Kerala', 'Nov 02-10', 'Backwaters', () {}),
              const SizedBox(width: 16),
              _destinationCard('Goa', 'Dec 20-26', 'Beach Vacation', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GoaDetailScreen()));
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _destinationCard(String title, String date, String type, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(8),
        color: Colors.orange.shade50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 100, color: Colors.orange.shade100),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('$date • $type', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingExperiences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Trending Experiences', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            _experienceCard('Yoga Retreat', 'Rishikesh', '5 Days', '₹12,500'),
            const SizedBox(height: 8),
            _experienceCard('Heritage Walk', 'Old Delhi', '4 Hours', '₹1,200'),
            const SizedBox(height: 8),
            _experienceCard('Mountain Trek', 'Manali', '3 Days', '₹8,500'),
          ],
        ),
      ],
    );
  }

  Widget _experienceCard(String title, String location, String duration, String price) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.orange.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$title\n$location • $duration'),
          Text(price),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, 'Home', 0),
            _navItem(Icons.map_outlined, 'Itinerary', 1),
            const SizedBox(width: 48), // FAB space
            _navItem(Icons.receipt_long_outlined, 'Expenses', 2),
            _navItem(Icons.menu, 'More', 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavItemTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.orange : Colors.grey),
          Text(label, style: TextStyle(color: isSelected ? Colors.orange : Colors.grey)),
        ],
      ),
    );
  }
}
