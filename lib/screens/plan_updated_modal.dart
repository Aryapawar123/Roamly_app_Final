import 'package:flutter/material.dart';

// Primary orange color used throughout the app
const Color primaryOrange = Color(0xFFE8913A);
const Color lightOrange = Color(0xFFFFF4EB);

/// Shows the Plan Updated bottom sheet modal
/// 
/// Usage:
/// ```dart
/// showPlanUpdatedModal(context);
/// ```
void showPlanUpdatedModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const PlanUpdatedModal(),
  );
}

class PlanUpdatedModal extends StatelessWidget {
  const PlanUpdatedModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Illustration container
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: lightOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Main illustration - person with checkmark
                const _PlanUpdatedIllustration(),
                
                const SizedBox(height: 24),
                
                // Route diagram
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Location pin
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    
                    // Connecting line
                    Container(
                      width: 40,
                      height: 2,
                      color: Colors.grey[400],
                    ),
                    
                    // Route marker
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Icon(
                        Icons.route_outlined,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Plan Updated',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Roamly AI has adjusted your schedule for a smoother day.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Status items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _StatusItem(
                  icon: Icons.access_time,
                  iconColor: primaryOrange,
                  iconBgColor: lightOrange,
                  title: 'Delay detected',
                ),
                const SizedBox(height: 12),
                _StatusItem(
                  icon: Icons.map_outlined,
                  iconColor: const Color(0xFF4A90D9),
                  iconBgColor: const Color(0xFFE8F4FD),
                  title: 'Itinerary recalculated',
                ),
                const SizedBox(height: 12),
                _StatusItem(
                  icon: Icons.check,
                  iconColor: const Color(0xFF34C759),
                  iconBgColor: const Color(0xFFE8F8ED),
                  title: 'End time preserved',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Got it button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // View Full Itinerary button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to full itinerary
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryOrange,
                  side: const BorderSide(color: primaryOrange, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'View Full Itinerary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }
}

class _PlanUpdatedIllustration extends StatelessWidget {
  const _PlanUpdatedIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Person icon
          Icon(
            Icons.person,
            size: 64,
            color: primaryOrange,
          ),
          // Checkmark with building
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: primaryOrange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.apartment,
                    size: 14,
                    color: Colors.orange[200],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;

  const _StatusItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(10),
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
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          
          // Arrow
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
            size: 24,
          ),
        ],
      ),
    );
  }
}


// Demo screen showing how to use the modal
class PlanUpdatedDemoScreen extends StatelessWidget {
  const PlanUpdatedDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Simulated map background
          Container(
            color: const Color(0xFFE8E4D8),
            child: CustomPaint(
              painter: _MapBackgroundPainter(),
              size: Size.infinite,
            ),
          ),
          
          // Map labels
          Positioned(
            top: 100,
            left: 40,
            child: Text(
              'VISHWAKARMA\nINDUSTRIAL AREA',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            top: 150,
            right: 40,
            child: Text(
              'Amber Fort',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            top: 180,
            left: 30,
            child: Text(
              'Temple',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
          Positioned(
            top: 220,
            left: 60,
            child: Text(
              'MURLIPURA',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
          Positioned(
            bottom: 350,
            right: 50,
            child: Text(
              'Papad wale Hanuman',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          // Map markers
          Positioned(
            top: 140,
            left: 100,
            child: _MapMarker(icon: Icons.place),
          ),
          Positioned(
            top: 180,
            right: 120,
            child: _MapMarker(icon: Icons.place),
          ),
          
          // Center button to show modal
          Center(
            child: ElevatedButton(
              onPressed: () => showPlanUpdatedModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Show Plan Updated'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final IconData icon;
  
  const _MapMarker({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[500],
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}

class _MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw some road lines
    final path1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.25);
    canvas.drawPath(path1, roadPaint);

    final path2 = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.3, size.height);
    canvas.drawPath(path2, roadPaint);

    final path3 = Path()
      ..moveTo(size.width * 0.6, 0)
      ..lineTo(size.width * 0.7, size.height * 0.5);
    canvas.drawPath(path3, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
