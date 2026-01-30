import 'package:flutter/material.dart';
import 'active_trip.dart';
import 'explore_home.dart';

enum TripStatus {
  loading,
  noTrip,
  activeTrip,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TripStatus _tripStatus = TripStatus.loading;

  @override
  void initState() {
    super.initState();
    _checkActiveTrip();
  }

  Future<void> _checkActiveTrip() async {
    setState(() => _tripStatus = TripStatus.loading);

    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    bool hasActiveTrip = false; // 🔹 Replace with real Firestore check

    setState(() {
      _tripStatus =
          hasActiveTrip ? TripStatus.activeTrip : TripStatus.noTrip;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_tripStatus) {
      case TripStatus.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case TripStatus.activeTrip:
        return const ActiveTripScreen();
      case TripStatus.noTrip:
      default:
        return const ExploreHomeScreen();
    }
  }
}
