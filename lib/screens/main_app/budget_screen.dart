import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/firebase_service.dart';
import '../../models/budget.dart';
import '../../core/theme/app_theme.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _setBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );

    try {
      final amount = double.parse(_amountController.text);
      await firebaseService.setCurrentBudget(amount);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  _isEditing
                      ? 'Budget updated successfully!'
                      : 'Budget set successfully!',
                  style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        _amountController.clear();
        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to ${_isEditing ? 'update' : 'set'} budget. Please try again.',
                    style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startEditing(Budget budget) {
    setState(() {
      _isEditing = true;
      _amountController.text = budget.amount.toString();
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _amountController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);

    return WillPopScope(
      onWillPop: () async {
        // Prevent back button from popping
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            'Budget Management',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: MediaQuery.of(context).viewInsets.bottom > 0
                    ? const AlwaysScrollableScrollPhysics()
                    : const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight - 40, // Account for padding
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle
                      Text(
                        'Manage your monthly budget for $monthName',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Current Budget Status
                      StreamBuilder<Budget?>(
                        stream: firebaseService.getCurrentBudgetStream(),
                        builder: (context, budgetSnapshot) {
                          return StreamBuilder<double>(
                            stream: firebaseService
                                .getCurrentMonthExpensesStream(),
                            builder: (context, expensesSnapshot) {
                              final budget = budgetSnapshot.data;
                              final totalExpenses =
                                  expensesSnapshot.data ?? 0.0;
                              final remaining = budget != null
                                  ? budget.amount - totalExpenses
                                  : 0.0;
                              final percentage =
                                  budget != null && budget.amount > 0
                                  ? (totalExpenses / budget.amount).clamp(
                                      0.0,
                                      1.0,
                                    )
                                  : 0.0;

                              return Column(
                                children: [
                                  // Budget Status Card
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context).colorScheme.primary
                                              .withOpacity(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Current Budget Status',
                                              style: GoogleFonts.lato(
                                                color: Colors.white70,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (budget != null)
                                              GestureDetector(
                                                onTap: () =>
                                                    _startEditing(budget),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.5),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.edit,
                                                        color: Colors.white,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Edit',
                                                        style: GoogleFonts.lato(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            else
                                              Text(
                                                'No budget set',
                                                style: GoogleFonts.lato(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (budget != null) ...[
                                          Text(
                                            '\$${budget.amount.toStringAsFixed(0)}',
                                            style: GoogleFonts.lato(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Spent',
                                                    style: GoogleFonts.lato(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    '\$${totalExpenses.toStringAsFixed(0)}',
                                                    style: GoogleFonts.lato(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'Remaining',
                                                    style: GoogleFonts.lato(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    '\$${remaining.toStringAsFixed(0)}',
                                                    style: GoogleFonts.lato(
                                                      color: remaining >= 0
                                                          ? Colors.white
                                                          : Colors.red[200],
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          // Progress Bar
                                          Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: percentage,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: percentage > 1.0
                                                      ? Colors.red[300]
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${(percentage * 100).toStringAsFixed(1)}% of budget used',
                                            style: GoogleFonts.lato(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ] else ...[
                                          Text(
                                            'No budget set',
                                            style: GoogleFonts.lato(
                                              color: Colors.white70,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Set a budget to start tracking your expenses',
                                            style: GoogleFonts.lato(
                                              color: Colors.white60,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // Set Budget Form
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardTheme.color,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _isEditing
                                                    ? 'Edit Budget'
                                                    : budget != null
                                                    ? 'Update Budget'
                                                    : 'Set Monthly Budget',
                                                style: GoogleFonts.lato(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                              ),
                                              if (_isEditing)
                                                TextButton(
                                                  onPressed: _cancelEditing,
                                                  child: Text(
                                                    'Cancel',
                                                    style: GoogleFonts.lato(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withOpacity(0.6),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          TextFormField(
                                            controller: _amountController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'^\d*\.?\d*'),
                                              ),
                                            ],
                                            decoration: InputDecoration(
                                              labelText: 'Budget Amount',
                                              hintText:
                                                  'Enter your monthly budget',
                                              prefixText: '\$ ',
                                              prefixStyle: GoogleFonts.lato(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.2),
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.2),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  width: 2,
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: Theme.of(
                                                context,
                                              ).colorScheme.surface,
                                            ),
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter a budget amount';
                                              }
                                              final amount = double.tryParse(
                                                value,
                                              );
                                              if (amount == null ||
                                                  amount <= 0) {
                                                return 'Please enter a valid amount';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 24),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: ElevatedButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _setBudget,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _isLoading
                                                    ? Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                          .withOpacity(0.6)
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: _isLoading
                                                  ? Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                  Color
                                                                >(
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .onPrimary,
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Text(
                                                          'Setting...',
                                                          style: GoogleFonts.lato(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .onPrimary,
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Text(
                                                      _isEditing
                                                          ? 'Update Budget'
                                                          : budget != null
                                                          ? 'Update Budget'
                                                          : 'Set Budget',
                                                      style: GoogleFonts.lato(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.onPrimary,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // Budget History Section
                                  _buildBudgetHistory(),
                                  const SizedBox(
                                    height: 10,
                                  ), // Extra space for keyboard
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget History',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Budget>>(
            stream: _getBudgetHistoryStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading budget history',
                    style: GoogleFonts.lato(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }

              final budgets = snapshot.data ?? [];
              final currentMonth = DateTime.now();
              final historyBudgets =
                  budgets
                      .where(
                        (b) =>
                            !(b.year == currentMonth.year &&
                                b.month == currentMonth.month),
                      )
                      .toList()
                    ..sort((a, b) {
                      if (a.year != b.year) return b.year.compareTo(a.year);
                      return b.month.compareTo(a.month);
                    });

              if (historyBudgets.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No budget history',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Previous budgets will appear here',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: historyBudgets.take(5).map((budget) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.formattedDate,
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Budget: \$${budget.amount.toStringAsFixed(0)}',
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Stream<List<Budget>> _getBudgetHistoryStream() {
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );
    return firebaseService.getBudgetHistoryStream();
  }
}
