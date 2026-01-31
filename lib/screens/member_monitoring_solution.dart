import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// MONITORING & DEBUGGING UTILITY FOR MEMBER MANAGEMENT
class MemberMonitoringService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final String tripId;

  MemberMonitoringService({required this.userId, required this.tripId});

  // MONITOR: Log all Firestore operations
  Future<void> logOperation(String operation, Map<String, dynamic> data) async {
    print('🔍 MONITOR [$operation] at ${DateTime.now()}');
    print('   Data: $data');
  }

  // MONITOR: Check if members collection exists and has data
  Future<Map<String, dynamic>> checkMembersHealth() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedTrips')
          .doc(tripId)
          .collection('members')
          .get();

      final health = {
        'exists': snapshot.docs.isNotEmpty,
        'count': snapshot.docs.length,
        'members': snapshot.docs.map((doc) => {
          'id': doc.id,
          'data': doc.data(),
        }).toList(),
        'path': 'users/$userId/savedTrips/$tripId/members',
        'timestamp': DateTime.now().toString(),
      };

      print('✅ HEALTH CHECK: ${health['count']} members found');
      return health;
    } catch (e) {
      print('❌ HEALTH CHECK FAILED: $e');
      return {'error': e.toString()};
    }
  }

  // MONITOR: Initialize with dummy data if empty
  Future<void> initializeDummyMembers() async {
    try {
      final existing = await checkMembersHealth();
      
      if (existing['count'] == 0) {
        print('🔧 INITIALIZING DUMMY DATA...');
        
        // Add current user as admin
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('savedTrips')
            .doc(tripId)
            .collection('members')
            .doc(userId)
            .set({
          'uid': userId,
          'fullName': 'You (Current User)',
          'email': 'you@example.com',
          'role': 'admin',
          'addedAt': FieldValue.serverTimestamp(),
          'addedBy': userId,
        });

        // Add dummy members
        final dummyMembers = [
          {
            'fullName': 'John Doe',
            'email': 'john@example.com',
            'role': 'member',
          },
          {
            'fullName': 'Sarah Smith',
            'email': 'sarah@example.com',
            'role': 'member',
          },
          {
            'fullName': 'Mike Johnson',
            'email': 'mike@example.com',
            'role': 'admin',
          },
        ];

        for (var member in dummyMembers) {
          final memberId = _firestore.collection('temp').doc().id;
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('savedTrips')
              .doc(tripId)
              .collection('members')
              .doc(memberId)
              .set({
            'uid': memberId,
            'fullName': member['fullName'],
            'email': member['email'],
            'role': member['role'],
            'addedAt': FieldValue.serverTimestamp(),
            'addedBy': userId,
          });
        }

        print('✅ DUMMY DATA INITIALIZED: ${dummyMembers.length + 1} members added');
      }
    } catch (e) {
      print('❌ INITIALIZATION FAILED: $e');
    }
  }

  // MONITOR: Add member with full logging
  Future<bool> addMemberWithMonitoring(String name, String email, String role) async {
    try {
      print('📝 ADDING MEMBER: $name ($email) as $role');
      
      final memberId = _firestore.collection('temp').doc().id;
      final memberData = {
        'uid': memberId,
        'fullName': name,
        'email': email,
        'role': role,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': userId,
      };

      await logOperation('ADD_MEMBER', memberData);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedTrips')
          .doc(tripId)
          .collection('members')
          .doc(memberId)
          .set(memberData);

      print('✅ MEMBER ADDED SUCCESSFULLY: $memberId');
      
      // Verify the add
      await Future.delayed(const Duration(milliseconds: 500));
      final health = await checkMembersHealth();
      print('📊 POST-ADD COUNT: ${health['count']}');
      
      return true;
    } catch (e) {
      print('❌ ADD MEMBER FAILED: $e');
      return false;
    }
  }

  // MONITOR: Stream members with logging
  Stream<List<Map<String, dynamic>>> monitorMembersStream() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('savedTrips')
        .doc(tripId)
        .collection('members')
        .snapshots()
        .map((snapshot) {
      print('🔄 STREAM UPDATE: ${snapshot.docs.length} members');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}

// MONITORING DASHBOARD WIDGET
class MemberMonitoringDashboard extends StatefulWidget {
  final String tripId;
  const MemberMonitoringDashboard({super.key, required this.tripId});

  @override
  State<MemberMonitoringDashboard> createState() => _MemberMonitoringDashboardState();
}

class _MemberMonitoringDashboardState extends State<MemberMonitoringDashboard> {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? 'user_1';
  late MemberMonitoringService _monitor;
  Map<String, dynamic>? _healthData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _monitor = MemberMonitoringService(userId: userId, tripId: widget.tripId);
    _runHealthCheck();
  }

  Future<void> _runHealthCheck() async {
    setState(() => _isLoading = true);
    final health = await _monitor.checkMembersHealth();
    setState(() {
      _healthData = health;
      _isLoading = false;
    });
  }

  Future<void> _initializeDummyData() async {
    setState(() => _isLoading = true);
    await _monitor.initializeDummyMembers();
    await _runHealthCheck();
  }

  Future<void> _addTestMember() async {
    final success = await _monitor.addMemberWithMonitoring(
      'Test User ${DateTime.now().second}',
      'test${DateTime.now().second}@example.com',
      'member',
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Test member added successfully!')),
      );
      await _runHealthCheck();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to add test member')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: const Text('Member Monitoring Dashboard'),
        backgroundColor: const Color(0xFFE8913A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runHealthCheck,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHealthCard(),
                  const SizedBox(height: 20),
                  _buildActionsCard(),
                  const SizedBox(height: 20),
                  _buildMembersListCard(),
                  const SizedBox(height: 20),
                  _buildDebugInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildHealthCard() {
    final count = _healthData?['count'] ?? 0;
    final isHealthy = count > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.error,
                  color: isHealthy ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'System Health',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isHealthy ? 'All systems operational' : 'No members found',
                        style: TextStyle(
                          color: isHealthy ? Colors.green : Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow('Member Count', '$count'),
            _buildInfoRow('Collection Path', _healthData?['path'] ?? 'N/A'),
            _buildInfoRow('Last Check', _healthData?['timestamp'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _initializeDummyData,
                icon: const Icon(Icons.people),
                label: const Text('Initialize Dummy Members'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8913A),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addTestMember,
                icon: const Icon(Icons.person_add),
                label: const Text('Add Test Member'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28A745),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _runHealthCheck,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Health Check'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersListCard() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _monitor.monitorMembersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final members = snapshot.data!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Members Feed',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 8, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            '${members.length} LIVE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (members.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No members found. Initialize dummy data to get started.'),
                    ),
                  )
                else
                  ...members.map((member) => _buildMemberTile(member)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final isAdmin = member['role'] == 'admin';
    final isCurrentUser = member['uid'] == userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFFFFF4E6) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? const Color(0xFFE8913A) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCurrentUser ? const Color(0xFFE8913A) : Colors.grey.shade300,
            child: Text(
              (member['fullName'] ?? 'U')[0].toUpperCase(),
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member['fullName'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  member['email'] ?? 'No email',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            'ID: ${member['id'].substring(0, 8)}...',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bug_report, size: 20),
                SizedBox(width: 8),
                Text(
                  'Debug Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('User ID', userId),
            _buildInfoRow('Trip ID', widget.tripId),
            _buildInfoRow('Full Path', 'users/$userId/savedTrips/${widget.tripId}/members'),
            const SizedBox(height: 12),
            const Text(
              'Console Output:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Check your Flutter console/terminal for detailed logs.\nAll operations are logged with 🔍, ✅, ❌ prefixes.',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}