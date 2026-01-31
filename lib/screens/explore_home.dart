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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      setState(() {
        _selectedLocation =
            '${placemarks.first.locality}, ${placemarks.first.country}';
      });
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
          MaterialPageRoute(builder: (_) => MyTripsScreen()),
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
              const SizedBox(height: 24),
              _buildPopularDestinations(),
              const SizedBox(height: 32),
              _buildTrendingExperiences(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // 🔥 FIXED NAV BAR
      bottomNavigationBar: _buildBottomNav(),

      // ➕ FAB KEPT AS IS
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTripScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ================= HEADER =================

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedLocation,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('Cloudy • 28°C', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AccountDetailsPage()));
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
    );
  }

  Widget _buildWhereToText() {
    return const Text(
      'Where do you\nwanna go?',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search destinations, trips...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  // ================= POPULAR DESTINATIONS =================

  Widget _buildPopularDestinations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Popular Destinations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _destinationCard(
                'Rajasthan',
                'Oct 12 - 18 • Heritage Tour',
                'https://images.unsplash.com/photo-1599661046289-e31897846e41',
                () {},
              ),
              const SizedBox(width: 16),
              _destinationCard(
                'Kerala',
                'Nov 02 - 10 • Backwaters',
                'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944',
                () {},
              ),
              const SizedBox(width: 16),
              _destinationCard(
                'Goa',
                'Dec 20 - 26 • Beach Vacation',
                'https://images.unsplash.com/photo-1507525428034-b723cf961d3e',
                () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GoaDetailScreen()));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _destinationCard(
      String title, String subtitle, String imageUrl, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.network(
                imageUrl,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ================= TRENDING EXPERIENCES =================

  Widget _buildTrendingExperiences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Trending Experiences',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        _experienceCard(
          'Yoga Retreat',
          'Rishikesh • 5 Days',
          '₹12,500',
          'https://images.unsplash.com/photo-1599447421416-3414500d18a5',
        ),
        _experienceCard(
          'Heritage Walk',
          'Old Delhi • 4 Hours',
          '₹1,200',
          'https://images.unsplash.com/photo-1587474260584-136574528ed5',
        ),
        _experienceCard(
          'Mountain Trek',
          'Manali • 3 Days',
          '₹8,500',
          'https://images.unsplash.com/photo-1501785888041-af3ef285b470',
        ),
      ],
    );
  }

  Widget _experienceCard(
      String title, String subtitle, String price, String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.network(
              imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Text(
                  '$price /person',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM NAV =================

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      elevation: 8,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_filled, 'Home', 0),
            _navItem(Icons.map_outlined, 'Itinerary', 1),

            // space for FAB
            const SizedBox(width: 48),

            _navItem(Icons.receipt_long_outlined, 'Expenses', 2),
            _navItem(Icons.menu, 'More', 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavItemTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected ? Colors.orange : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.orange : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}