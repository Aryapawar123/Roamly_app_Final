import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'expense_split_screen.dart';
// import 'add_memory_screen.dart';

class TripDetailScreen extends StatelessWidget {
  final String tripId;
  final String userId; // <-- Add this line

  const TripDetailScreen({
    Key? key,
    required this.tripId,
    required this.userId, // <-- Add this line
  }) : super(key: key);
  
  static const Color primaryOrange = Color(0xFFE8913A);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('savedTrips')
            .doc(tripId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final imageUrl = data['imageUrl'] ??
              'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee';

          final status = data['status'] ?? 'NOT_STARTED';
          final itinerary = data['itinerary']?['days'] ?? [];

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, imageUrl),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(data, status),
                      const SizedBox(height: 16),
                      _buildActionButtons(context, status),
                      const SizedBox(height: 24),
                      _buildProgress(itinerary),
                      const SizedBox(height: 24),
                      _buildItinerary(itinerary),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  // ---------------- APP BAR ----------------
  Widget _buildAppBar(BuildContext context, String imageUrl) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: primaryOrange,
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          imageUrl,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader(Map<String, dynamic> data, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data['destination'] ?? 'Trip',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _statusChip(status),
            const SizedBox(width: 10),
            Text(
              "Budget ₹${data['budget'] ?? 0}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'ONGOING':
        color = Colors.blue;
        break;
      case 'COMPLETED':
        color = Colors.green;
        break;
      default:
        color = Colors.orange;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color),
    );
  }

  // ---------------- ACTION BUTTONS ----------------
  Widget _buildActionButtons(BuildContext context, String status) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.receipt_long),
            label: const Text("Expenses"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExpenseSplitScreen(
              tripId: tripId,
            ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        if (status == 'ONGOING' || status == 'COMPLETED')
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text("Add Memories"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: primaryOrange,
              ),
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) => AddMemoryScreen(tripId: tripId),
                //   ),
                // );
              },
            ),
          ),
      ],
    );
  }

  // ---------------- PROGRESS ----------------
  Widget _buildProgress(List days) {
    if (days.isEmpty) return const SizedBox();

    final completed =
        days.where((d) => d['completed'] == true).length;
    final progress = completed / days.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Trip Progress",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          backgroundColor: Colors.grey.shade300,
          color: primaryOrange,
        ),
        const SizedBox(height: 6),
        Text("${(progress * 100).toInt()}% completed"),
      ],
    );
  }

  // ---------------- ITINERARY ----------------
  Widget _buildItinerary(List days) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Itinerary",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...days.map((day) => _dayCard(day)).toList(),
      ],
    );
  }

  Widget _dayCard(Map<String, dynamic> day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Day ${day['day']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (day['completed'] == true)
                const Icon(Icons.check_circle, color: Colors.green)
            ],
          ),
          const SizedBox(height: 6),
          Text(
            day['title'] ?? '',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          _section("Morning", day['morning']),
          _section("Afternoon", day['afternoon']),
          _section("Evening", day['evening']),
        ],
      ),
    );
  }

  Widget _section(String title, List? items) {
    if (items == null || items.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...items.map(
            (i) => Text("• ${i['activity']}"),
          ),
        ],
      ),
    );
  }
}
