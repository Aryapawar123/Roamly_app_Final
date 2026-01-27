import 'package:flutter/material.dart';

// Main color constants matching Roamly theme
const Color primaryOrange = Color(0xFFE8913A);
const Color lightOrange = Color(0xFFFFF4E6);
const Color textDark = Color(0xFF1A1A1A);
const Color textGray = Color(0xFF6B7280);
const Color backgroundColor = Color(0xFFFAF7F2);
const Color redAmount = Color(0xFFDC3545);
const Color greenAmount = Color(0xFF28A745);

class ExpenseSplitScreen extends StatefulWidget {
  const ExpenseSplitScreen({super.key});

  @override
  State<ExpenseSplitScreen> createState() => _ExpenseSplitScreenState();
}

class _ExpenseSplitScreenState extends State<ExpenseSplitScreen> {
  int _selectedNavIndex = 1; // Expenses tab active

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Back button in circle
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: textDark, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Expense Split',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const Spacer(),
                  // Settle Up button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryOrange),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Settle Up',
                      style: TextStyle(
                        color: primaryOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trip Balance Card
                    _buildTripBalanceCard(),
                    const SizedBox(height: 24),

                    // Recent Expenses Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Expenses',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune, color: textGray),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Expense List
                    _buildExpenseCard(
                      icon: Icons.restaurant,
                      iconColor: primaryOrange,
                      iconBgColor: lightOrange,
                      title: 'Lunch at local dhaba',
                      amount: '₹850',
                      payer: 'YOU PAID',
                      date: 'OCT 12',
                      isYou: true,
                    ),
                    const SizedBox(height: 12),
                    _buildExpenseCard(
                      icon: Icons.directions_car,
                      iconColor: const Color(0xFF3B82F6),
                      iconBgColor: const Color(0xFFDBEAFE),
                      title: 'Rickshaw to Hawa Mahal',
                      amount: '₹120',
                      payer: 'PAID BY RAHUL',
                      date: 'OCT 12',
                      isYou: false,
                    ),
                    const SizedBox(height: 12),
                    _buildExpenseCard(
                      icon: Icons.home_work,
                      iconColor: const Color(0xFF8B5CF6),
                      iconBgColor: const Color(0xFFEDE9FE),
                      title: 'City Palace Tickets',
                      amount: '₹1,500',
                      payer: 'PAID BY AMIT',
                      date: 'OCT 11',
                      isYou: false,
                      hasM: true,
                    ),
                    const SizedBox(height: 12),
                    _buildExpenseCard(
                      icon: Icons.shopping_bag,
                      iconColor: const Color(0xFF22C55E),
                      iconBgColor: const Color(0xFFDCFCE7),
                      title: 'Souvenirs at Bapu Bazaar',
                      amount: '₹350',
                      payer: 'YOU PAID',
                      date: 'OCT 11',
                      isYou: true,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTripBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRIP BALANCE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textGray.withOpacity(0.8),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Jaipur Getaway',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              // Trip image
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lightOrange,
                  border: Border.all(color: primaryOrange.withOpacity(0.3), width: 2),
                ),
                child: ClipOval(
                  child: CustomPaint(
                    size: const Size(64, 64),
                    painter: HawaMahalPainter(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You owe',
                      style: TextStyle(
                        fontSize: 14,
                        color: textGray.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '₹1,200',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: redAmount,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: const Color(0xFFE5E7EB),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You receive',
                        style: TextStyle(
                          fontSize: 14,
                          color: textGray.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '₹450',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: greenAmount,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String amount,
    required String payer,
    required String date,
    required bool isYou,
    bool hasM = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: hasM
                ? Center(
                    child: Text(
                      'M',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                  )
                : Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Payer avatar
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isYou ? lightOrange : Colors.grey.shade200,
                        border: Border.all(
                          color: isYou ? primaryOrange.withOpacity(0.3) : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 14,
                        color: isYou ? primaryOrange : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$payer • $date',
                      style: const TextStyle(
                        fontSize: 12,
                        color: textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Amount
          Text(
            amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.explore_outlined, 'Explore', 0),
          _buildNavItem(Icons.receipt_long, 'Expenses', 1),
          _buildNavItem(Icons.people_outline, 'Group', 2),
          _buildNavItem(Icons.person_outline, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? primaryOrange : textGray,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? primaryOrange : textGray,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for Hawa Mahal illustration
class HawaMahalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryOrange.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Simple building silhouette
    final path = Path();
    
    // Main building shape
    path.moveTo(size.width * 0.2, size.height * 0.8);
    path.lineTo(size.width * 0.2, size.height * 0.4);
    path.lineTo(size.width * 0.3, size.height * 0.3);
    path.lineTo(size.width * 0.35, size.height * 0.4);
    path.lineTo(size.width * 0.35, size.height * 0.35);
    path.lineTo(size.width * 0.45, size.height * 0.25);
    path.lineTo(size.width * 0.5, size.height * 0.2);
    path.lineTo(size.width * 0.55, size.height * 0.25);
    path.lineTo(size.width * 0.65, size.height * 0.35);
    path.lineTo(size.width * 0.65, size.height * 0.4);
    path.lineTo(size.width * 0.7, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width * 0.8, size.height * 0.8);
    path.close();

    canvas.drawPath(path, paint);

    // Windows
    final windowPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        canvas.drawRect(
          Rect.fromLTWH(
            size.width * 0.3 + col * 12,
            size.height * 0.45 + row * 10,
            6,
            6,
          ),
          windowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
