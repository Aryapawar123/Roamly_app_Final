import 'package:flutter/material.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Upcoming', 'Ongoing', 'Past'];

  // Primary orange color matching Roamly theme
  static const Color primaryOrange = Color(0xFFE8913A);
  static const Color lightOrange = Color(0xFFFFF4ED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tab Filter
            _buildTabFilter(),
            
            // Trips List
            Expanded(
              child: _buildTripsList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'My Trips',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          // User Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryOrange, width: 2),
            ),
            child: ClipOval(
              child: Image.network(
                'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? primaryOrange : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  _tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTripsList() {
    final trips = _getTripsForTab();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return _buildTripCard(trips[index]);
      },
    );
  }

  List<TripData> _getTripsForTab() {
    switch (_selectedTabIndex) {
      case 0: // Upcoming
        return [
          TripData(
            name: 'Rajasthan Adventure',
            location: 'Jaipur & Udaipur, Rajasthan',
            dates: '15 – 22 Feb 2026',
            imageUrl: 'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=800',
            status: TripStatus.upcoming,
          ),
          TripData(
            name: 'Himalayan Escape',
            location: 'Manali, Himachal Pradesh',
            dates: '10 – 15 Mar 2026',
            imageUrl: 'https://images.unsplash.com/photo-1626621341517-bbf3d9990a23?w=800',
            status: TripStatus.upcoming,
          ),
        ];
      case 1: // Ongoing
        return [
          TripData(
            name: 'Kerala Backwaters',
            location: 'Alleppey, Kerala',
            dates: '25 – 30 Jan 2026',
            imageUrl: 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=800',
            status: TripStatus.ongoing,
          ),
        ];
      case 2: // Past
        return [
          TripData(
            name: 'Backwater Bliss',
            location: 'Alleppey, Kerala',
            dates: '02 – 08 Dec 2024',
            imageUrl: 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=800',
            status: TripStatus.completed,
          ),
          TripData(
            name: 'Golden Triangle Tour',
            location: 'Delhi, Agra, Jaipur',
            dates: '10 – 17 Nov 2024',
            imageUrl: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=800',
            status: TripStatus.completed,
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildTripCard(TripData trip) {
    final isCompleted = trip.status == TripStatus.completed;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Status Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: ColorFiltered(
                  colorFilter: isCompleted
                      ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                      : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                  child: Image.network(
                    trip.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              // Status Badge
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(trip.status).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (trip.status != TripStatus.completed)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        _getStatusText(trip.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? Colors.grey[600] : Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Trip Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip Name
                Text(
                  trip.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.grey[600] : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                
                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: isCompleted ? Colors.grey[400] : primaryOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trip.location,
                      style: TextStyle(
                        fontSize: 13,
                        color: isCompleted ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Divider
                Divider(color: Colors.grey[200], height: 1),
                
                const SizedBox(height: 12),
                
                // Dates and Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DATES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[400],
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isCompleted ? Icons.access_time : Icons.calendar_today_outlined,
                              size: 14,
                              color: isCompleted ? Colors.grey[400] : primaryOrange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              trip.dates,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isCompleted ? Colors.grey[500] : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Action Button
                    _buildActionButton(trip.status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.upcoming:
        return primaryOrange;
      case TripStatus.ongoing:
        return Colors.green;
      case TripStatus.completed:
        return Colors.grey[300]!;
    }
  }

  String _getStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.upcoming:
        return 'UPCOMING';
      case TripStatus.ongoing:
        return 'ONGOING';
      case TripStatus.completed:
        return 'COMPLETED';
    }
  }

  Widget _buildActionButton(TripStatus status) {
    final isCompleted = status == TripStatus.completed;
    
    return GestureDetector(
      onTap: () {
        // Handle button tap
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.transparent : primaryOrange,
          borderRadius: BorderRadius.circular(25),
          border: isCompleted ? Border.all(color: Colors.grey[300]!) : null,
        ),
        child: Text(
          isCompleted ? 'Re-visit' : 'View Trip',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isCompleted ? Colors.grey[500] : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Explore Tab
            _buildNavItem(
              icon: Icons.explore_outlined,
              label: 'Explore',
              isSelected: false,
            ),
            
            // My Trips Tab (Active)
            _buildNavItem(
              icon: Icons.work_outline,
              label: 'My Trips',
              isSelected: true,
            ),
            
            // Plan New Trip Button
            GestureDetector(
              onTap: () {
                // Navigate to plan new trip
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: primaryOrange,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Plan New Trip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? primaryOrange : Colors.grey[400],
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isSelected ? primaryOrange : Colors.grey[400],
          ),
        ),
      ],
    );
  }
}

// Trip Status Enum
enum TripStatus {
  upcoming,
  ongoing,
  completed,
}

// Trip Data Model
class TripData {
  final String name;
  final String location;
  final String dates;
  final String imageUrl;
  final TripStatus status;

  TripData({
    required this.name,
    required this.location,
    required this.dates,
    required this.imageUrl,
    required this.status,
  });
}
