import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// COLORS (unchanged)
const Color primaryOrange = Color(0xFFE8913A);
const Color lightOrange = Color(0xFFFFF4E6);
const Color textDark = Color(0xFF1A1A1A);
const Color textGray = Color(0xFF6B7280);
const Color backgroundColor = Color(0xFFFAF7F2);
const Color redAmount = Color(0xFFDC3545);
const Color greenAmount = Color(0xFF28A745);

class ExpenseSplitScreen extends StatefulWidget {
  final String tripId;
  const ExpenseSplitScreen({super.key, required this.tripId});

  @override
  State<ExpenseSplitScreen> createState() => _ExpenseSplitScreenState();
}

class _ExpenseSplitScreenState extends State<ExpenseSplitScreen> {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  double youOwe = 0;
  double youReceive = 0;

  Map<String, double> balances = {};

  // ---------------- SETTLE UP LOGIC ----------------
  void _calculateBalances(List<QueryDocumentSnapshot> expenses) {
    balances.clear();

    for (var doc in expenses) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = data['amount'].toDouble();
      final paidBy = data['paidBy'];
      final participants = List<String>.from(data['participants']);

      final split = amount / participants.length;

      for (var uid in participants) {
        balances[uid] = (balances[uid] ?? 0) - split;
      }

      balances[paidBy] = (balances[paidBy] ?? 0) + amount;
    }

    youOwe = balances[userId]! < 0 ? balances[userId]!.abs() : 0;
    youReceive = balances[userId]! > 0 ? balances[userId]! : 0;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('savedTrips')
                    .doc(widget.tripId)
                    .collection('expenses')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final expenses = snapshot.data!.docs;
                  _calculateBalances(expenses);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMembersRow(),
                        const SizedBox(height: 16),
                        _buildTripBalanceCard(),
                        const SizedBox(height: 24),
                        _buildExpenseList(expenses),
                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _circleIcon(
            Icons.arrow_back,
            () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Text(
            'Expense Split',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Settled balances calculated")),
              );
            },
            child: Container(
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- MEMBERS ----------------
  Widget _buildMembersRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedTrips')
          .doc(widget.tripId)
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final members = snapshot.data!.docs;

        return SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: members.map((m) {
              final data = m.data() as Map<String, dynamic>;
              final isYou = data['uid'] == userId;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          isYou ? primaryOrange : Colors.grey.shade300,
                      child: Text(
                        isYou ? 'YOU' : data['fullName'][0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isYou ? 'You' : data['fullName'].split(' ')[0],
                      style: const TextStyle(fontSize: 11),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ---------------- BALANCE CARD ----------------
  Widget _buildTripBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _balanceColumn('You owe', youOwe, redAmount),
          const VerticalDivider(),
          _balanceColumn('You receive', youReceive, greenAmount),
        ],
      ),
    );
  }

  Widget _balanceColumn(String title, double amount, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: textGray)),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- EXPENSE LIST ----------------
  Widget _buildExpenseList(List<QueryDocumentSnapshot> expenses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Expenses',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...expenses.map((e) {
          final d = e.data() as Map<String, dynamic>;
          final isYou = d['paidBy'] == userId;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildExpenseCard(
              title: d['title'],
              amount: '₹${d['amount']}',
              payer: isYou ? 'YOU PAID' : 'PAID BY MEMBER',
              date: d['createdAt']
                  .toDate()
                  .toString()
                  .substring(0, 10),
              isYou: isYou,
            ),
          );
        }).toList(),
      ],
    );
  }

  // ---------------- REUSED UI PARTS ----------------
  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildExpenseCard({
    required String title,
    required String amount,
    required String payer,
    required String date,
    required bool isYou,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isYou ? lightOrange : Colors.grey.shade200,
            child: Icon(Icons.receipt, color: primaryOrange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('$payer • $date',
                    style: const TextStyle(fontSize: 12, color: textGray)),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
