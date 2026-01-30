import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountDetailsPage extends StatelessWidget {
  const AccountDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile image
            CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(
                user?.photoURL ??
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
              ),
            ),

            const SizedBox(height: 16),

            Text(
              user?.displayName ?? 'Roamly User',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              user?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 30),

            _accountTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () {},
            ),

            _accountTile(
              icon: Icons.lock_outline,
              title: 'Privacy & Security',
              onTap: () {},
            ),

            _accountTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {},
            ),

            const Spacer(),

            _accountTile(
              icon: Icons.logout,
              title: 'Logout',
              color: Colors.red,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountTile({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? Colors.black),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}
