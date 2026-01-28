// main.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;



class GoaDetailScreen extends StatelessWidget {
  const GoaDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeaderIllustration(context),
                _buildContentCard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
          _buildTopButtons(context),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopButtons(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: Color(0xFF636E72),
                ),
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_horiz,
                size: 20,
                color: Color(0xFF636E72),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildHeaderIllustration(BuildContext context) {
  return Container(
    height: 300,
    width: double.infinity,
    decoration: BoxDecoration(
      image: const DecorationImage(
        image: NetworkImage(
          'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=400&h=500&fit=crop',
        ), // Goa / beach vibe
        fit: BoxFit.cover,
      ),
    ),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.35),
            Colors.black.withOpacity(0.05),
            Colors.transparent,
          ],
        ),
      ),
    ),
  );
}


  Widget _buildCloud(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(height),
      ),
    );
  }

  Widget _buildRoundedTree(double size, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size * 0.9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size / 2),
          ),
        ),
        Container(
          width: size * 0.15,
          height: size * 0.35,
          decoration: BoxDecoration(
            color: const Color(0xFF8D6E63),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildPineTree(double height) {
    return SizedBox(
      width: height * 0.6,
      height: height,
      child: CustomPaint(
        painter: PineTreePainter(),
      ),
    );
  }

  Widget _buildContentCard() {
    return Container(
      transform: Matrix4.translationValues(0, -30, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlaceHeader(),
          const Divider(height: 1, indent: 24, endIndent: 24),
          _buildAboutSection(),
          _buildInfoCards(),
        ],
      ),
    );
  }

  Widget _buildPlaceHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Yogyakarta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(0xFFFFB347),
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '4.5 ratings',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 1,
                height: 45,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.only(right: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'IDR 250K',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '/Person',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About the place',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Jogjakarta is a fun and special city in Indonesia! People also call it "Jogja."',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            _buildInfoCard(
              icon: Icons.access_time_rounded,
              label: 'Duration',
              value: '14 Days',
              bgColor: const Color(0xFFE3F2FD),
              iconBgColor: const Color(0xFFBBDEFB),
              iconColor: const Color(0xFF64B5F6),
            ),
            const SizedBox(width: 12),
            _buildInfoCard(
              icon: Icons.people_outline_rounded,
              label: 'Capacity',
              value: '12 People',
              bgColor: const Color(0xFFFFF3E0),
              iconBgColor: const Color(0xFFFFE0B2),
              iconColor: const Color(0xFFFFB74D),
            ),
            const SizedBox(width: 12),
            _buildInfoCard(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: 'Jogjakarta',
              bgColor: const Color(0xFFE8F5E9),
              iconBgColor: const Color(0xFFC8E6C9),
              iconColor: const Color(0xFF81C784),
            ),
            const SizedBox(width: 12),
            _buildInfoCard(
              icon: Icons.wb_sunny_outlined,
              label: 'Weather',
              value: '28°C',
              bgColor: const Color(0xFFFCE4EC),
              iconBgColor: const Color(0xFFF8BBD9),
              iconColor: const Color(0xFFF06292),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color bgColor,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      width: 85,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Color(0xFF2D3436),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF26A69A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'More Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sun painter with rays
class SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw sun circle
    final sunPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 22, sunPaint);

    // Draw rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFFB74D)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const rayCount = 12;
    const innerRadius = 28.0;
    const outerRadius = 40.0;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 360 / rayCount) * math.pi / 180;
      final start = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      canvas.drawLine(start, end, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Back mountains painter (blue/teal mountains)
class BackMountainsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4DB6AC)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.7)
      ..lineTo(size.width * 0.15, size.height * 0.3)
      ..lineTo(size.width * 0.28, size.height * 0.55)
      ..lineTo(size.width * 0.45, size.height * 0.15)
      ..lineTo(size.width * 0.6, size.height * 0.45)
      ..lineTo(size.width * 0.75, size.height * 0.2)
      ..lineTo(size.width * 0.9, size.height * 0.4)
      ..lineTo(size.width, size.height * 0.25)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Front hills painter (green rolling hills)
class FrontHillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8BC34A)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.15, size.height * 0.2,
        size.width * 0.3, size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.45, size.height * 0.8,
        size.width * 0.6, size.height * 0.4,
      )
      ..quadraticBezierTo(
        size.width * 0.8, size.height * 0.0,
        size.width, size.height * 0.3,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);

    // Add lighter green overlay for depth
    final lightPaint = Paint()
      ..color = const Color(0xFFA5D6A7)
      ..style = PaintingStyle.fill;

    final lightPath = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
        size.width * 0.25, size.height * 0.5,
        size.width * 0.5, size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.75, size.height * 0.9,
        size.width, size.height * 0.6,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(lightPath, lightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Pine tree painter
class PineTreePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final treePaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;

    final trunkPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.fill;

    // Draw trunk
    final trunkRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height - 8),
      width: size.width * 0.12,
      height: size.height * 0.2,
    );
    canvas.drawRect(trunkRect, trunkPaint);

    // Draw three triangle layers
    for (int i = 0; i < 3; i++) {
      final layerHeight = size.height * 0.35;
      final layerWidth = size.width * (1 - i * 0.12);
      final yOffset = i * layerHeight * 0.4;

      final path = Path()
        ..moveTo(size.width / 2, yOffset)
        ..lineTo(size.width / 2 - layerWidth / 2, yOffset + layerHeight)
        ..lineTo(size.width / 2 + layerWidth / 2, yOffset + layerHeight)
        ..close();

      canvas.drawPath(path, treePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}