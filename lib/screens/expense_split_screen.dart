import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'member_monitoring_solution.dart';

// COLORS
const Color primaryOrange = Color(0xFFE8913A);
const Color lightOrange = Color(0xFFFFF4E6);
const Color textDark = Color(0xFF1A1A1A);
const Color textGray = Color(0xFF6B7280);
const Color backgroundColor = Color(0xFFFAF7F2);
const Color redAmount = Color(0xFFDC3545);
const Color greenAmount = Color(0xFF28A745);
const Color cardWhite = Colors.white;

class ExpenseSplitScreen extends StatefulWidget {
  final String tripId;
  const ExpenseSplitScreen({super.key, required this.tripId});

  @override
  State<ExpenseSplitScreen> createState() => _ExpenseSplitScreenState();
}

class _ExpenseSplitScreenState extends State<ExpenseSplitScreen> {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? 'user_1';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double youOwe = 0;
  double youReceive = 0;
  double totalExpenses = 0;
  Map<String, double> balances = {};
  Map<String, String> memberNames = {};
  String? currentUserRole;
  bool isAdmin = false;

@override
void initState() {
  super.initState();
  _initializeData();
}

Future<void> _initializeData() async {
  _loadMemberNames();
  _loadUserRole();

  final monitor = MemberMonitoringService(
    userId: userId,
    tripId: widget.tripId,
  );

  await monitor.initializeDummyMembers(); // ✅ now valid
}


  Future<void> _loadMemberNames() async {
    try {
      final membersSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedTrips')
          .doc(widget.tripId)
          .collection('members')
          .get();

      setState(() {
        memberNames.clear();
        for (var doc in membersSnapshot.docs) {
          final data = doc.data();
          memberNames[data['uid']] = data['fullName'] ?? 'Unknown';
        }
      });
    } catch (e) {
      print('Error loading member names: $e');
    }
  }

  Future<void> _loadUserRole() async {
    try {
      final memberDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedTrips')
          .doc(widget.tripId)
          .collection('members')
          .where('uid', isEqualTo: userId)
          .get();

      if (memberDoc.docs.isNotEmpty) {
        final role = memberDoc.docs.first.data()['role'] ?? 'member';
        setState(() {
          currentUserRole = role;
          isAdmin = role == 'admin';
        });
      }
    } catch (e) {
      print('Error loading user role: $e');
    }
  }

