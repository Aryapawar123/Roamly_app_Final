import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🔹 Import your pages
import 'edit_profile_page.dart';
import 'privacy_security_page.dart';
import 'help_support_page.dart';

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
            // 👤 Profile Image
            CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(
                user?.photoURL ??
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
              ),
            ),

            const SizedBox(height: 16),

            // 👤 Name
            Text(
              user?.displayName ?? 'Roamly User',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            // 📧 Email
            Text(
              user?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 30),

            // ✏️ Edit Profile
            _accountTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditProfilePage(),
                  ),
                );
              },
            ),

            // 🔐 Privacy & Security
            _accountTile(
              icon: Icons.lock_outline,
              title: 'Privacy & Security',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacySecurityPage(),
                  ),
                );
              },
            ),

            // ❓ Help & Support
            _accountTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HelpSupportPage(),
                  ),
                );
              },
            ),

            const Spacer(),

            // 🚪 Logout
            _accountTile(
              icon: Icons.logout,
              title: 'Logout',
              color: Colors.red,
              onTap: () async {
                await FirebaseAuth.instance.signOut();

                // AuthGate will automatically redirect
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Reusable tile widget
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
