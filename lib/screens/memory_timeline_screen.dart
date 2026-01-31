import 'package:flutter/material.dart';
import 'dart:async';

// ============================================================================
// MAIN SCREEN
// ============================================================================

class MemoryTimelineScreen extends StatefulWidget {
  const MemoryTimelineScreen({super.key});

  @override
  State<MemoryTimelineScreen> createState() => _MemoryTimelineScreenState();
}

class _MemoryTimelineScreenState extends State<MemoryTimelineScreen> with SingleTickerProviderStateMixin {
  final MemoryService _memoryService = MemoryService();
  final ScrollController _scrollController = ScrollController();
  
  int _selectedNavIndex = 1;
  bool _isLoading = false;
  String _selectedFilter = 'All';
  late AnimationController _fabAnimationController;
  
  List<DayMemory> _allMemories = [];
  List<DayMemory> _filteredMemories = [];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadMemories();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 100) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  Future<void> _loadMemories() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate loading
    
    final memories = await _memoryService.getAllMemories();
    setState(() {
      _allMemories = memories;
      _filteredMemories = memories;
      _isLoading = false;
    });
  }

  void _filterMemories(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'All') {
        _filteredMemories = _allMemories;
      } else if (filter == 'Favorites') {
        _filteredMemories = _allMemories
            .map((day) => DayMemory(
                  dayNumber: day.dayNumber,
                  dayTitle: day.dayTitle,
                  memories: day.memories.where((m) => m.isFavorite).toList(),
                  photoGallery: day.photoGallery?.where((p) => p.isFavorite).toList(),
                  transitText: day.transitText,
                ))
            .where((day) => day.memories.isNotEmpty || (day.photoGallery?.isNotEmpty ?? false))
            .toList();
      } else {
        _filteredMemories = _allMemories
            .where((day) => day.memories.any((m) => m.locationTag.toUpperCase() == filter.toUpperCase()))
            .toList();
      }
    });
  }

  void _toggleMemoryFavorite(int dayIndex, int memoryIndex) {
    setState(() {
      final memory = _allMemories[dayIndex].memories[memoryIndex];
      memory.isFavorite = !memory.isFavorite;
      _memoryService.toggleFavorite(memory.id);
      
      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(memory.isFavorite ? 'Added to favorites' : 'Removed from favorites'),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFFE8913A),
        ),
      );
    });
  }

  void _togglePhotoFavorite(int dayIndex, int photoIndex) {
    setState(() {
      final photo = _allMemories[dayIndex].photoGallery![photoIndex];
      photo.isFavorite = !photo.isFavorite;
      _memoryService.togglePhotoFavorite(photo.id);
    });
  }

  void _deleteMemory(int dayIndex, int memoryIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Memory'),
        content: const Text('Are you sure you want to delete this memory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final memoryId = _allMemories[dayIndex].memories[memoryIndex].id;
                _allMemories[dayIndex].memories.removeAt(memoryIndex);
                _memoryService.deleteMemory(memoryId);
                _filterMemories(_selectedFilter);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Memory deleted'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _shareMemory(Memory memory) {
    // Simulate sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${memory.title}"...'),
        backgroundColor: const Color(0xFFE8913A),
      ),
    );
  }

  void _addNewMemory() {
    // Navigate to add memory screen (simulated)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening camera...'),
        backgroundColor: Color(0xFFE8913A),
      ),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterChips(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _filteredMemories.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadMemories,
                          color: const Color(0xFFE8913A),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                _buildTripSummary(),
                                const SizedBox(height: 24),
                                ..._filteredMemories.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final dayMemory = entry.value;
                                  return _buildDaySection(dayMemory, index);
                                }),
                                _buildWhatsNextSection(),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _fabAnimationController,
            child: FloatingActionButton.small(
              heroTag: 'scrollTop',
              onPressed: _scrollToTop,
              backgroundColor: Colors.white,
              elevation: 2,
              child: const Icon(Icons.keyboard_arrow_up, color: Color(0xFFE8913A)),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'addMemory',
            onPressed: _addNewMemory,
            backgroundColor: const Color(0xFFE8913A),
            child: const Icon(Icons.add_a_photo, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5EE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_left, size: 24, color: Color(0xFFE8913A)),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'MEMORY TIMELINE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Golden Triangle Tour',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5EE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.more_vert, color: Color(0xFFE8913A)),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 20, color: Color(0xFFE8913A)),
                    SizedBox(width: 12),
                    Text('Share Trip'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download_outlined, size: 20, color: Color(0xFFE8913A)),
                    SizedBox(width: 12),
                    Text('Export PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20, color: Color(0xFFE8913A)),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Favorites', 'Old Delhi', 'Agra', 'Jaipur'];
    
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => _filterMemories(filter),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFE8913A),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFFE8913A),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? const Color(0xFFE8913A) : const Color(0xFFFFDCC0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTripSummary() {
    final totalMemories = _allMemories.fold<int>(
      0,
      (sum, day) => sum + day.memories.length,
    );
    final totalPhotos = _allMemories.fold<int>(
      0,
      (sum, day) => sum + (day.photoGallery?.length ?? 0),
    );
    final totalDays = _allMemories.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE8913A).withOpacity(0.15),
            const Color(0xFFFFB366).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFDCC0).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.event_outlined, totalDays.toString(), 'Days'),
          Container(width: 1, height: 40, color: const Color(0xFFFFDCC0)),
          _buildStatItem(Icons.photo_library_outlined, totalMemories.toString(), 'Memories'),
          Container(width: 1, height: 40, color: const Color(0xFFFFDCC0)),
          _buildStatItem(Icons.collections_outlined, totalPhotos.toString(), 'Photos'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFE8913A), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE8913A)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your memories...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'No memories found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your filter or add new memories',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(DayMemory dayMemory, int dayIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8913A), Color(0xFFFFB366)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8913A).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${dayMemory.dayNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day ${dayMemory.dayNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    dayMemory.dayTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${dayMemory.memories.length} memories',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE8913A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Photo gallery
        if (dayMemory.photoGallery != null && dayMemory.photoGallery!.isNotEmpty)
          _buildPhotoGallery(dayMemory.photoGallery!, dayIndex),

        // Memory cards
        ...dayMemory.memories.asMap().entries.map((entry) {
          final memoryIndex = entry.key;
          final memory = entry.value;
          return _buildMemoryCard(memory, dayIndex, memoryIndex);
        }),

        // Transit indicator
        if (dayMemory.transitText != null)
          _buildTransitIndicator(dayMemory.transitText!),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMemoryCard(Memory memory, int dayIndex, int memoryIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with overlays
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  memory.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, size: 50, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Location tag
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8913A), Color(0xFFFFB366)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8913A).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    _buildActionButton(
                      icon: memory.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: memory.isFavorite ? Colors.red : Colors.white,
                      onTap: () => _toggleMemoryFavorite(dayIndex, memoryIndex),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.share_outlined,
                      color: Colors.white,
                      onTap: () => _shareMemory(memory),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time and date
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      memory.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      memory.date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Title
                Text(
                  memory.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  memory.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),

                // Footer actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildFooterAction(Icons.mode_comment_outlined, '${memory.comments}'),
                        const SizedBox(width: 16),
                        _buildFooterAction(Icons.remove_red_eye_outlined, '${memory.views}'),
                      ],
                    ),
                    PopupMenuButton(
                      icon: Icon(Icons.more_horiz, color: Colors.grey[600]),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: const Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            Duration.zero,
                            () => _deleteMemory(dayIndex, memoryIndex),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildFooterAction(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGallery(List<PhotoItem> photos, int dayIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (context, photoIndex) {
          final photo = photos[photoIndex];
          return Container(
            width: 160,
            margin: EdgeInsets.only(right: photoIndex < photos.length - 1 ? 12 : 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          photo.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(Icons.image_outlined, size: 30, color: Colors.grey[400]),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _togglePhotoFavorite(dayIndex, photoIndex),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              photo.isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: photo.isFavorite ? Colors.red : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    photo.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE8913A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransitIndicator(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE8913A).withOpacity(0.3),
                    const Color(0xFFE8913A).withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5EE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFDCC0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_bus_outlined,
                  color: const Color(0xFFE8913A),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE8913A),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE8913A).withOpacity(0.1),
                    const Color(0xFFE8913A).withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsNextSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE8913A).withOpacity(0.12),
            const Color(0xFFFFB366).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFDCC0).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8913A).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              color: Color(0xFFE8913A),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "What's Next?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Keep capturing the magic of your\njourney through India.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _addNewMemory,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8913A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
              shadowColor: const Color(0xFFE8913A).withOpacity(0.4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, size: 20),
                SizedBox(width: 8),
                Text(
                  'Add New Memory',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.explore_outlined, 'EXPLORE', 0),
          _buildNavItem(Icons.collections_outlined, 'MEMORIES', 1),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF5EE) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFE8913A) : Colors.grey[500],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFFE8913A) : Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

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
  final String id;
  final String locationTag;
  final String imageUrl;
  final String time;
  final String date;
  final String title;
  final String description;
  bool isFavorite;
  final int comments;
  final int views;

  Memory({
    required this.id,
    required this.locationTag,
    required this.imageUrl,
    required this.time,
    required this.date,
    required this.title,
    required this.description,
    this.isFavorite = false,
    this.comments = 0,
    this.views = 0,
  });
}

