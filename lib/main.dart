import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forgetpassword_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const WanderWiseApp());
}

class WanderWiseApp extends StatelessWidget {
  const WanderWiseApp({super.key});

@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'WanderWise',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35)),
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
    ),

    // 👇 IMPORTANT PART
    initialRoute: '/',
    routes: {
      '/': (context) => const OnboardingScreen(),
      '/login': (context) => LoginScreen(),
      '/signup': (context) => SignupScreen(),
      '/home': (context) => HomeScreen(), // or your dashboard
    },
  );
}
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: const [
                  OnboardingPage1(),
                  OnboardingPage2(),
                  OnboardingPage3(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 10 : 8,
                        height: _currentPage == index ? 10 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? const Color(0xFF1E3A5F)
                              : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                          }

                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ PAGE 1: Your Journey, Perfectly Planned ============
class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Logo
          const WanderWiseLogo(),
          const SizedBox(height: 24),
          // Trip Planning Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile and Trip Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side - Avatar and trip info
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar with calendar badges
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const CircleAvatar(
                                  radius: 28,
                                  backgroundImage: NetworkImage(
                                    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
                                  ),
                                ),
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E3A5F),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '12',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -8,
                                  right: -28,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A90D9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '4',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Kuala Lumpur - Ipoh',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Malaysia',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Budget: \$1,200',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Sunset avatar
                            const CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(
                                'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=100',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right side - Destination list
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildDestinationItem(
                              '🇲🇾',
                              'Kuala Lumpur',
                              '5 Days, 24 Dec 2024',
                            ),
                            _buildDestinationItem(
                              '🇯🇵',
                              'Tokyo',
                              '14 Days, 1 Jan 2025',
                            ),
                            _buildDestinationItem(
                              '🇹🇭',
                              'Bangkok',
                              '8 Days, 4 Mar 2025',
                            ),
                            _buildDestinationItem(
                              '🇻🇳',
                              'Hanoi',
                              '8 Days, 19 Jul 2025',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          const Text(
            'Your Journey,\nPerfectly Planned',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Effortlessly create and organize your\ndream trips. Start exploring now!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDestinationItem(String flag, String city, String details) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(flag, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============ PAGE 2: Discover Friends Nearby ============
class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const WanderWiseLogo(),
          const SizedBox(height: 24),
          // World Map Container
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // World map placeholder (dotted pattern)
                  Center(
                    child: CustomPaint(
                      size: const Size(double.infinity, 200),
                      painter: WorldMapPainter(),
                    ),
                  ),
                  // Friend markers
                  Positioned(
                    top: 40,
                    left: 80,
                    child: _buildFriendMarker(
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
                      hasPhotos: true,
                    ),
                  ),
                  Positioned(
                    top: 80,
                    right: 60,
                    child: _buildFriendMarker(
                      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
                    ),
                  ),
                  // Currently in badge
                  Positioned(
                    bottom: 40,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            backgroundImage: NetworkImage(
                              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
                            ),
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 12, color: Colors.black),
                              children: [
                                TextSpan(text: 'Currently in '),
                                TextSpan(
                                  text: 'Syd, Aus!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF6B35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Discover\nFriends Nearby',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'See where your friends are traveling and\nexplore the world together.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFriendMarker(String imageUrl, {bool hasPhotos = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(imageUrl),
          ),
        ),
        if (hasPhotos)
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 40,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=100',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============ PAGE 3: Stay Updated with Top Places ============
class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const WanderWiseLogo(),
          const SizedBox(height: 24),
          // Places Cards Container
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildPlaceCard(
                    'Old Quarter Hanoi',
                    'The Old Quarter is the name co...',
                    4.8,
                    80,
                    'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=200',
                    price: '\$1,200',
                  ),
                  const SizedBox(height: 12),
                  _buildPlaceCard(
                    'Central Market - KL',
                    'A vibrant cultural landmark offe...',
                    4.5,
                    47,
                    'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=200',
                    isFavorite: true,
                  ),
                  const SizedBox(height: 12),
                  _buildPlaceCard(
                    'Fansipan Legend, Sapa',
                    'The Old Quarter is the name co...',
                    4.8,
                    80,
                    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=200',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Stay Updated\nwith Top Places',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Find trending destinations and must-see attractions,\nall tailored to enhance your travel plans.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(
    String title,
    String description,
    double rating,
    int reviews,
    String imageUrl, {
    String? price,
    bool isFavorite = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFFFFB800),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$rating ($reviews)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              if (price != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    price,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.bookmark_border,
                    color: Colors.grey,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============ SHARED WIDGETS ============

class WanderWiseLogo extends StatelessWidget {
  const WanderWiseLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.network(
          'https://img.icons8.com/color/48/bird.png',
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 8),
        const Text(
          'WanderWise',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Text(
          '.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFF6B35),
          ),
        ),
      ],
    );
  }
}

// World Map Painter for dotted world map effect
class WorldMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    // Draw dots to simulate world map
    const spacing = 12.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Create a rough world map shape with dots
        if (_isLandArea(x / size.width, y / size.height)) {
          canvas.drawCircle(Offset(x, y), 2, paint);
        }
      }
    }
  }

  bool _isLandArea(double x, double y) {
    // Simplified world map regions
    // North America
    if (x > 0.1 && x < 0.35 && y > 0.15 && y < 0.45) return true;
    // South America
    if (x > 0.2 && x < 0.35 && y > 0.5 && y < 0.85) return true;
    // Europe
    if (x > 0.4 && x < 0.55 && y > 0.15 && y < 0.35) return true;
    // Africa
    if (x > 0.4 && x < 0.55 && y > 0.35 && y < 0.7) return true;
    // Asia
    if (x > 0.55 && x < 0.9 && y > 0.15 && y < 0.5) return true;
    // Australia
    if (x > 0.75 && x < 0.9 && y > 0.6 && y < 0.8) return true;
    return false;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}