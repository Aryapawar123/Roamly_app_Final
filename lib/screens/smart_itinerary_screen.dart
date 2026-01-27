import 'package:flutter/material.dart';

// Roamly Theme Colors
const Color primaryOrange = Color(0xFFE8913A);
const Color lightOrange = Color(0xFFFFF4E6);
const Color darkText = Color(0xFF1A1A1A);
const Color grayText = Color(0xFF6B7280);
const Color lightGray = Color(0xFFF5F5F5);
const Color warningRed = Color(0xFFE8913A);

class SmartItineraryScreen extends StatefulWidget {
  const SmartItineraryScreen({super.key});

  @override
  State<SmartItineraryScreen> createState() => _SmartItineraryScreenState();
}

class _SmartItineraryScreenState extends State<SmartItineraryScreen> {
  int selectedDay = 0;

  final List<Map<String, dynamic>> days = [
    {'label': 'Day 1', 'date': 'DEC 14, 2024'},
    {'label': 'Day 2', 'date': 'DEC 15, 2024'},
    {'label': 'Day 3', 'date': 'DEC 16, 2024'},
    {'label': 'Day 4', 'date': 'DEC 17, 2024'},
  ];

  final List<List<Map<String, dynamic>>> schedules = [
    // Day 1
    [
      {
        'name': 'Amber Fort',
        'time': '10:00 AM',
        'duration': '3 hours',
        'icon': Icons.account_balance,
        'isMustVisit': true,
        'isRunningLate': false,
      },
      {
        'name': 'Chokhi Dhani',
        'time': '01:30 PM',
        'duration': 'Lunch',
        'icon': Icons.restaurant,
        'isMustVisit': false,
        'isRunningLate': false,
      },
      {
        'name': 'Hawa Mahal',
        'time': '03:30 PM',
        'duration': 'Photo',
        'icon': Icons.camera_alt_outlined,
        'isMustVisit': true,
        'isRunningLate': true,
      },
    ],
    // Day 2
    [
      {
        'name': 'City Palace',
        'time': '09:00 AM',
        'duration': '2 hours',
        'icon': Icons.account_balance,
        'isMustVisit': true,
        'isRunningLate': false,
      },
      {
        'name': 'Jantar Mantar',
        'time': '12:00 PM',
        'duration': '1.5 hours',
        'icon': Icons.explore,
        'isMustVisit': false,
        'isRunningLate': false,
      },
    ],
    // Day 3
    [
      {
        'name': 'Nahargarh Fort',
        'time': '08:00 AM',
        'duration': '4 hours',
        'icon': Icons.terrain,
        'isMustVisit': true,
        'isRunningLate': false,
      },
    ],
    // Day 4
    [
      {
        'name': 'Shopping at Johari Bazaar',
        'time': '10:00 AM',
        'duration': '3 hours',
        'icon': Icons.shopping_bag,
        'isMustVisit': false,
        'isRunningLate': false,
      },
      {
        'name': 'Departure',
        'time': '04:00 PM',
        'duration': 'Airport',
        'icon': Icons.flight_takeoff,
        'isMustVisit': false,
        'isRunningLate': false,
      },
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: darkText),
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Smart Itinerary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'JAIPUR, INDIA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryOrange,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      color: darkText,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Map Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: lightGray,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // Map placeholder with actual map style
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F1EB),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: CustomPaint(
                                size: const Size(double.infinity, 220),
                                painter: MapPlaceholderPainter(),
                              ),
                            ),
                            // Map markers
                            Positioned(
                              top: 60,
                              left: 80,
                              child: _buildMapMarker(Icons.account_balance),
                            ),
                            Positioned(
                              top: 100,
                              left: 180,
                              child: _buildMapMarker(Icons.restaurant),
                            ),
                            Positioned(
                              top: 140,
                              right: 100,
                              child: _buildMapMarker(Icons.location_on, isMain: true),
                            ),
                            // Current location button
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: primaryOrange, width: 2),
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  color: primaryOrange,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Day Selector
                    SizedBox(
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: days.length,
                        itemBuilder: (context, index) {
                          final isSelected = selectedDay == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedDay = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryOrange : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryOrange
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                days[index]['label'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : grayText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Today's Schedule Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Schedule Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Today's Schedule",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                ),
                              ),
                              Text(
                                days[selectedDay]['date'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: grayText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Timeline
                          ...schedules[selectedDay].asMap().entries.map((entry) {
                            final index = entry.key;
                            final activity = entry.value;
                            final isLast =
                                index == schedules[selectedDay].length - 1;

                            return _buildTimelineItem(
                              icon: activity['icon'],
                              name: activity['name'],
                              time: activity['time'],
                              duration: activity['duration'],
                              isMustVisit: activity['isMustVisit'],
                              isRunningLate: activity['isRunningLate'],
                              isLast: isLast,
                            );
                          }),

                          const SizedBox(height: 16),

                          // Stayed Longer Button
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: lightOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: primaryOrange,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Stayed Longer',
                                  style: TextStyle(
                                    color: primaryOrange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Share Trip Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Share trip logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Share Trip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapMarker(IconData icon, {bool isMain = false}) {
    if (isMain) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryOrange,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryOrange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: primaryOrange,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String name,
    required String time,
    required String duration,
    required bool isMustVisit,
    required bool isRunningLate,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: lightOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: primaryOrange,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: CustomPaint(
                  painter: DashedLinePainter(),
                ),
              ),
          ],
        ),

        const SizedBox(width: 12),

        // Activity Card
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    if (isMustVisit)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: lightOrange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'MUST-VISIT',
                          style: TextStyle(
                            color: primaryOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: grayText,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      ' • ',
                      style: TextStyle(color: grayText),
                    ),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: grayText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (isRunningLate) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: lightOrange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          color: primaryOrange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Running Late',
                          style: TextStyle(
                            color: primaryOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Dashed Line Painter for Timeline
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 5.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Map Placeholder Painter
class MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw grid lines to simulate map
    for (int i = 0; i < size.width; i += 30) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
    for (int i = 0; i < size.height; i += 30) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }

    // Draw some road-like lines
    final roadPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.4);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.7,
      size.width,
      size.height * 0.6,
    );
    canvas.drawPath(path, roadPaint);

    // Draw dashed route line
    final routePaint = Paint()
      ..color = primaryOrange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashPath = Path();
    dashPath.moveTo(80, 70);
    dashPath.lineTo(180, 110);
    dashPath.lineTo(size.width - 100, 150);

    _drawDashedPath(canvas, dashPath, routePaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + 8).clamp(0, metric.length);
        final extractPath = metric.extractPath(start, end.toDouble());
        canvas.drawPath(extractPath, paint);
        distance += 16;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
