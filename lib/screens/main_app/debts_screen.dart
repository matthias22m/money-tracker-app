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
    _tabController = TabController(length: 2, vsync: this);
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
            Tab(text: 'Debts'),
            Tab(text: 'Requests'),
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
        children: [_buildDebtsCombined(), _buildRequestsCombined()],
      ),
    );
  }

  Widget _buildDebtsCombined() {
    final owed$ = _service.owedToMe(appId: _appId);
    final owe$ = _service.iOwe(appId: _appId);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: owed$,
      builder: (context, owedSnap) {
        if (owedSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: owe$,
          builder: (context, oweSnap) {
            if (oweSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (owedSnap.hasError) {
              return Center(child: Text('Error: ${owedSnap.error}'));
            }
            if (oweSnap.hasError) {
              return Center(child: Text('Error: ${oweSnap.error}'));
            }
            final owedDocs = owedSnap.data?.docs ?? [];
            final oweDocs = oweSnap.data?.docs ?? [];
            if (owedDocs.isEmpty && oweDocs.isEmpty) {
              return const Center(child: Text('No debts'));
            }
            final List<_DebtItem> items = [];
            for (final d in owedDocs) {
              final data = d.data();
              items.add(
                _DebtItem(
                  data: data,
                  lenderView: true,
                  createdAt:
                      (data['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime(1970),
                ),
              );
            }
            for (final d in oweDocs) {
              final data = d.data();
              items.add(
                _DebtItem(
                  data: data,
                  lenderView: false,
                  createdAt:
                      (data['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime(1970),
                ),
              );
            }
            items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final it = items[index];
                return _DebtListItem(
                  debt: it.data,
                  showActions: false,
                  lenderView: it.lenderView,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsCombined() {
    final incoming$ = _service.pendingApprovals(
      appId: _appId,
    ); // I am borrower (outgoing - I would owe)
    final outgoing$ = _service.pendingMyRequests(
      appId: _appId,
    ); // I am lender (incoming)
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: incoming$,
      builder: (context, inSnap) {
        if (inSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: outgoing$,
          builder: (context, outSnap) {
            if (outSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (inSnap.hasError) {
              return Center(child: Text('Error: ${inSnap.error}'));
            }
            if (outSnap.hasError) {
              return Center(child: Text('Error: ${outSnap.error}'));
            }
            final inDocs = inSnap.data?.docs ?? [];
            final outDocs = outSnap.data?.docs ?? [];
            if (inDocs.isEmpty && outDocs.isEmpty) {
              return const Center(child: Text('No requests'));
            }
            final List<_DebtRequestItem> items = [];
            for (final d in inDocs) {
              final data = d.data();
              items.add(
                _DebtRequestItem(
                  id: d.id,
                  data: data,
                  // Incoming request for me to approve → I would owe (outgoing money)
                  lenderView: false,
                  approvalMode: true,
                  createdAt:
                      (data['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime(1970),
                ),
              );
            }
            for (final d in outDocs) {
              final data = d.data();
              items.add(
                _DebtRequestItem(
                  id: d.id,
                  data: data,
                  // My request waiting → incoming if approved
                  lenderView: true,
                  approvalMode: false,
                  createdAt:
                      (data['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime(1970),
                ),
              );
            }
            items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final it = items[index];
                return _DebtListItem(
                  debt: it.data,
                  showActions: it.approvalMode,
                  approvalMode: it.approvalMode,
                  lenderView: it.lenderView,
                  onAccept: it.approvalMode
                      ? () async {
                          await _service.acceptDebt(
                            appId: _appId,
                            expenseId: it.id,
                          );
                        }
                      : null,
                  onReject: it.approvalMode
                      ? () async {
                          await _service.rejectDebt(
                            appId: _appId,
                            expenseId: it.id,
                          );
                        }
                      : null,
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
  final bool lenderView;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _DebtListItem({
    required this.debt,
    this.showActions = false,
    this.approvalMode = false,
    this.lenderView = false,
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
        trailing: _AmountPill(
          amount: amount,
          isIncoming: lenderView,
          approvalMode: approvalMode,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              approvalMode
                  ? (lenderView
                        ? '${borrowerUsername} owes me'
                        : 'I owe ${lenderUsername}')
                  : (lenderView
                        ? '${borrowerUsername} owes me'
                        : 'I owe ${lenderUsername}'),
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

class _DebtItem {
  final Map<String, dynamic> data;
  final bool lenderView;
  final DateTime createdAt;
  _DebtItem({
    required this.data,
    required this.lenderView,
    required this.createdAt,
  });
}

class _DebtRequestItem {
  final String id;
  final Map<String, dynamic> data;
  final bool lenderView;
  final bool approvalMode;
  final DateTime createdAt;
  _DebtRequestItem({
    required this.id,
    required this.data,
    required this.lenderView,
    required this.approvalMode,
    required this.createdAt,
  });
}

class _AmountPill extends StatelessWidget {
  final double amount;
  final bool
  isIncoming; // true => money to me (lenderView), false => I owe (outgoing)
  final bool approvalMode; // pending approval indicator color neutral
  const _AmountPill({
    required this.amount,
    required this.isIncoming,
    required this.approvalMode,
  });

  @override
  Widget build(BuildContext context) {
    final bool positive = isIncoming;
    final Color color = approvalMode
        ? Theme.of(context).colorScheme.primary
        : positive
        ? Colors.green
        : Colors.red;
    final String sign = approvalMode ? '' : (positive ? '+' : '-');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$sign\$${amount.toStringAsFixed(2)}',
        style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
