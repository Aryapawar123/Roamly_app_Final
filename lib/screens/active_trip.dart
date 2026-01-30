// main.dart
import 'package:flutter/material.dart';

void main() {
  runApp(const ActiveTripScreen());
}

class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Itinerary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'SF Pro Display',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedChipIndex = 0;

  final List<String> _chips = ['Jaipur Itinerary', 'Hotels', 'Food', 'Flights'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildChips(),
              _buildMapSection(),
              _buildTimeline(),
              _buildStatusCards(),
              _buildPopularNearby(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.orange,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Mumbai',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 20),
                    ],
                  ),
                  Text(
                    'Cloudy • 28°C',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
              ),
              const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Text(
              'Where to, explorer?',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Icon(Icons.tune, color: Colors.grey.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildChips() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_chips.length, (index) {
            final isSelected = _selectedChipIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedChipIndex = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (index == 0) ...[
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: isSelected ? Colors.white : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        _chips[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 320,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.network(
                'https://maps.googleapis.com/maps/api/staticmap?center=Jaipur,India&zoom=13&size=600x400&maptype=roadmap&key=YOUR_API_KEY',
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Map View - Jaipur'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Map markers
          Positioned(
            left: 80,
            top: 120,
            child: _buildMapMarker(Colors.orange, Icons.restaurant),
          ),
          Positioned(
            right: 100,
            top: 80,
            child: _buildMapMarker(Colors.orange, Icons.account_balance),
          ),
          Positioned(
            right: 60,
            bottom: 140,
            child: _buildMapMarker(Colors.orange, Icons.museum),
          ),
          // Hawa Mahal Card
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildHawaMahalCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapMarker(Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }

  Widget _buildHawaMahalCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=100',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 48,
                      height: 48,
                      color: Colors.orange.shade100,
                      child: const Icon(Icons.account_balance, color: Colors.orange),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hawa Mahal',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'MUST-VISIT',
                          style: TextStyle(
                            color: Colors.orange.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' • 1.2km away',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text('Navigate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.access_time, size: 18, color: Colors.orange),
                  label: const Text('Running Late'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Timeline",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Day 2 of 4',
                style: TextStyle(
                  color: Colors.orange.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTimelineItem(
            time: '10:00 AM',
            title: 'Amer Fort Exploration',
            subtitle: 'Includes elephant ride & local guide',
            isCompleted: true,
            isActive: false,
          ),
          _buildTimelineItem(
            time: '01:30 PM',
            title: 'Lunch at Panna Meena',
            subtitle: 'Traditional Rajasthani Thali',
            isCompleted: false,
            isActive: true,
            badge: 'HAPPENING NOW',
          ),
          _buildTimelineItem(
            time: '04:00 PM',
            title: 'Jal Mahal Sunset Visit',
            subtitle: 'Photography spot',
            isCompleted: false,
            isActive: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    String? badge,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.orange
                      : isActive
                          ? Colors.orange
                          : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(color: Colors.orange.shade200, width: 3)
                      : null,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 8, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? Colors.orange : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: isActive ? const EdgeInsets.all(16) : null,
              decoration: isActive
                  ? BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: isActive ? Colors.orange : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• $badge',
                          style: TextStyle(
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (isCompleted) ...[
                        const Spacer(),
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade500,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isLast && !isActive ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (isActive)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Text('🍽️', style: TextStyle(fontSize: 12)),
                        ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.groups, color: Colors.grey.shade600),
                  const SizedBox(height: 12),
                  Text(
                    'CROWD STATUS',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'High',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.8,
                    backgroundColor: Colors.orange.shade100,
                    valueColor: const AlwaysStoppedAnimation(Colors.orange),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.hotel, color: Colors.grey.shade600),
                  const SizedBox(height: 12),
                  Text(
                    'STAY',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'The Royal Pala...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confirmed',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularNearby() {
    final places = [
      {
        'name': 'Rawat Mishtan',
        'image': 'https://images.unsplash.com/photo-1567337710282-00832b415979?w=200',
      },
      {
        'name': 'Bapu Bazaar',
        'image': 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=200',
      },
      {
        'name': 'Jantar Mantar',
        'image': 'https://images.unsplash.com/photo-1590766940554-634d2d51c4a8?w=200',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Nearby',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: places.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          places[index]['image']!,
                          height: 120,
                          width: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 120,
                              width: 130,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        places[index]['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
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
            _buildNavItem(Icons.home, 'Home', 0),
            _buildNavItem(Icons.map_outlined, 'Itinerary', 1),
            const SizedBox(width: 48),
            _buildNavItem(Icons.receipt_long_outlined, 'Expenses', 2),
            _buildNavItem(Icons.menu, 'More', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.orange : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.orange : Colors.grey,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}