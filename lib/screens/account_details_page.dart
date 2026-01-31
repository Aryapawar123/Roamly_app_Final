import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // User data
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  
  // Settings
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _locationEnabled = true;
  String _selectedLanguage = 'English (US)';
  String _selectedCurrency = 'USD (\$)';
  
  // Stats
  int _tripsCount = 0;
  int _placesCount = 0;
  int _pointsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSettings();
    _loadStats();
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user!.uid).get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data() ?? {};
            _isLoading = false;
          });
        } else {
          // Create initial user document if it doesn't exist
          await _createUserDocument();
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  // Create initial user document
  Future<void> _createUserDocument() async {
    try {
      final userData = {
        'displayName': user?.displayName ?? 'Roamly User',
        'email': user?.email ?? '',
        'photoURL': user?.photoURL ?? '',
        'bio': '',
        'phone': '',
        'location': '',
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false,
        'isPremium': false,
      };
      
      await _firestore.collection('users').doc(user!.uid).set(userData);
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _darkModeEnabled = prefs.getBool('darkMode') ?? false;
      _locationEnabled = prefs.getBool('location') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'English (US)';
      _selectedCurrency = prefs.getString('currency') ?? 'USD (\$)';
    });
  }

  // Load user statistics
  Future<void> _loadStats() async {
    try {
      if (user != null) {
        // Load trips count
        final tripsSnapshot = await _firestore
            .collection('users')
            .doc(user!.uid)
            .collection('trips')
            .get();
        
        // Load saved places count
        final placesSnapshot = await _firestore
            .collection('users')
            .doc(user!.uid)
            .collection('savedPlaces')
            .get();
        
        // Load points (you can calculate based on activities)
        final userDoc = await _firestore.collection('users').doc(user!.uid).get();
        
        setState(() {
          _tripsCount = tripsSnapshot.docs.length;
          _placesCount = placesSnapshot.docs.length;
          _pointsCount = userDoc.data()?['points'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with gradient
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color.fromARGB(255, 255, 100, 28),
                      const Color.fromARGB(255, 241, 181, 138),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Profile Image with edit button
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 52,
                              backgroundImage: _userData['photoURL'] != null && 
                                      _userData['photoURL'].toString().isNotEmpty
                                  ? NetworkImage(_userData['photoURL'])
                                  : const NetworkImage(
                                      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _editProfilePhoto,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userData['displayName'] ?? 'Roamly User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userData['email'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(_tripsCount.toString(), 'Trips'),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white30,
                          ),
                          _buildStatItem(_placesCount.toString(), 'Places'),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white30,
                          ),
                          _buildStatItem(
                            _pointsCount > 1000 
                                ? '${(_pointsCount / 1000).toStringAsFixed(1)}k'
                                : _pointsCount.toString(),
                            'Points'
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  _buildSectionHeader('Profile Settings'),
                  const SizedBox(height: 12),
                  _buildModernCard([
                    _buildMenuTile(
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      subtitle: 'Name, bio, and more',
                      onTap: _editProfile,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Verify Account',
                      subtitle: _userData['isVerified'] == true 
                          ? 'Account verified' 
                          : 'Get verified badge',
                      trailing: _userData['isVerified'] == true
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'New',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                      onTap: _handleVerifyAccount,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.interests_outlined,
                      title: 'Interests & Preferences',
                      subtitle: 'Travel style, activities',
                      onTap: _showInterestsDialog,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Travel Section
                  _buildSectionHeader('My Travels'),
                  const SizedBox(height: 12),
                  _buildModernCard([
                    _buildMenuTile(
                      icon: Icons.bookmark_outline,
                      title: 'Saved Places',
                      subtitle: '$_placesCount destinations',
                      onTap: _showSavedPlaces,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.history,
                      title: 'Travel History',
                      subtitle: 'View past trips',
                      onTap: _showTravelHistory,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.favorite_outline,
                      title: 'Wishlist',
                      subtitle: '${_userData['wishlistCount'] ?? 0} places to visit',
                      onTap: _showWishlist,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.star_outline,
                      title: 'Reviews & Ratings',
                      subtitle: '${_userData['reviewsCount'] ?? 0} reviews written',
                      onTap: _showReviews,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Settings Section
                  _buildSectionHeader('Settings'),
                  const SizedBox(height: 12),
                  _buildModernCard([
                    _buildSwitchTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Push notifications',
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      subtitle: 'App theme preference',
                      value: _darkModeEnabled,
                      onChanged: _toggleDarkMode,
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      icon: Icons.location_on_outlined,
                      title: 'Location Services',
                      subtitle: 'For better recommendations',
                      value: _locationEnabled,
                      onChanged: _toggleLocation,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: _selectedLanguage,
                      onTap: _changeLanguage,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.currency_exchange_outlined,
                      title: 'Currency',
                      subtitle: _selectedCurrency,
                      onTap: _changeCurrency,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Privacy & Security Section
                  _buildSectionHeader('Privacy & Security'),
                  const SizedBox(height: 12),
                  _buildModernCard([
                    _buildMenuTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      subtitle: 'Update your password',
                      onTap: _changePassword,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.security_outlined,
                      title: 'Two-Factor Authentication',
                      subtitle: _userData['twoFactorEnabled'] == true 
                          ? 'Enabled' 
                          : 'Add extra security',
                      onTap: _toggleTwoFactor,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Settings',
                      subtitle: 'Control your data',
                      onTap: _showPrivacySettings,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.block_outlined,
                      title: 'Blocked Users',
                      subtitle: 'Manage blocked accounts',
                      onTap: _showBlockedUsers,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Subscription Section
                  _buildSectionHeader('Subscription'),
                  const SizedBox(height: 12),
                  _buildPremiumCard(),
                  const SizedBox(height: 24),

                  // Support Section
                  _buildSectionHeader('Support & About'),
                  const SizedBox(height: 12),
                  _buildModernCard([
                    _buildMenuTile(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      subtitle: 'FAQs and support',
                      onTap: _showHelpCenter,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.feedback_outlined,
                      title: 'Send Feedback',
                      subtitle: 'We love to hear from you',
                      onTap: _sendFeedback,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.bug_report_outlined,
                      title: 'Report a Problem',
                      subtitle: 'Let us know issues',
                      onTap: _reportProblem,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.article_outlined,
                      title: 'Terms & Conditions',
                      subtitle: 'Legal information',
                      onTap: _showTerms,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.info_outline,
                      title: 'About Roamly',
                      subtitle: 'Version 2.5.0',
                      onTap: _showAbout,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Danger Zone
                  _buildSectionHeader('Account Actions'),
                  const SizedBox(height: 12),
                  _buildModernCard([
                    _buildMenuTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      titleColor: Colors.orange.shade700,
                      iconColor: Colors.orange.shade700,
                      onTap: _handleLogout,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.delete_outline,
                      title: 'Delete Account',
                      subtitle: 'Permanently delete account',
                      titleColor: Colors.red,
                      iconColor: Colors.red,
                      onTap: _handleDeleteAccount,
                    ),
                  ]),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI Building Methods
  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildModernCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? titleColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.blue.shade700,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: titleColor ?? Colors.grey.shade800,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.grey.shade400,
          ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.blue.shade700,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue.shade700,
      ),
    );
  }

  Widget _buildPremiumCard() {
    final isPremium = _userData['isPremium'] == true;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPremium
              ? [Colors.purple.shade400, Colors.deepPurple.shade600]
              : [Colors.amber.shade400, Colors.orange.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? Colors.purple : Colors.orange).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isPremium ? _managePremium : _upgradeToPremium,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPremium ? Icons.star : Icons.workspace_premium,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium ? 'Premium Active' : 'Upgrade to Premium',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPremium 
                            ? 'Manage your subscription'
                            : 'Unlock exclusive features & benefits',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Functional Methods

  // Profile Photo Management
  Future<void> _editProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),
            if (_userData['photoURL'] != null && 
                _userData['photoURL'].toString().isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _removeProfilePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // In a real app, you would upload to Firebase Storage
        // For now, we'll just use the local path
        // TODO: Implement Firebase Storage upload
        
        // Simulate upload delay
        await Future.delayed(const Duration(seconds: 2));
        
        // Update Firestore with new photo URL
        await _firestore.collection('users').doc(user!.uid).update({
          'photoURL': image.path, // In production, use Firebase Storage URL
        });

        setState(() {
          _userData['photoURL'] = image.path;
        });

        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _removeProfilePhoto() async {
    try {
      await _firestore.collection('users').doc(user!.uid).update({
        'photoURL': '',
      });

      setState(() {
        _userData['photoURL'] = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo removed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Edit Profile
  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _userData['displayName']);
    final bioController = TextEditingController(text: _userData['bio']);
    final phoneController = TextEditingController(text: _userData['phone']);
    final locationController = TextEditingController(text: _userData['location']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Update Firestore
                          try {
                            await _firestore.collection('users').doc(user!.uid).update({
                              'displayName': nameController.text,
                              'bio': bioController.text,
                              'phone': phoneController.text,
                              'location': locationController.text,
                            });

                            setState(() {
                              _userData['displayName'] = nameController.text;
                              _userData['bio'] = bioController.text;
                              _userData['phone'] = phoneController.text;
                              _userData['location'] = locationController.text;
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully!'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
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

  // Verify Account
  Future<void> _handleVerifyAccount() async {
    if (_userData['isVerified'] == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Account Verified'),
          content: const Text('Your account is already verified!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verify Account'),
        content: const Text(
          'To verify your account, please provide:\n\n'
          '• Valid government ID\n'
          '• Proof of address\n'
          '• Selfie with ID\n\n'
          'Verification usually takes 24-48 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Simulate verification process
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              await Future.delayed(const Duration(seconds: 2));
              
              await _firestore.collection('users').doc(user!.uid).update({
                'verificationRequested': true,
                'verificationDate': FieldValue.serverTimestamp(),
              });
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verification request submitted!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Interests Dialog
  Future<void> _showInterestsDialog() async {
    final interests = [
      'Adventure', 'Beach', 'Culture', 'Food', 'Nature',
      'Photography', 'Shopping', 'Sports', 'Wildlife', 'History'
    ];
    
    final selectedInterests = List<String>.from(
      _userData['interests'] ?? []
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select Interests'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.map((interest) {
                final isSelected = selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setDialogState(() {
                      if (selected) {
                        selectedInterests.add(interest);
                      } else {
                        selectedInterests.remove(interest);
                      }
                    });
                  },
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue.shade700,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _firestore.collection('users').doc(user!.uid).update({
                  'interests': selectedInterests,
                });
                
                setState(() {
                  _userData['interests'] = selectedInterests;
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Interests updated!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Travel Features
  Future<void> _showSavedPlaces() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Saved Places'),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(user!.uid)
                .collection('savedPlaces')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_outline, 
                        size: 64, 
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved places yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final place = snapshot.data!.docs[index].data() 
                      as Map<String, dynamic>;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(Icons.place, color: Colors.blue.shade700),
                      title: Text(place['name'] ?? 'Unknown Place'),
                      subtitle: Text(place['location'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await snapshot.data!.docs[index].reference.delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Place removed')),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showTravelHistory() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Travel History'),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(user!.uid)
                .collection('trips')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, 
                        size: 64, 
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No trips yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final trip = snapshot.data!.docs[index].data() 
                      as Map<String, dynamic>;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(Icons.flight, color: Colors.blue.shade700),
                      title: Text(trip['destination'] ?? 'Unknown'),
                      subtitle: Text(trip['date'] ?? ''),
                      trailing: Icon(Icons.chevron_right, 
                        color: Colors.grey.shade400,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showWishlist() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Wishlist'),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(user!.uid)
                .collection('wishlist')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_outline, 
                        size: 64, 
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your wishlist is empty',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data!.docs[index].data() 
                      as Map<String, dynamic>;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(Icons.favorite, color: Colors.red.shade400),
                      title: Text(item['name'] ?? 'Unknown'),
                      subtitle: Text(item['location'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await snapshot.data!.docs[index].reference.delete();
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showReviews() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('My Reviews'),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(user!.uid)
                .collection('reviews')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_outline, 
                        size: 64, 
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reviews yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final review = snapshot.data!.docs[index].data() 
                      as Map<String, dynamic>;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  review['placeName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < (review['rating'] ?? 0)
                                        ? Icons.star
                                        : Icons.star_outline,
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(review['comment'] ?? ''),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Settings Toggle Methods
  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    setState(() {
      _notificationsEnabled = value;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value 
          ? 'Notifications enabled' 
          : 'Notifications disabled'
        ),
      ),
    );
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    setState(() {
      _darkModeEnabled = value;
    });
    
    // In a real app, you would trigger theme change here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value 
          ? 'Dark mode enabled (restart app to apply)' 
          : 'Light mode enabled (restart app to apply)'
        ),
      ),
    );
  }

  Future<void> _toggleLocation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location', value);
    setState(() {
      _locationEnabled = value;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value 
          ? 'Location services enabled' 
          : 'Location services disabled'
        ),
      ),
    );
  }

  // Language Selection
  Future<void> _changeLanguage() async {
    final languages = [
      'English (US)',
      'English (UK)',
      'Spanish',
      'French',
      'German',
      'Italian',
      'Portuguese',
      'Japanese',
      'Chinese',
      'Hindi',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final language = languages[index];
              final isSelected = language == _selectedLanguage;
              
              return RadioListTile<String>(
                title: Text(language),
                value: language,
                groupValue: _selectedLanguage,
                activeColor: Colors.blue.shade700,
                onChanged: (value) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('language', value!);
                  
                  setState(() {
                    _selectedLanguage = value;
                  });
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Language changed to $value')),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Currency Selection
  Future<void> _changeCurrency() async {
    final currencies = [
      'USD (\$)',
      'EUR (€)',
      'GBP (£)',
      'JPY (¥)',
      'INR (₹)',
      'AUD (A\$)',
      'CAD (C\$)',
      'CNY (¥)',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              final currency = currencies[index];
              
              return RadioListTile<String>(
                title: Text(currency),
                value: currency,
                groupValue: _selectedCurrency,
                activeColor: Colors.blue.shade700,
                onChanged: (value) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('currency', value!);
                  
                  setState(() {
                    _selectedCurrency = value;
                  });
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Currency changed to $value')),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Security Features
  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                  ),
                );
                return;
              }

              try {
                // Re-authenticate user
                final credential = EmailAuthProvider.credential(
                  email: user!.email!,
                  password: currentPasswordController.text,
                );
                
                await user!.reauthenticateWithCredential(credential);
                
                // Update password
                await user!.updatePassword(newPasswordController.text);
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated successfully!')),
                );
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.message}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTwoFactor() async {
    final isEnabled = _userData['twoFactorEnabled'] == true;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEnabled 
          ? 'Disable Two-Factor Authentication' 
          : 'Enable Two-Factor Authentication'
        ),
        content: Text(isEnabled
          ? 'Are you sure you want to disable two-factor authentication? This will make your account less secure.'
          : 'Two-factor authentication adds an extra layer of security to your account. You\'ll need to verify your identity using a code sent to your phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('users').doc(user!.uid).update({
                'twoFactorEnabled': !isEnabled,
              });
              
              setState(() {
                _userData['twoFactorEnabled'] = !isEnabled;
              });
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEnabled 
                    ? '2FA disabled' 
                    : '2FA enabled successfully!'
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isEnabled ? 'Disable' : 'Enable',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPrivacySettings() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Privacy Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Profile Visibility'),
                subtitle: const Text('Make profile visible to others'),
                value: _userData['profilePublic'] ?? true,
                onChanged: (value) async {
                  await _firestore.collection('users').doc(user!.uid).update({
                    'profilePublic': value,
                  });
                  setState(() {
                    _userData['profilePublic'] = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Show Email'),
                subtitle: const Text('Display email on profile'),
                value: _userData['showEmail'] ?? false,
                onChanged: (value) async {
                  await _firestore.collection('users').doc(user!.uid).update({
                    'showEmail': value,
                  });
                  setState(() {
                    _userData['showEmail'] = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Show Phone'),
                subtitle: const Text('Display phone on profile'),
                value: _userData['showPhone'] ?? false,
                onChanged: (value) async {
                  await _firestore.collection('users').doc(user!.uid).update({
                    'showPhone': value,
                  });
                  setState(() {
                    _userData['showPhone'] = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Activity Status'),
                subtitle: const Text('Show when you\'re online'),
                value: _userData['showActivity'] ?? true,
                onChanged: (value) async {
                  await _firestore.collection('users').doc(user!.uid).update({
                    'showActivity': value,
                  });
                  setState(() {
                    _userData['showActivity'] = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBlockedUsers() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Blocked Users'),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(user!.uid)
                .collection('blockedUsers')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, 
                        size: 64, 
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No blocked users',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final blockedUser = snapshot.data!.docs[index].data() 
                      as Map<String, dynamic>;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          blockedUser['photoURL'] ?? 
                          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
                        ),
                      ),
                      title: Text(blockedUser['name'] ?? 'Unknown'),
                      trailing: TextButton(
                        onPressed: () async {
                          await snapshot.data!.docs[index].reference.delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User unblocked')),
                          );
                        },
                        child: const Text('Unblock'),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Premium Features
  Future<void> _upgradeToPremium() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            const Text('Premium Features'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unlock exclusive benefits:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _premiumFeature('Ad-free experience'),
            _premiumFeature('Unlimited saved places'),
            _premiumFeature('Advanced trip planning'),
            _premiumFeature('Priority customer support'),
            _premiumFeature('Exclusive travel guides'),
            _premiumFeature('Early access to new features'),
            const SizedBox(height: 16),
            const Text(
              '\$9.99/month or \$99/year',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Simulate payment process
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              await Future.delayed(const Duration(seconds: 2));
              
              await _firestore.collection('users').doc(user!.uid).update({
                'isPremium': true,
                'premiumSince': FieldValue.serverTimestamp(),
              });
              
              setState(() {
                _userData['isPremium'] = true;
              });
              
              Navigator.pop(context);
              
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Welcome to Premium! 🎉'),
                  content: const Text(
                    'You now have access to all premium features. Enjoy!',
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                      ),
                      child: const Text('Awesome!', 
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Upgrade Now', 
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _managePremium() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Manage Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Plan: Premium Monthly'),
            const SizedBox(height: 8),
            const Text('Next billing date: Feb 28, 2026'),
            const SizedBox(height: 8),
            const Text('Amount: \$9.99'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Subscription management coming soon'),
                  ),
                );
              },
              child: const Text('Change Plan'),
            ),
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cancel Subscription'),
                    content: const Text(
                      'Are you sure you want to cancel your premium subscription?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Yes, Cancel', 
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _firestore.collection('users').doc(user!.uid).update({
                    'isPremium': false,
                  });
                  
                  setState(() {
                    _userData['isPremium'] = false;
                  });
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subscription cancelled'),
                    ),
                  );
                }
              },
              child: const Text(
                'Cancel Subscription',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Support Features
  Future<void> _showHelpCenter() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Help Center'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _helpTile(
                'Getting Started',
                'Learn how to use Roamly',
                Icons.school_outlined,
              ),
              _helpTile(
                'Account & Settings',
                'Manage your account',
                Icons.settings_outlined,
              ),
              _helpTile(
                'Booking & Payments',
                'Payment and booking help',
                Icons.payment_outlined,
              ),
              _helpTile(
                'Safety & Security',
                'Stay safe while traveling',
                Icons.security_outlined,
              ),
              _helpTile(
                'Contact Support',
                'Get in touch with us',
                Icons.support_agent_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpTile(String title, String subtitle, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade700),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening $title...')),
          );
        },
      ),
    );
  }

  Future<void> _sendFeedback() async {
    final feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Send Feedback'),
        content: TextField(
          controller: feedbackController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Tell us what you think...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (feedbackController.text.isNotEmpty) {
                await _firestore.collection('feedback').add({
                  'userId': user!.uid,
                  'feedback': feedbackController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you for your feedback!'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _reportProblem() async {
    final problemController = TextEditingController();
    String selectedCategory = 'Technical Issue';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Report a Problem'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Technical Issue',
                    'Payment Problem',
                    'Account Issue',
                    'Bug Report',
                    'Other',
                  ].map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: problemController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Describe the problem...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (problemController.text.isNotEmpty) {
                  await _firestore.collection('problemReports').add({
                    'userId': user!.uid,
                    'category': selectedCategory,
                    'description': problemController.text,
                    'timestamp': FieldValue.serverTimestamp(),
                    'status': 'open',
                  });
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Problem reported. We\'ll look into it!'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTerms() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Terms & Conditions'),
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '1. Acceptance of Terms\n\n'
                  'By accessing and using Roamly, you accept and agree to be bound by the terms and provision of this agreement.\n\n'
                  '2. Use License\n\n'
                  'Permission is granted to temporarily use Roamly for personal, non-commercial transitory viewing only.\n\n'
                  '3. Privacy Policy\n\n'
                  'Your privacy is important to us. Please review our Privacy Policy to understand how we collect and use your information.\n\n'
                  '4. User Conduct\n\n'
                  'You agree not to use Roamly for any unlawful purpose or any purpose prohibited by these terms.\n\n'
                  '5. Modifications\n\n'
                  'Roamly reserves the right to modify these terms at any time. Continued use of the service constitutes acceptance of modified terms.',
                  style: TextStyle(height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAbout() async {
    showAboutDialog(
      context: context,
      applicationName: 'Roamly',
      applicationVersion: '2.5.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.travel_explore,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text(
          'Your ultimate travel companion for discovering amazing destinations worldwide.',
        ),
        const SizedBox(height: 16),
        const Text('© 2026 Roamly Inc. All rights reserved.'),
      ],
    );
  }

  // Account Actions
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final passwordController = TextEditingController();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action cannot be undone. All your data will be permanently deleted including:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('• Profile information'),
            const Text('• Travel history'),
            const Text('• Saved places'),
            const Text('• Reviews and ratings'),
            const Text('• All other personal data'),
            const SizedBox(height: 16),
            const Text('Please enter your password to confirm:'),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text.isNotEmpty) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your password')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // Re-authenticate user
        final credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: passwordController.text,
        );
        
        await user!.reauthenticateWithCredential(credential);
        
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user!.uid).delete();
        
        // Delete user account
        await user!.delete();
        
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }
}