  void _calculateBalances(List<QueryDocumentSnapshot> expenses) {
    balances.clear();
    totalExpenses = 0;

    for (var memberId in memberNames.keys) {
      balances[memberId] = 0;
    }

    for (var doc in expenses) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] ?? 0).toDouble();
      final paidBy = data['paidBy'] ?? '';
      final participants = List<String>.from(data['participants'] ?? []);

      if (participants.isEmpty) continue;

      totalExpenses += amount;
      final split = amount / participants.length;

      for (var uid in participants) {
        balances[uid] = (balances[uid] ?? 0) - split;
      }

      balances[paidBy] = (balances[paidBy] ?? 0) + amount;
    }

    final userBalance = balances[userId] ?? 0;
    youOwe = userBalance < 0 ? userBalance.abs() : 0;
    youReceive = userBalance > 0 ? userBalance : 0;
  }

  Future<void> _settleUp() async {
    if (balances.isEmpty) {
      _showSnackBar('No balances to settle');
      return;
    }

    List<MapEntry<String, double>> debts = [];
    List<MapEntry<String, double>> credits = [];

    balances.forEach((uid, balance) {
      if (balance < 0) {
        debts.add(MapEntry(uid, balance.abs()));
      } else if (balance > 0) {
        credits.add(MapEntry(uid, balance));
      }
    });

    debts.sort((a, b) => b.value.compareTo(a.value));
    credits.sort((a, b) => b.value.compareTo(a.value));

    List<Settlement> settlements = [];
    int i = 0, j = 0;

    while (i < debts.length && j < credits.length) {
      double debt = debts[i].value;
      double credit = credits[j].value;
      double settled = debt < credit ? debt : credit;

      settlements.add(Settlement(
        from: debts[i].key,
        to: credits[j].key,
        amount: settled,
      ));

      debts[i] = MapEntry(debts[i].key, debt - settled);
      credits[j] = MapEntry(credits[j].key, credit - settled);

      if (debts[i].value == 0) i++;
      if (credits[j].value == 0) j++;
    }

    _showSettlementDialog(settlements);
  }

  void _showSettlementDialog(List<Settlement> settlements) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: cardWhite,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: lightOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.account_balance_wallet, color: primaryOrange, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Settlement Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightOrange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, color: primaryOrange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Optimal settlement in ${settlements.length} transaction${settlements.length > 1 ? 's' : ''}',
                        style: const TextStyle(color: primaryOrange, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...settlements.map((s) {
                final fromName = memberNames[s.from] ?? 'Unknown';
                final toName = memberNames[s.to] ?? 'Unknown';
                final isUserInvolved = s.from == userId || s.to == userId;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUserInvolved ? lightOrange : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUserInvolved ? primaryOrange.withOpacity(0.3) : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.from == userId ? 'You' : fromName.split(' ')[0],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isUserInvolved ? primaryOrange : textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text('pays', style: TextStyle(fontSize: 11, color: textGray)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isUserInvolved ? primaryOrange : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₹${s.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isUserInvolved ? Colors.white : textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward, color: primaryOrange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              s.to == userId ? 'You' : toName.split(' ')[0],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isUserInvolved ? primaryOrange : textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text('receives', style: TextStyle(fontSize: 11, color: textGray)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: textGray)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _markAsSettled();
              Navigator.pop(context);
              _showSnackBar('Settlement recorded! 🎉');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: greenAmount,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Mark as Settled', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsSettled() async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedTrips')
          .doc(widget.tripId)
          .collection('settlements')
          .add({
        'settledAt': FieldValue.serverTimestamp(),
        'settledBy': userId,
        'balances': balances,
      });
    } catch (e) {
      print('Error recording settlement: $e');
    }
  }

  // ADD MEMBER DIALOG
  void _showAddMemberDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'member';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: cardWhite,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_add, color: primaryOrange, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Add Trip Member', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g., John Doe',
                    prefixIcon: const Icon(Icons.person, color: primaryOrange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: primaryOrange, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'e.g., john@example.com',
                    prefixIcon: const Icon(Icons.email, color: primaryOrange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: primaryOrange, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightOrange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Role',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              value: 'member',
                              groupValue: selectedRole,
                              onChanged: (value) {
                                setState(() => selectedRole = value!);
                              },
                              title: const Text('Member', style: TextStyle(fontSize: 14)),
                              activeColor: primaryOrange,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              value: 'admin',
                              groupValue: selectedRole,
                              onChanged: (value) {
                                setState(() => selectedRole = value!);
                              },
                              title: const Text('Admin', style: TextStyle(fontSize: 14)),
                              activeColor: primaryOrange,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: textGray)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
                  _showSnackBar('Please fill all fields');
                  return;
                }
                
                await _addMember(
                  nameController.text.trim(),
                  emailController.text.trim(),
                  selectedRole,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Add Member', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMember(String name, String email, String role) async {
    try {
      // Generate a unique ID for the member
      final memberId = _firestore.collection('temp').doc().id;
      
      // Add member to the trip's members subcollection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedTrips')
          .doc(widget.tripId)
          .collection('members')
          .doc(memberId)
          .set({
        'uid': memberId,
        'fullName': name,
        'email': email,
        'role': role,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': userId,
      });

      // Reload member names
      await _loadMemberNames();
      
      _showSnackBar('Member added successfully! ✓');
    } catch (e) {
      print('Error adding member: $e');
      _showSnackBar('Error adding member');
    }
  }

  // ADD EXPENSE DIALOG
  void _showAddExpenseDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'Food';
    String selectedPaidBy = userId;
    Set<String> selectedParticipants = {userId};

    final categories = ['Food', 'Transport', 'Accommodation', 'Activities', 'Shopping', 'Other'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: cardWhite,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: primaryOrange, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Add Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Expense Title',
                    hintText: 'e.g., Dinner at Marina Bay',
                    prefixIcon: const Icon(Icons.title, color: primaryOrange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: primaryOrange, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: 'e.g., 3200',
                    prefixIcon: const Icon(Icons.currency_rupee, color: primaryOrange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: primaryOrange, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightOrange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(_getCategoryIcon(cat), color: _getCategoryColor(cat), size: 20),
                                const SizedBox(width: 12),
                                Text(cat),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedCategory = value!);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightOrange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paid By',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedPaidBy,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: memberNames.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.key == userId ? 'You' : entry.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedPaidBy = value!);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightOrange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Split Between',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...memberNames.entries.map((entry) {
                        final isSelected = selectedParticipants.contains(entry.key);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedParticipants.add(entry.key);
                              } else {
                                selectedParticipants.remove(entry.key);
                              }
                            });
                          },
                          title: Text(
                            entry.key == userId ? 'You' : entry.value,
                            style: const TextStyle(fontSize: 14),
                          ),
                          activeColor: primaryOrange,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: textGray)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || amountController.text.trim().isEmpty) {
                  _showSnackBar('Please fill all fields');
                  return;
                }

                if (selectedParticipants.isEmpty) {
                  _showSnackBar('Please select at least one participant');
                  return;
                }

                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  _showSnackBar('Please enter a valid amount');
                  return;
                }

                await _addExpense(
                  titleController.text.trim(),
                  amount,
                  selectedCategory,
                  selectedPaidBy,
                  selectedParticipants.toList(),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addExpense(String title, double amount, String category, String paidBy, List<String> participants) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedTrips')
          .doc(widget.tripId)
          .collection('expenses')
          .add({
        'title': title,
        'amount': amount,
        'category': category,
        'paidBy': paidBy,
        'participants': participants,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': userId,
      });

      _showSnackBar('Expense added successfully! ✓');
    } catch (e) {
      print('Error adding expense: $e');
      _showSnackBar('Error adding expense');
    }
  }

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
                stream: _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('savedTrips')
                    .doc(widget.tripId)
                    .collection('expenses')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: primaryOrange));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final expenses = snapshot.data!.docs;
                  _calculateBalances(expenses);

                  return _buildContent(expenses);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildContent(List<QueryDocumentSnapshot> expenses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTripStatsCard(),
          const SizedBox(height: 20),
          _buildMembersSection(),
          const SizedBox(height: 20),
          _buildBalanceSummaryCard(),
          const SizedBox(height: 20),
          _buildExpenseChart(expenses),
          const SizedBox(height: 24),
          _buildExpenseList(expenses),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTripStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryOrange, Color(0xFFFF9D5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Trip Expenses',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${memberNames.length} members',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '₹',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                totalExpenses.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(userId)
          .collection('savedTrips')
          .doc(widget.tripId)
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final members = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: lightOrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.people, color: primaryOrange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Trip Members',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                  if (isAdmin)
                    InkWell(
                      onTap: _showAddMemberDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: lightOrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.person_add, size: 16, color: primaryOrange),
                            SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                color: primaryOrange,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              ...members.asMap().entries.map((entry) {
                final index = entry.key;
                final memberDoc = entry.value;
                final member = memberDoc.data() as Map<String, dynamic>;
                final isYou = member['uid'] == userId;
                final role = member['role'];
                final balance = balances[member['uid']] ?? 0;

                return Container(
                  margin: EdgeInsets.only(bottom: index < members.length - 1 ? 12 : 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isYou ? lightOrange : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isYou ? primaryOrange.withOpacity(0.3) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: isYou ? primaryOrange : Colors.grey.shade300,
                            child: Text(
                              (member['fullName'] ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                color: isYou ? Colors.white : textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (role == 'admin')
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: greenAmount,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isYou ? 'You' : (member['fullName'] ?? 'Unknown').split(' ')[0],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isYou ? primaryOrange : textDark,
                                  ),
                                ),
                                if (role == 'admin') ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: greenAmount.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Admin',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: greenAmount,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              member['email'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            balance == 0
                                ? 'Settled'
                                : balance > 0
                                    ? '+₹${balance.toStringAsFixed(0)}'
                                    : '-₹${balance.abs().toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: balance == 0
                                  ? textGray
                                  : balance > 0
                                      ? greenAmount
                                      : redAmount,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            balance == 0
                                ? '✓'
                                : balance > 0
                                    ? 'gets back'
                                    : 'owes',
                            style: TextStyle(
                              fontSize: 10,
                              color: balance == 0
                                  ? textGray
                                  : balance > 0
                                      ? greenAmount
                                      : redAmount,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  'You Owe',
                  youOwe,
                  redAmount,
                  Icons.arrow_upward,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              Expanded(
                child: _buildBalanceItem(
                  'You Get',
                  youReceive,
                  greenAmount,
                  Icons.arrow_downward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String title, double amount, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: textGray,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseChart(List<QueryDocumentSnapshot> expenses) {
    Map<String, double> categoryExpenses = {};

    for (var doc in expenses) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['category'] ?? 'Other';
      final amount = (data['amount'] ?? 0).toDouble();
      categoryExpenses[category] = (categoryExpenses[category] ?? 0) + amount;
    }

    if (categoryExpenses.isEmpty) return const SizedBox();

    final sections = categoryExpenses.entries.map((e) {
      final percentage = (e.value / totalExpenses) * 100;
      return PieChartSectionData(
        value: e.value,
        title: '${percentage.toStringAsFixed(0)}%',
        color: _getCategoryColor(e.key),
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart, color: primaryOrange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Expense Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 3,
                centerSpaceRadius: 50,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: categoryExpenses.entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(e.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${e.key}: ₹${e.value.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textDark,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(List<QueryDocumentSnapshot> expenses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: lightOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long, color: primaryOrange, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Recent Expenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...expenses.map((doc) {
          final expense = doc.data() as Map<String, dynamic>;
          final isYou = expense['paidBy'] == userId;
          final paidByName = memberNames[expense['paidBy']] ?? 'Unknown';
          final createdAt = (expense['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showSnackBar('Expense details: ${expense['title']}'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isYou ? lightOrange : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _getCategoryIcon(expense['category']),
                          color: isYou ? primaryOrange : textGray,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense['title'] ?? 'Expense',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  isYou ? 'YOU PAID' : 'PAID BY ${paidByName.split(' ')[0].toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isYou ? primaryOrange : textGray,
                                  ),
                                ),
                                Text(
                                  ' • ${_formatDateRelative(createdAt)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: textGray,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${(expense['amount'] ?? 0).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(expense['category']).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              expense['category'] ?? 'Other',
                              style: TextStyle(
                                fontSize: 10,
                                color: _getCategoryColor(expense['category']),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  String _formatDateRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food': const Color(0xFFFF6B6B),
      'Transport': const Color(0xFF4ECDC4),
      'Accommodation': const Color(0xFF9B59B6),
      'Activities': const Color(0xFF2ECC71),
      'Shopping': const Color(0xFFE91E63),
      'Other': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      'Food': Icons.restaurant,
      'Transport': Icons.directions_car,
      'Accommodation': Icons.hotel,
      'Activities': Icons.local_activity,
      'Shopping': Icons.shopping_bag,
      'Other': Icons.receipt,
    };
    return icons[category] ?? Icons.receipt;
  }

Widget _buildHeader(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: cardWhite,
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
        // 🔙 Back button
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 22),
            onPressed: () => Navigator.pop(context),
            color: textDark,
          ),
        ),

        const SizedBox(width: 12),

        // 📝 Title
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Singapore Trip',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              Text(
                'Expense Management',
                style: TextStyle(
                  fontSize: 12,
                  color: textGray,
                ),
              ),
            ],
          ),
        ),

        // ❤️ Monitor button (DEBUG)
        IconButton(
          icon: const Icon(Icons.monitor_heart, color: Colors.red),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MemberMonitoringDashboard(tripId: widget.tripId),
              ),
            );
          },
        ),

        const SizedBox(width: 8),

        // ✅ Settle Up button
        InkWell(
          onTap: _settleUp,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [greenAmount, Color(0xFF2ECC71)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: greenAmount.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'Settle Up',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: lightOrange,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long, size: 80, color: primaryOrange.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text(
            'No expenses yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start tracking your trip expenses',
            style: TextStyle(color: textGray, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddExpenseDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add First Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showAddExpenseDialog,
      backgroundColor: primaryOrange,
      elevation: 8,
      icon: const Icon(Icons.add, color: Colors.white, size: 24),
      label: const Text(
        'Add Expense',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: textDark,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class Settlement {
  final String from;
  final String to;
  final double amount;

  Settlement({required this.from, required this.to, required this.amount});
}