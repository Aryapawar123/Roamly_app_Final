import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedLocation = 'Mumbai';

  final List<String> _locations = ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Kolkata'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              
              const SizedBox(height: 16),
              
              // Search Bar
              _buildSearchBar(),
              
              const SizedBox(height: 24),
              
              // Popular Destinations Section
              _buildPopularDestinations(),
              
              const SizedBox(height: 24),
              
              // Trending Experiences Section
              _buildTrendingExperiences(),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Location Selector
          GestureDetector(
            onTap: () => _showLocationPicker(),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFFE8913A),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  _selectedLocation,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF1A1A1A),
                  size: 20,
                ),
              ],
            ),
          ),
          
          // Brand Name
          const Text(
            'Roamly',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE8913A),
            ),
          ),
          
          // Notification & Profile
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF1A1A1A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE8913A),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person,
                      color: Color(0xFF666666),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Colors.grey[400],
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              'Search destinations, trips...',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularDestinations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Destinations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to all destinations
                },
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE8913A),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Destination Cards
        SizedBox(
          height: 380,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildDestinationCard(
                image: 'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=400&h=500&fit=crop',
                title: 'Rajasthan',
                date: 'Oct 12 - 18',
                type: 'Heritage Tour',
                rating: 4.8,
              ),
              const SizedBox(width: 16),
              _buildDestinationCard(
                image: 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=400&h=500&fit=crop',
                title: 'Kerala',
                date: 'Nov 02 - 10',
                type: 'Backwaters',
                rating: 4.7,
              ),
              const SizedBox(width: 16),
              _buildDestinationCard(
                image: 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=400&h=500&fit=crop',
                title: 'Goa',
                date: 'Dec 20 - 26',
                type: 'Beach Vacation',
                rating: 4.6,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationCard({
    required String image,
    required String title,
    required String date,
    required String type,
    required double rating,
  }) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Rating Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  image,
                  width: 240,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 240,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFE8913A),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Date & Type
          Text(
            '$date • $type',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingExperiences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Trending Experiences',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Experience Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _buildExperienceCard(
                image: 'https://images.unsplash.com/photo-1545389336-cf090694435e?w=200&h=200&fit=crop',
                title: 'Yoga Retreat',
                location: 'Rishikesh',
                duration: '5 Days',
                price: '₹12,500',
                iconData: Icons.self_improvement,
              ),
              const SizedBox(height: 12),
              _buildExperienceCard(
                image: 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=200&h=200&fit=crop',
                title: 'Heritage Walk',
                location: 'Old Delhi',
                duration: '4 Hours',
                price: '₹1,200',
                iconData: Icons.account_balance,
              ),
              const SizedBox(height: 12),
              _buildExperienceCard(
                image: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=200&h=200&fit=crop',
                title: 'Mountain Trek',
                location: 'Manali',
                duration: '3 Days',
                price: '₹8,500',
                iconData: Icons.terrain,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceCard({
    required String image,
    required String title,
    required String location,
    required String duration,
    required String price,
    required IconData iconData,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Image/Illustration
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFFFEEE0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  iconData,
                  size: 40,
                  color: const Color(0xFFE8913A),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$location • $duration',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE8913A),
                      ),
                    ),
                    Text(
                      ' /person',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Arrow Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5D0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.chevron_right,
              color: Color(0xFFE8913A),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5EE),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.calendar_month_outlined,
                label: 'Itinerary',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.luggage_outlined,
                label: 'Trips',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.more_horiz,
                label: 'More',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFE8913A) : Colors.grey[400],
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? const Color(0xFFE8913A) : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              _locations.length,
              (index) => ListTile(
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFFE8913A),
                ),
                title: Text(_locations[index]),
                trailing: _selectedLocation == _locations[index]
                    ? const Icon(
                        Icons.check_circle,
                        color: Color(0xFFE8913A),
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _selectedLocation = _locations[index];
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}