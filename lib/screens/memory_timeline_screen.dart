import 'package:flutter/material.dart';

// Roamly Memory Timeline Screen
// A travel journal/timeline view showing memories from a trip organized by days

class MemoryTimelineScreen extends StatefulWidget {
  const MemoryTimelineScreen({super.key});

  @override
  State<MemoryTimelineScreen> createState() => _MemoryTimelineScreenState();
}

class _MemoryTimelineScreenState extends State<MemoryTimelineScreen> {
  int _selectedNavIndex = 1; // MEMORIES tab selected

  // Sample data for memories
  final List<DayMemory> _memories = [
    DayMemory(
      dayNumber: 1,
      dayTitle: 'Arrival & Markets',
      memories: [
        Memory(
          locationTag: 'Old Delhi',
          imageUrl: 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=400',
          time: '10:45 AM',
          date: 'OCT 12',
          title: 'Spices and Scents',
          description: 'The smell of cardamom and chilli in the air was intoxicating. First meal in Delhi was incredible!',
        ),
      ],
      transitText: 'TRANSIT TO AGRA',
    ),
    DayMemory(
      dayNumber: 2,
      dayTitle: 'The White Marble',
      photoGallery: [
        PhotoItem(
          imageUrl: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=400',
          label: 'Taj Mahal',
          isFavorite: true,
        ),
        PhotoItem(
          imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
          label: 'Sunrise View',
          isFavorite: true,
        ),
      ],
      memories: [
        Memory(
          locationTag: 'JAIPUR',
          imageUrl: 'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=400',
          time: '04:30 PM',
          date: 'Oct 13',
          title: 'The Amber Palace',
          description: 'Walking through the Sheesh Mahal felt like standing inside a diamond. Rajasthan\'s royalty is something else!',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Timeline content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Day memories
                    ..._memories.map((dayMemory) => _buildDaySection(dayMemory)),
                    
                    // What's next section
                    _buildWhatsNextSection(),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            
            // Bottom navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFE8913A),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.chevron_left, size: 28),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'MEMORY TIMELINE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Golden Triangle Tour',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(DayMemory dayMemory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFE8913A),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${dayMemory.dayNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Day ${dayMemory.dayNumber}: ${dayMemory.dayTitle}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Photo gallery (if exists)
        if (dayMemory.photoGallery != null && dayMemory.photoGallery!.isNotEmpty)
          _buildPhotoGallery(dayMemory.photoGallery!),
        
        // Memory cards
        ...dayMemory.memories.map((memory) => _buildMemoryCard(memory)),
        
        // Transit indicator (if exists)
        if (dayMemory.transitText != null)
          _buildTransitIndicator(dayMemory.transitText!),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMemoryCard(Memory memory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with location tag
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  memory.imageUrl,
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
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8913A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        memory.locationTag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${memory.time} • ${memory.date}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  memory.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  memory.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(List<PhotoItem> photos) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: photos.map((photo) => Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: photos.indexOf(photo) < photos.length - 1 ? 12 : 0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    photo.imageUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 30, color: Colors.grey),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        photo.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE8913A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        photo.isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: photo.isFavorite ? Colors.red : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildTransitIndicator(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Bus icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.directions_bus_outlined,
              color: Colors.grey[400],
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsNextSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE8913A).withOpacity(0.1),
            const Color(0xFFE8913A).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Camera icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              color: Colors.grey[400],
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "What's next?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep capturing the magic of your\njourney through India.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Add New Memory',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.edit_outlined, 'EXPLORE', 0),
          _buildNavItem(Icons.chat_bubble_outline, 'MEMORIES', 1),
          _buildNavItem(Icons.map_outlined, 'MAP', 2),
          _buildNavItem(Icons.person_outline, 'PROFILE', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFE8913A) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFFE8913A) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// Data models
class DayMemory {
  final int dayNumber;
  final String dayTitle;
  final List<Memory> memories;
  final List<PhotoItem>? photoGallery;
  final String? transitText;

  DayMemory({
    required this.dayNumber,
    required this.dayTitle,
    required this.memories,
    this.photoGallery,
    this.transitText,
  });
}

class Memory {
  final String locationTag;
  final String imageUrl;
  final String time;
  final String date;
  final String title;
  final String description;

  Memory({
    required this.locationTag,
    required this.imageUrl,
    required this.time,
    required this.date,
    required this.title,
    required this.description,
  });
}

class PhotoItem {
  final String imageUrl;
  final String label;
  final bool isFavorite;

  PhotoItem({
    required this.imageUrl,
    required this.label,
    this.isFavorite = false,
  });
}
