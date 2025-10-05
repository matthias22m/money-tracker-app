import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/shared_expense_service.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SharedExpenseService _service = SharedExpenseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _appId => FirebaseAuth.instance.app.options.projectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shared Expenses', style: GoogleFonts.lato()),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Owed To Me'),
            Tab(text: 'I Owe'),
            Tab(text: 'Approvals'),
            // Settlements removed
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/log-shared-expense');
        },
        child: const Icon(Icons.add),
        tooltip: 'Log Shared Expense',
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(
            _service.owedToMe(appId: _appId),
            showActions: false,
            lenderView: true,
          ),
          _buildList(
            _service.iOwe(appId: _appId),
            showActions: false,
            lenderView: false,
          ),
          _buildApprovals(),
          // Settlements tab removed
        ],
      ),
    );
  }

  Widget _buildList(
    Stream<QuerySnapshot<Map<String, dynamic>>> stream, {
    bool showActions = false,
    required bool lenderView,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No pending debts'));
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            return _DebtListItem(debt: data, showActions: showActions);
          },
        );
      },
    );
  }

  Widget _buildApprovals() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.pendingApprovals(appId: _appId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No pending approvals'));
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            return _DebtListItem(
              debt: data,
              showActions: true,
              approvalMode: true,
              onAccept: () async {
                await _service.acceptDebt(
                  appId: _appId,
                  expenseId: docs[index].id,
                );
              },
              onReject: () async {
                await _service.rejectDebt(
                  appId: _appId,
                  expenseId: docs[index].id,
                );
              },
            );
          },
        );
      },
    );
  }

  // Settlements workflow removed
}

class _DebtListItem extends StatelessWidget {
  final Map<String, dynamic> debt;
  final bool showActions;
  final bool approvalMode;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _DebtListItem({
    required this.debt,
    this.showActions = false,
    this.approvalMode = false,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final amount = (debt['amount'] as num?)?.toDouble() ?? 0.0;
    final description = (debt['description'] as String?) ?? '';
    final lenderUsername = (debt['lenderUsername'] as String?) ?? 'User';
    final borrowerUsername = (debt['borrowerUsername'] as String?) ?? 'User';

    return Card(
      child: ListTile(
        title: Text(
          description.isEmpty ? 'Shared Expense' : description,
          style: GoogleFonts.lato(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          '\$${amount.toStringAsFixed(2)}',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${borrowerUsername} owes ${lenderUsername}',
              style: GoogleFonts.lato(),
            ),
            if (showActions)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (approvalMode) ...[
                      OutlinedButton(
                        onPressed: onReject,
                        child: const Text('Reject'),
                      ),
                      ElevatedButton(
                        onPressed: onAccept,
                        child: const Text('Accept'),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
