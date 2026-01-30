import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading spinner while checking auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User logged in → HomeScreen
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // User not logged in → Onboarding
        return const OnboardingScreen();
      },
    );
  }
}
