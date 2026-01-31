import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'trip_detail_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  int selectedTab = 0;

  final tabs = const ['Upcoming', 'Ongoing', 'Completed'];

  late String userId; // ✅ FIX HERE

  static const primaryColor = Color(0xFFE8913A);

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid; // ✅ SAFE INIT
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('My Trips'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(child: _buildTrips()),
        ],
      ),
    );
  }

  // ------------------ TABS ------------------
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = selectedTab == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedTab = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    tabs[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ------------------ FIRESTORE ------------------
  Widget _buildTrips() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedTrips')
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No trips found'));
        }

        final trips = snapshot.data!.docs
            .where((doc) => _filterByStatus(doc['status']))
            .toList();

        if (trips.isEmpty) {
          return const Center(child: Text('Nothing here yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: trips.length,
          itemBuilder: (_, i) => _tripCard(trips[i]),
        );
      },
    );
  }

  bool _filterByStatus(String status) {
    if (selectedTab == 0) return status == 'NOT_STARTED';
    if (selectedTab == 1) return status == 'IN_PROGRESS';
    return status == 'COMPLETED';
  }

  // ------------------ TRIP CARD ------------------
  Widget _tripCard(QueryDocumentSnapshot trip) {
    final List days = trip['days'] ?? [];
    final completedDays =
        days.where((d) => d['completed'] == true).length;

    final progress = days.isEmpty ? 0.0 : completedDays / days.length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TripDetailScreen(
              tripId: trip.id,
              userId: userId, // ✅ NOW WORKS
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER IMAGE (SAFE FALLBACK)
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                image: DecorationImage(
                  image: NetworkImage(
                    trip.data().toString().contains('coverImage')
                        ? trip['coverImage']
                        : 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        trip['destination'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _statusChip(trip['status']),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Budget: ₹${trip['budget']}",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  if (trip['status'] != 'NOT_STARTED') ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      color: primaryColor,
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Day $completedDays of ${days.length} completed",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'IN_PROGRESS':
        color = Colors.blue;
        label = 'Ongoing';
        break;
      case 'COMPLETED':
        color = Colors.green;
        label = 'Completed';
        break;
      default:
        color = Colors.orange;
        label = 'Upcoming';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}
