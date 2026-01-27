import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GroupMembersScreen extends StatelessWidget {
  const GroupMembersScreen({super.key});

  static const Color primaryOrange = Color(0xFFE8913A);
  static const Color lightOrange = Color(0xFFFFF4E6);
  static const Color backgroundColor = Color(0xFFFAF7F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                _buildHeader(context),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        
                        // Illustration Card
                        _buildIllustrationCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Invite Code Card
                        _buildInviteCodeCard(context),
                        
                        const SizedBox(height: 32),
                        
                        // The Tribe Section
                        _buildTribeSection(),
                        
                        const SizedBox(height: 16),
                        
                        // Members List
                        _buildMembersList(),
                        
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Floating Add Button
            Positioned(
              right: 24,
              bottom: 100,
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: primaryOrange,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
            
            // Invite via Contacts Button
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Center(
                child: _buildInviteContactsButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          const Expanded(
            child: Text(
              'Group Members',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustrationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: lightOrange,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Container(
          width: 180,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: CustomPaint(
            painter: TravelersIllustrationPainter(),
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCodeCard(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRIP INVITE CODE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ROAM-2024-GOA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share this code with your fellow travelers to join the tribe.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: 'ROAM-2024-GOA'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invite code copied!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primaryOrange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.copy_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTribeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'The Tribe',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryOrange),
          ),
          child: const Text(
            '5 Members',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryOrange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMembersList() {
    final members = [
      MemberData(
        name: 'Aarav Sharma',
        status: 'ONLINE',
        isOnline: true,
        role: 'PLANNER',
        isPlanner: true,
        imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
      ),
      MemberData(
        name: 'Priya Patel',
        status: 'Joined via link',
        isOnline: false,
        role: 'VIEWER',
        isPlanner: false,
        imageUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
      ),
      MemberData(
        name: 'Rohan Das',
        status: 'Added by Aarav',
        isOnline: false,
        role: 'VIEWER',
        isPlanner: false,
        imageUrl: 'https://randomuser.me/api/portraits/men/52.jpg',
      ),
      MemberData(
        name: 'Ananya Iyer',
        status: 'Joined via link',
        isOnline: false,
        role: 'VIEWER',
        isPlanner: false,
        imageUrl: 'https://randomuser.me/api/portraits/women/68.jpg',
      ),
      MemberData(
        name: 'Vikram Singh',
        status: 'Added by Aarav',
        isOnline: false,
        role: 'VIEWER',
        isPlanner: false,
        imageUrl: 'https://randomuser.me/api/portraits/men/75.jpg',
      ),
    ];

    return Column(
      children: members.map((member) => _buildMemberCard(member)).toList(),
    );
  }

  Widget _buildMemberCard(MemberData member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: member.isPlanner ? primaryOrange : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                member.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.person, color: Colors.grey[400]),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Name and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (member.isOnline) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      member.status,
                      style: TextStyle(
                        fontSize: 13,
                        color: member.isOnline ? Colors.green : Colors.grey[500],
                        fontWeight: member.isOnline ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: member.isPlanner ? primaryOrange : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: member.isPlanner 
                  ? null 
                  : Border.all(color: Colors.grey[400]!),
            ),
            child: Text(
              member.role,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: member.isPlanner ? Colors.white : Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteContactsButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: primaryOrange, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_add_outlined, color: primaryOrange, size: 20),
          const SizedBox(width: 8),
          Text(
            'Invite via Contacts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class MemberData {
  final String name;
  final String status;
  final bool isOnline;
  final String role;
  final bool isPlanner;
  final String imageUrl;

  MemberData({
    required this.name,
    required this.status,
    required this.isOnline,
    required this.role,
    required this.isPlanner,
    required this.imageUrl,
  });
}

class TravelersIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw 3 travelers illustration
    // Person 1 (left - woman)
    paint.color = const Color(0xFFE8913A);
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.35),
      18,
      paint,
    );
    // Hair
    paint.color = Colors.black87;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.25, size.height * 0.3),
        width: 40,
        height: 30,
      ),
      paint,
    );
    // Body
    paint.color = const Color(0xFFFFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.25, size.height * 0.65),
          width: 36,
          height: 50,
        ),
        const Radius.circular(8),
      ),
      paint,
    );
    
    // Person 2 (center - man)
    paint.color = const Color(0xFFF5CBA7);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.3),
      20,
      paint,
    );
    // Hair
    paint.color = Colors.black87;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.22),
        width: 36,
        height: 20,
      ),
      paint,
    );
    // Body with backpack
    paint.color = const Color(0xFF2E7D32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.6),
          width: 40,
          height: 55,
        ),
        const Radius.circular(8),
      ),
      paint,
    );
    
    // Person 3 (right - man)
    paint.color = const Color(0xFFF5CBA7);
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.35),
      18,
      paint,
    );
    // Hair
    paint.color = Colors.black87;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.75, size.height * 0.28),
        width: 32,
        height: 18,
      ),
      paint,
    );
    // Body
    paint.color = const Color(0xFFE8913A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.75, size.height * 0.65),
          width: 36,
          height: 50,
        ),
        const Radius.circular(8),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
