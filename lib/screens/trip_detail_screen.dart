import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'expense_split_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  final String userId;

  const TripDetailScreen({
    Key? key,
    required this.tripId,
    required this.userId,
  }) : super(key: key);

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showMap = false;

  // Enhanced Theme Colors
  static const primaryOrange = Color(0xFFFF9F66);
  static const darkOrange = Color(0xFFFF8243);
  static const lightOrange = Color(0xFFFFB88C);
  static const palePeach = Color(0xFFFFF4ED);
  static const accentOrange = Color(0xFFFF7A3D);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('savedTrips')
            .doc(widget.tripId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: primaryOrange),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final imageUrl = data['coverImage'] ??
              data['imageUrl'] ??
              'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee';

          final status = data['status'] ?? 'NOT_STARTED';
          final destination = data['destination'] ?? 'Trip';
          final budget = data['budget'] ?? 0;

          return CustomScrollView(
            slivers: [
              _buildEnhancedAppBar(context, imageUrl, destination),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHeader(data, status),
                    _buildTripStats(data),
                    _buildBudgetOverview(budget),
                    _buildTabBar(),
                  ],
                ),
              ),
              _buildTabContent(),
            ],
          );
        },
      ),
    );
  }

  // ------------------ ENHANCED APP BAR ------------------
  Widget _buildEnhancedAppBar(
      BuildContext context, String imageUrl, String destination) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: primaryOrange,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.black87),
            onPressed: _shareTrip,
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: _showOptions,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [lightOrange, primaryOrange],
                  ),
                ),
                child: const Icon(
                  Icons.landscape,
                  size: 80,
                  color: Colors.white70,
                ),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Destination text
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        destination.split(',')[0],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ HEADER WITH STATUS ------------------
  Widget _buildHeader(Map<String, dynamic> data, String status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildEnhancedStatusChip(status),
              _buildActionButtons(status),
            ],
          ),
        ],
      ),
    );
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    return Row(
      children: [
        _buildQuickAction(
          Icons.receipt_long,
          'Expenses',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExpenseSplitScreen(tripId: widget.tripId),
              ),
            );
          },
        ),
        if (status == 'IN_PROGRESS' || status == 'COMPLETED') ...[
          const SizedBox(width: 8),
          _buildQuickAction(
            Icons.photo_library,
            'Memories',
            () {
              _showComingSoon('Memories feature');
            },
          ),
        ],
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: palePeach,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: primaryOrange),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryOrange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ TRIP STATS ROW ------------------
  Widget _buildTripStats(Map<String, dynamic> data) {
    final stats = data['stats'] ?? {};
    final totalDays = stats['totalDays'] ?? 0;
    final completedDays = stats['completedDays'] ?? 0;
    final startDate = data['startDate'] as String?;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryOrange, darkOrange],
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
          _buildStatItem(
            Icons.calendar_today,
            '$totalDays',
            'Days',
          ),
          _buildStatDivider(),
          _buildStatItem(
            Icons.check_circle_outline,
            '$completedDays',
            'Completed',
          ),
          _buildStatDivider(),
          _buildStatItem(
            Icons.percent,
            '${totalDays > 0 ? ((completedDays / totalDays) * 100).toInt() : 0}',
            'Progress',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
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

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  // ------------------ BUDGET OVERVIEW ------------------
  Widget _buildBudgetOverview(int budget) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('savedTrips')
          .doc(widget.tripId)
          .collection('days')
          .snapshots(),
      builder: (context, snapshot) {
        double estimatedTotal = 0;
        double actualSpent = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            estimatedTotal += (data['estimatedDayCost'] ?? 0).toDouble();
            actualSpent += (data['actualSpent'] ?? 0).toDouble();
          }
        }

        final remaining = budget - actualSpent;
        final percentSpent = budget > 0 ? (actualSpent / budget) : 0.0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Budget Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: remaining >= 0 ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      remaining >= 0 ? 'On Budget' : 'Over Budget',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBudgetDetail(
                    'Total Budget',
                    '₹${_formatAmount(budget)}',
                    primaryOrange,
                  ),
                  _buildBudgetDetail(
                    'Spent',
                    '₹${_formatAmount(actualSpent.toInt())}',
                    Colors.red.shade400,
                  ),
                  _buildBudgetDetail(
                    'Remaining',
                    '₹${_formatAmount(remaining.toInt())}',
                    Colors.green.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentSpent > 1 ? 1 : percentSpent,
                  minHeight: 12,
                  backgroundColor: palePeach,
                  valueColor: AlwaysStoppedAnimation(
                    percentSpent > 0.9 ? Colors.red : primaryOrange,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(percentSpent * 100).toInt()}% of budget used',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetDetail(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ------------------ TAB BAR ------------------
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
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
          gradient: LinearGradient(
            colors: [primaryOrange, lightOrange],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'Itinerary'),
          Tab(text: 'Map'),
          Tab(text: 'Weather'),
        ],
      ),
    );
  }

  // ------------------ TAB CONTENT ------------------
  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildItineraryTab(),
          _buildMapTab(),
          _buildWeatherTab(),
        ],
      ),
    );
  }

  // ------------------ ITINERARY TAB ------------------
  Widget _buildItineraryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('savedTrips')
          .doc(widget.tripId)
          .collection('days')
          .orderBy('day')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: primaryOrange),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            'No itinerary yet',
            Icons.event_busy,
            'Start planning your daily activities!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildDayCard(doc);
          },
        );
      },
    );
  }

  Widget _buildDayCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final day = data['day'] ?? 1;
    final title = data['title'] ?? 'Day $day';
    final completed = data['completed'] ?? false;
    final estimatedCost = data['estimatedDayCost'] ?? 0;
    final actualSpent = data['actualSpent'] ?? 0;
    final weather = data['weather'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: completed
            ? Border.all(color: Colors.green, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: completed
                ? Colors.green.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Day Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: completed
                    ? [Colors.green.shade400, Colors.green.shade600]
                    : [lightOrange, primaryOrange],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$day',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (weather != null)
                        Row(
                          children: [
                            Icon(
                              _getWeatherIcon(weather['condition']),
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${weather['temp']}°C • ${weather['condition']}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    completed ? Icons.check_circle : Icons.circle_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => _toggleDayCompletion(doc.id, completed),
                ),
              ],
            ),
          ),

          // Budget info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCostChip(
                      'Estimated',
                      estimatedCost,
                      primaryOrange,
                    ),
                    _buildCostChip(
                      'Spent',
                      actualSpent,
                      actualSpent > estimatedCost
                          ? Colors.red
                          : Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMiniMapPreview(data),
                const SizedBox(height: 12),
                _buildDayActivities(data),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostChip(String label, int amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${_formatAmount(amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ MINI MAP PREVIEW ------------------
  Widget _buildMiniMapPreview(Map<String, dynamic> data) {
    final locations = data['locations'] as List?;
    
    return GestureDetector(
      onTap: () => _showFullMap(data),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: palePeach,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryOrange.withOpacity(0.2)),
        ),
        child: Stack(
          children: [
            // Simulated map background
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade50,
                      Colors.blue.shade100,
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: _MapPatternPainter(),
                  child: Container(),
                ),
              ),
            ),
            
            // Location markers
            if (locations != null && locations.isNotEmpty)
              ...locations.asMap().entries.map((entry) {
                return Positioned(
                  left: 30.0 + (entry.key * 80.0),
                  top: 50.0 + (entry.key % 2 == 0 ? 0 : 30),
                  child: _buildMapMarker(entry.value['name'] ?? 'Location'),
                );
              }).toList(),

            // View full map overlay
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primaryOrange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryOrange.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'View Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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

  Widget _buildMapMarker(String name) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Icon(
          Icons.location_on,
          color: Colors.red,
          size: 24,
        ),
      ],
    );
  }

  // ------------------ DAY ACTIVITIES ------------------
  Widget _buildDayActivities(Map<String, dynamic> data) {
    final morning = data['morning'] as List?;
    final afternoon = data['afternoon'] as List?;
    final evening = data['evening'] as List?;

    return Column(
      children: [
        if (morning != null && morning.isNotEmpty)
          _buildTimeSection('Morning', morning, Icons.wb_sunny_outlined),
        if (afternoon != null && afternoon.isNotEmpty)
          _buildTimeSection('Afternoon', afternoon, Icons.wb_sunny),
        if (evening != null && evening.isNotEmpty)
          _buildTimeSection('Evening', evening, Icons.nightlight_outlined),
      ],
    );
  }

  Widget _buildTimeSection(String time, List activities, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palePeach,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: primaryOrange),
              const SizedBox(width: 8),
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...activities.map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: primaryOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activity['activity'] ?? activity.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ------------------ MAP TAB ------------------
  Widget _buildMapTab() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('savedTrips')
            .doc(widget.tripId)
            .collection('days')
            .orderBy('day')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: primaryOrange),
            );
          }

          return Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.blue.shade100],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomPaint(
                    painter: _MapPatternPainter(),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 80,
                            color: primaryOrange.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Interactive Map',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Full map integration coming soon!',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Locations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildLocationListItem(data);
                    }).toList(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLocationListItem(Map<String, dynamic> data) {
    final locations = data['locations'] as List?;
    if (locations == null || locations.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palePeach,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryOrange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${data['day']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryOrange,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: locations
                  .map((loc) => Text(
                        '• ${loc['name']}',
                        style: const TextStyle(fontSize: 13),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ WEATHER TAB ------------------
  Widget _buildWeatherTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('savedTrips')
          .doc(widget.tripId)
          .collection('days')
          .orderBy('day')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: primaryOrange),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildWeatherCard(data);
          },
        );
      },
    );
  }

  Widget _buildWeatherCard(Map<String, dynamic> data) {
    final day = data['day'] ?? 1;
    final weather = data['weather'] as Map<String, dynamic>?;
    
    if (weather == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Day $day - Weather data unavailable',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    final temp = weather['temp'] ?? 25;
    final condition = weather['condition'] ?? 'Clear';
    final humidity = weather['humidity'] ?? 60;
    final windSpeed = weather['windSpeed'] ?? 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: _getWeatherGradient(condition),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Day $day',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  _getWeatherIcon(condition),
                  color: Colors.white,
                  size: 40,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$temp°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      condition,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildWeatherDetail(
                      Icons.water_drop,
                      '$humidity%',
                      'Humidity',
                    ),
                    const SizedBox(height: 8),
                    _buildWeatherDetail(
                      Icons.air,
                      '${windSpeed}km/h',
                      'Wind',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------ EMPTY STATE ------------------
  Widget _buildEmptyState(String title, IconData icon, String subtitle) {
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
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ------------------ HELPER METHODS ------------------
  String _formatAmount(int amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toString();
  }

  IconData _getWeatherIcon(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny;
      case 'cloudy':
        return Icons.cloud;
      case 'rainy':
      case 'rain':
        return Icons.water_drop;
      case 'stormy':
        return Icons.thunderstorm;
      default:
        return Icons.wb_cloudy;
    }
  }

  LinearGradient _getWeatherGradient(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
        );
      case 'cloudy':
        return LinearGradient(
          colors: [Colors.grey.shade400, Colors.grey.shade600],
        );
      case 'rainy':
      case 'rain':
        return LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
        );
      case 'stormy':
        return LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade900],
        );
      default:
        return LinearGradient(
          colors: [lightOrange, primaryOrange],
        );
    }
  }

  Future<void> _toggleDayCompletion(String dayId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('savedTrips')
          .doc(widget.tripId)
          .collection('days')
          .doc(dayId)
          .update({'completed': !currentStatus});

      // Update stats
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('savedTrips')
          .doc(widget.tripId)
          .collection('days')
          .get();

      final completedCount =
          snapshot.docs.where((d) => d.data()['completed'] == true).length;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('savedTrips')
          .doc(widget.tripId)
          .update({'stats.completedDays': completedCount});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !currentStatus ? 'Day marked as complete! 🎉' : 'Day unmarked',
            ),
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
          const SnackBar(content: Text('Failed to update day status')),
        );
      }
    }
  }

  void _showFullMap(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Day ${data['day']} Map',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.blue.shade100],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Full map view - Integration pending'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareTrip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon!')),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionItem(Icons.edit, 'Edit Trip', () {}),
            _buildOptionItem(Icons.delete_outline, 'Delete Trip', () {}),
            _buildOptionItem(Icons.archive_outlined, 'Archive', () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: primaryOrange),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!')),
    );
  }
}

// ------------------ CUSTOM MAP PAINTER ------------------
class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade200.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw grid pattern
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw random paths to simulate roads
    final pathPaint = Paint()
      ..color = Colors.blue.shade300.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.2,
        size.width * 0.6,
        size.height * 0.4,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.5,
        size.width,
        size.height * 0.6,
      );

    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}