import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/friend_service.dart';
import '../../services/shared_expense_service.dart';

class LogSharedExpenseScreen extends StatefulWidget {
  const LogSharedExpenseScreen({super.key});

  @override
  State<LogSharedExpenseScreen> createState() => _LogSharedExpenseScreenState();
}

class _LogSharedExpenseScreenState extends State<LogSharedExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  String? _selectedBorrowerId;
  String? _selectedBorrowerUsername;
  String? _currentUserUsername;

  final FriendService _friendService = FriendService();
  final SharedExpenseService _sharedExpenseService = SharedExpenseService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  Future<void> _loadCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('info')
        .get();
    setState(() {
      _currentUserUsername = userDoc.data()?['name'] ?? 'You';
    });
  }

  Future<List<Map<String, String>>> _loadFriends() async {
    final friendIds = await _friendService.getFriendUserIds();
    if (friendIds.isEmpty) return [];
    final List<Map<String, String>> friends = [];
    for (final id in friendIds) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .collection('profile')
          .doc('info')
          .get();
      final name = doc.data()?['name']?.toString() ?? 'Friend';
      friends.add({'id': id, 'name': name});
    }
    friends.sort((a, b) => a['name']!.compareTo(b['name']!));
    return friends;
  }

  Future<void> _logSharedExpense() async {
    if (!_formKey.currentState!.validate() || _selectedBorrowerId == null) {
      return;
    }

    final appId = FirebaseAuth.instance.app.options.projectId;

    try {
      await _sharedExpenseService.logSharedExpense(
        appId: appId,
        borrowerId: _selectedBorrowerId!,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text,
        lenderUsername: _currentUserUsername ?? 'You',
        borrowerUsername: _selectedBorrowerUsername ?? 'Friend',
        createdAt: _selectedDate,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error logging expense: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log Shared Expense', style: GoogleFonts.lato()),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _loadFriends(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final friends = snapshot.data ?? [];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedBorrowerId,
                    decoration: const InputDecoration(
                      labelText: 'Select Friend',
                      border: OutlineInputBorder(),
                    ),
                    items: friends
                        .map(
                          (f) => DropdownMenuItem<String>(
                            value: f['id'],
                            child: Text(f['name']!),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedBorrowerId = val;
                        _selectedBorrowerUsername = friends.firstWhere(
                          (e) => e['id'] == val,
                        )['name'];
                      });
                    },
                    validator: (val) =>
                        val == null ? 'Please select a friend' : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                            style: GoogleFonts.lato(),
                          ),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter amount';
                      final d = double.tryParse(val);
                      if (d == null || d <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Enter description'
                        : null,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logSharedExpense,
                      child: const Text('Send for Approval'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
