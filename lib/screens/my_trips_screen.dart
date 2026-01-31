import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'trip_detail_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> with SingleTickerProviderStateMixin {
  int selectedTab = 0;
  late final String userId;
  late TabController _tabController;
  String searchQuery = '';
  String sortBy = 'recent'; // recent, budget, alphabetical
  bool showSearch = false;

  // Enhanced Theme Colors
  static const primaryOrange = Color(0xFFFF9F66);
  static const darkOrange = Color(0xFFFF8243);
  static const lightOrange = Color(0xFFFFB88C);
  static const palePeach = Color(0xFFFFF4ED);
  static const accentOrange = Color(0xFFFF7A3D);

  final tabs = const ['Upcoming', 'Ongoing', 'Completed'];

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palePeach,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildSearchAndFilter()),
          SliverToBoxAdapter(child: _buildStats()),
          SliverToBoxAdapter(child: _buildTabs()),
          _buildTrips(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ------------------ ENHANCED APP BAR ------------------
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'My Journeys',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                palePeach.withOpacity(0.3),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            showSearch ? Icons.close : Icons.search,
            color: primaryOrange,
          ),
          onPressed: () => setState(() {
            showSearch = !showSearch;
            if (!showSearch) searchQuery = '';
          }),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black54),
          onSelected: (value) {
            if (value == 'archive') {
              _showArchiveDialog();
            } else if (value == 'export') {
              _exportTrips();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(Icons.archive_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Archived Trips'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Export Data'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------ SEARCH & FILTER ------------------
  Widget _buildSearchAndFilter() {
    if (!showSearch) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Search destinations...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palePeach,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sort, size: 20, color: primaryOrange),
            ),
            onSelected: (value) => setState(() => sortBy = value),
            itemBuilder: (context) => [
              _buildSortOption('recent', 'Most Recent', Icons.access_time),
              _buildSortOption('budget', 'Budget', Icons.attach_money),
              _buildSortOption('alphabetical', 'A-Z', Icons.sort_by_alpha),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortOption(String value, String label, IconData icon) {
    final isSelected = sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? primaryOrange : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryOrange : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check, size: 18, color: primaryOrange),
          ],
        ],
      ),
    );
  }

  // ------------------ STATS OVERVIEW ------------------
  Widget _buildStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedTrips')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final trips = snapshot.data!.docs;
        final upcoming = trips.where((t) => (t.data() as Map)['status'] == 'NOT_STARTED').length;
        final ongoing = trips.where((t) => (t.data() as Map)['status'] == 'IN_PROGRESS').length;
        final completed = trips.where((t) => (t.data() as Map)['status'] == 'COMPLETED').length;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryOrange, darkOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
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
              _buildStatItem(upcoming, 'Upcoming', Icons.event_available),
              _buildDivider(),
              _buildStatItem(ongoing, 'Ongoing', Icons.trending_up),
              _buildDivider(),
              _buildStatItem(completed, 'Completed', Icons.check_circle),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(int count, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
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

  // ------------------ ENHANCED TABS ------------------
  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryOrange, lightOrange],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryOrange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  // ------------------ ENHANCED TRIPS LIST ------------------
  Widget _buildTrips() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedTrips')
          .orderBy('createdAt', descending: true)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: primaryOrange),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(),
          );
        }

        var trips = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'NOT_STARTED';
          final destination = (data['destination'] ?? '').toString().toLowerCase();
          
          final matchesTab = _filterByStatus(status);
          final matchesSearch = searchQuery.isEmpty || 
              destination.contains(searchQuery.toLowerCase());
          
          return matchesTab && matchesSearch;
        }).toList();

        // Apply sorting
        trips = _sortTrips(trips);

        if (trips.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildEnhancedTripCard(trips[index], index),
              childCount: trips.length,
            ),
          ),
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _sortTrips(List<QueryDocumentSnapshot> trips) {
    switch (sortBy) {
      case 'budget':
        trips.sort((a, b) {
          final budgetA = (a.data() as Map)['budget'] ?? 0;
          final budgetB = (b.data() as Map)['budget'] ?? 0;
          return budgetB.compareTo(budgetA);
        });
        break;
      case 'alphabetical':
        trips.sort((a, b) {
          final destA = (a.data() as Map)['destination'] ?? '';
          final destB = (b.data() as Map)['destination'] ?? '';
          return destA.toString().compareTo(destB.toString());
        });
        break;
      default: // recent
        break;
    }
    return trips;
  }

  bool _filterByStatus(String status) {
    if (selectedTab == 0) return status == 'NOT_STARTED';
    if (selectedTab == 1) return status == 'IN_PROGRESS';
    return status == 'COMPLETED';
  }

  // ------------------ ENHANCED TRIP CARD ------------------
  Widget _buildEnhancedTripCard(QueryDocumentSnapshot trip, int index) {
    final data = trip.data() as Map<String, dynamic>;

    final destination = data['destination'] ?? 'Unknown destination';
    final budget = data['budget'] ?? 0;
    final status = data['status'] ?? 'NOT_STARTED';
    final createdAt = data['createdAt'] as Timestamp?;

    final coverImage = data['coverImage'] ??
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee';

    final stats = data['stats'] ?? {};
    final totalDays = stats['totalDays'] ?? 0;
    final completedDays = stats['completedDays'] ?? 0;

    final progress = totalDays == 0 ? 0.0 : completedDays / totalDays;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: Key(trip.id),
        background: _buildSwipeBackground(true),
        secondaryBackground: _buildSwipeBackground(false),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            return await _showDeleteDialog(trip.id);
          } else {
            _archiveTrip(trip.id);
            return false;
          }
        },
        child: GestureDetector(
          onTap: () => _navigateToDetails(trip.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryOrange.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ENHANCED IMAGE WITH GRADIENT OVERLAY
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: Image.network(
                        coverImage,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [lightOrange, palePeach],
                            ),
                          ),
                          child: const Icon(
                            Icons.landscape,
                            size: 64,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Status badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _buildEnhancedStatusChip(status),
                    ),
                    // Quick actions
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Row(
                        children: [
                          _buildQuickActionButton(
                            Icons.share_outlined,
                            () => _shareTrip(trip.id),
                          ),
                          const SizedBox(width: 8),
                          _buildQuickActionButton(
                            Icons.favorite_border,
                            () => _toggleFavorite(trip.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Destination
                      Text(
                        destination,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Budget & Date Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: palePeach,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 16,
                                  color: primaryOrange,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "₹${_formatBudget(budget)}",
                                  style: const TextStyle(
                                    color: primaryOrange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (createdAt != null)
                            Text(
                              _formatDate(createdAt),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),

                      // Progress section
                      if (status != 'NOT_STARTED' && totalDays > 0) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Progress",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        "${(progress * 100).toInt()}%",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: primaryOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: palePeach,
                                      valueColor: AlwaysStoppedAnimation(
                                        primaryOrange,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Day $completedDays of $totalDays",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Action buttons for upcoming trips
                      if (status == 'NOT_STARTED') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _startTrip(trip.id),
                                icon: const Icon(Icons.play_arrow, size: 18),
                                label: const Text('Start Trip'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryOrange,
                                  side: const BorderSide(color: primaryOrange),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: primaryOrange),
      ),
    );
  }

  Widget _buildSwipeBackground(bool isLeft) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isLeft ? Colors.blue : Colors.red,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(
        isLeft ? Icons.archive : Icons.delete,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  // ------------------ ENHANCED STATUS CHIP ------------------
  Widget _buildEnhancedStatusChip(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'IN_PROGRESS':
        color = Colors.blue;
        label = 'Ongoing';
        icon = Icons.navigation;
        break;
      case 'COMPLETED':
        color = Colors.green;
        label = 'Completed';
        icon = Icons.check_circle;
        break;
      default:
        color = primaryOrange;
        label = 'Upcoming';
        icon = Icons.event;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ EMPTY STATE ------------------
  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (selectedTab) {
      case 1:
        message = 'No ongoing trips';
        icon = Icons.explore_off;
        break;
      case 2:
        message = 'No completed trips yet';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'No upcoming trips';
        icon = Icons.event_busy;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palePeach,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: lightOrange),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start planning your next adventure!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ FAB ------------------
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _createNewTrip(),
      backgroundColor: primaryOrange,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'New Trip',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 8,
    );
  }

  // ------------------ HELPER METHODS ------------------
  String _formatBudget(int budget) {
    if (budget >= 100000) {
      return '${(budget / 100000).toStringAsFixed(1)}L';
    } else if (budget >= 1000) {
      return '${(budget / 1000).toStringAsFixed(1)}K';
    }
    return budget.toString();
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM d, yyyy').format(date);
  }

  void _navigateToDetails(String tripId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripDetailScreen(
          tripId: tripId,
          userId: userId,
        ),
      ),
    );
  }

  Future<void> _startTrip(String tripId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedTrips')
          .doc(tripId)
          .update({'status': 'IN_PROGRESS'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trip started! Have a great journey! 🎉'),
            backgroundColor: primaryOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start trip')),
        );
      }
    }
  }

  Future<bool> _showDeleteDialog(String tripId) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Delete Trip?'),
            content: const Text(
              'Are you sure you want to delete this trip? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _archiveTrip(String tripId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Trip archived'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _shareTrip(String tripId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon!')),
    );
  }

  void _toggleFavorite(String tripId) {
    // Implement favorite toggle
  }

  void _createNewTrip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to trip creation screen')),
    );
  }

  void _showArchiveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Archived Trips'),
        content: const Text('View and restore your archived trips.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportTrips() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exporting trips data...'),
        backgroundColor: primaryOrange,
      ),
    );
  }
}