class PhotoItem {
  final String id;
  final String imageUrl;
  final String label;
  bool isFavorite;

  PhotoItem({
    required this.id,
    required this.imageUrl,
    required this.label,
    this.isFavorite = false,
  });
}

// ============================================================================
// BACKEND SERVICE
// ============================================================================

class MemoryService {
  // Simulate database/API calls
  static final MemoryService _instance = MemoryService._internal();
  factory MemoryService() => _instance;
  MemoryService._internal();

  // In-memory storage (simulating database)
  final Map<String, Memory> _memoriesCache = {};
  final Map<String, PhotoItem> _photosCache = {};

  Future<List<DayMemory>> getAllMemories() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final memories = _generateDummyData();
    
    // Cache all memories
    for (var day in memories) {
      for (var memory in day.memories) {
        _memoriesCache[memory.id] = memory;
      }
      if (day.photoGallery != null) {
        for (var photo in day.photoGallery!) {
          _photosCache[photo.id] = photo;
        }
      }
    }

    return memories;
  }

  Future<void> toggleFavorite(String memoryId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // In real app, this would update database
    print('Toggled favorite for memory: $memoryId');
  }

  Future<void> togglePhotoFavorite(String photoId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    print('Toggled favorite for photo: $photoId');
  }

  Future<void> deleteMemory(String memoryId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _memoriesCache.remove(memoryId);
    print('Deleted memory: $memoryId');
  }

  Future<void> addMemory(Memory memory) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _memoriesCache[memory.id] = memory;
    print('Added new memory: ${memory.id}');
  }

  List<DayMemory> _generateDummyData() {
    return [
      DayMemory(
        dayNumber: 1,
        dayTitle: 'Arrival & Markets',
        memories: [
          Memory(
            id: 'mem_001',
            locationTag: 'Old Delhi',
            imageUrl: 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800',
            time: '10:45 AM',
            date: 'Oct 12',
            title: 'Spices and Scents',
            description: 'The smell of cardamom and chilli in the air was intoxicating. First meal in Delhi was incredible! The vibrant colors of the market stalls and the friendly vendors made this an unforgettable experience.',
            isFavorite: true,
            comments: 12,
            views: 156,
          ),
          Memory(
            id: 'mem_002',
            locationTag: 'Chandni Chowk',
            imageUrl: 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=800',
            time: '02:30 PM',
            date: 'Oct 12',
            title: 'Rickshaw Adventure',
            description: 'Navigating through the narrow lanes of Chandni Chowk was thrilling! The chaos and energy of this place is something you have to experience to believe.',
            isFavorite: false,
            comments: 8,
            views: 98,
          ),
          Memory(
            id: 'mem_003',
            locationTag: 'India Gate',
            imageUrl: 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800',
            time: '06:15 PM',
            date: 'Oct 12',
            title: 'Sunset at India Gate',
            description: 'The golden hour at India Gate was magical. Families gathered, children playing, and the monument standing tall against the orange sky.',
            isFavorite: true,
            comments: 15,
            views: 203,
          ),
        ],
        transitText: 'TRANSIT TO AGRA',
      ),
      DayMemory(
        dayNumber: 2,
        dayTitle: 'The White Marble',
        photoGallery: [
          PhotoItem(
            id: 'photo_001',
            imageUrl: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=800',
            label: 'Taj Mahal',
            isFavorite: true,
          ),
          PhotoItem(
            id: 'photo_002',
            imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
            label: 'Sunrise View',
            isFavorite: true,
          ),
          PhotoItem(
            id: 'photo_003',
            imageUrl: 'https://images.unsplash.com/photo-1548013146-72479768bada?w=800',
            label: 'Garden Path',
            isFavorite: false,
          ),
        ],
        memories: [
          Memory(
            id: 'mem_004',
            locationTag: 'Agra',
            imageUrl: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=800',
            time: '06:00 AM',
            date: 'Oct 13',
            title: 'Taj Mahal at Dawn',
            description: 'Witnessing the Taj Mahal at sunrise was a dream come true. The way the first rays of light touched the white marble was absolutely breathtaking. No words can truly capture this moment.',
            isFavorite: true,
            comments: 28,
            views: 412,
          ),
          Memory(
            id: 'mem_005',
            locationTag: 'Agra Fort',
            imageUrl: 'https://images.unsplash.com/photo-1477587458883-47145ed94245?w=800',
            time: '11:30 AM',
            date: 'Oct 13',
            title: 'Mughal Architecture',
            description: 'The Agra Fort is a masterpiece of Mughal architecture. Walking through the same halls where emperors once ruled gave me chills.',
            isFavorite: false,
            comments: 10,
            views: 167,
          ),
        ],
        transitText: 'TRANSIT TO JAIPUR',
      ),
      DayMemory(
        dayNumber: 3,
        dayTitle: 'The Pink City',
        memories: [
          Memory(
            id: 'mem_006',
            locationTag: 'Jaipur',
            imageUrl: 'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=800',
            time: '09:30 AM',
            date: 'Oct 14',
            title: 'Hawa Mahal',
            description: 'The Palace of Winds is even more stunning in person. The intricate lattice work and pink sandstone make it a photographer\'s paradise.',
            isFavorite: true,
            comments: 18,
            views: 289,
          ),
          Memory(
            id: 'mem_007',
            locationTag: 'Amber Fort',
            imageUrl: 'https://images.unsplash.com/photo-1609137144813-7d9921338f24?w=800',
            time: '04:30 PM',
            date: 'Oct 14',
            title: 'The Amber Palace',
            description: 'Walking through the Sheesh Mahal felt like standing inside a diamond. Rajasthan\'s royalty is something else! The mirror work is absolutely incredible.',
            isFavorite: true,
            comments: 22,
            views: 334,
          ),
        ],
      ),
      DayMemory(
        dayNumber: 4,
        dayTitle: 'Cultural Immersion',
        photoGallery: [
          PhotoItem(
            id: 'photo_004',
            imageUrl: 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=800',
            label: 'Local Market',
            isFavorite: false,
          ),
          PhotoItem(
            id: 'photo_005',
            imageUrl: 'https://images.unsplash.com/photo-1548013146-72479768bada?w=800',
            label: 'Street Food',
            isFavorite: true,
          ),
        ],
        memories: [
          Memory(
            id: 'mem_008',
            locationTag: 'Jaipur',
            imageUrl: 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=800',
            time: '10:00 AM',
            date: 'Oct 15',
            title: 'Johari Bazaar Shopping',
            description: 'The jewelry and textile markets of Jaipur are treasure troves. Spent hours browsing beautiful handcrafted items and learning about traditional techniques.',
            isFavorite: false,
            comments: 14,
            views: 198,
          ),
          Memory(
            id: 'mem_009',
            locationTag: 'Chokhi Dhani',
            imageUrl: 'https://images.unsplash.com/photo-1548013146-72479768bada?w=800',
            time: '07:00 PM',
            date: 'Oct 15',
            title: 'Rajasthani Evening',
            description: 'Traditional dance performances, camel rides, and authentic Rajasthani thali under the stars. This cultural village experience was the perfect way to end our journey.',
            isFavorite: true,
            comments: 31,
            views: 445,
          ),
        ],
      ),
    ];
  }
}