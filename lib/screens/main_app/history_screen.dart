import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../services/firebase_service.dart';
import '../../models/transaction.dart';
import '../../config/categories.dart';
import '../../core/theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  String _selectedType = 'All'; // 'All', 'Income', 'Expense'
  String _selectedCategory = 'All'; // 'All', 'Food', 'Transport', etc.
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            backgroundBlendMode: BlendMode.color,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
            ),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
            cursorColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Transaction>>(
        stream: firebaseService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allTransactions = snapshot.data ?? [];

          // Month range filter (default: current month)
          final startOfMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month,
            1,
          );
          final endOfMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month + 1,
            0,
            23,
            59,
            59,
          );
          final monthFiltered = allTransactions.where((t) {
            return t.date.isAfter(
                  startOfMonth.subtract(const Duration(milliseconds: 1)),
                ) &&
                t.date.isBefore(
                  endOfMonth.add(const Duration(milliseconds: 1)),
                );
          }).toList();

          // Apply filters
          final filteredTransactions = monthFiltered.where((transaction) {
            final matchesSearch = transaction.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

            final matchesType =
                _selectedType == 'All' ||
                (_selectedType == 'Income' && !transaction.isExpense) ||
                (_selectedType == 'Expense' && transaction.isExpense);

            final matchesCategory =
                _selectedCategory == 'All' ||
                transaction.category == _selectedCategory;

            return matchesSearch && matchesType && matchesCategory;
          }).toList();

          return Column(
            children: [
              // Month Selector
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          final prevMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month - 1,
                            1,
                          );
                          _selectedMonth = DateTime(
                            prevMonth.year,
                            prevMonth.month,
                          );
                        });
                      },
                    ),
                    Text(
                      DateFormat.yMMMM().format(_selectedMonth),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          final nextMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month + 1,
                            1,
                          );
                          _selectedMonth = DateTime(
                            nextMonth.year,
                            nextMonth.month,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Filter Buttons
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = 'All';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedType == 'All'
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'All',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedType == 'All'
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = 'Income';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedType == 'Income'
                                ? context.incomeColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Income',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedType == 'Income'
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = 'Expense';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedType == 'Expense'
                                ? context.expenseColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Expense',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedType == 'Expense'
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Category Filter Dropdown
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: CategoryConfig.categoriesWithAll.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          if (value != 'All') ...[
                            Icon(
                              CategoryConfig.getIcon(value),
                              color: CategoryConfig.getColor(value),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Transaction List
              if (filteredTransactions.isEmpty)
                const Expanded(
                  child: Center(child: Text('No matching transactions found.')),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredTransactions.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      final color = transaction.isExpense
                          ? context.expenseColor
                          : context.incomeColor;
                      final icon = transaction.isExpense
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded;

                      return Slidable(
                        key: Key(transaction.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.3,
                          children: [
                            // Edit Button
                            SlidableAction(
                              onPressed: (context) =>
                                  _editTransaction(transaction),
                              backgroundColor: const Color(0xFF4A90E2),
                              foregroundColor: Colors.white,
                              icon: Icons.edit_rounded,
                              label: 'Edit',
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                              flex: 1,
                              autoClose: true,
                            ),
                            // Delete Button
                            SlidableAction(
                              onPressed: (context) async {
                                final confirmed = await _showDeleteConfirmation(
                                  context,
                                  transaction,
                                );
                                if (confirmed == true) {
                                  _deleteTransaction(transaction.id);
                                }
                              },
                              backgroundColor: const Color(0xFFE74C3C),
                              foregroundColor: Colors.white,
                              icon: Icons.delete_rounded,
                              label: 'Delete',
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              flex: 1,
                              autoClose: true,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Material(
                            color: Theme.of(context).cardTheme.color,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.1),
                                child: Icon(icon, color: color),
                              ),
                              title: Text(
                                transaction.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(transaction.category),
                                  Text(
                                    DateFormat.yMMMd().format(transaction.date),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                '${transaction.isExpense ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    Transaction transaction,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: Text(
            'Are you sure you want to delete "${transaction.title}"?\n\nThis action cannot be undone.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTransaction(String transactionId) async {
    try {
      final firebaseService = Provider.of<FirebaseService>(
        context,
        listen: false,
      );
      await firebaseService.deleteTransaction(transactionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Transaction deleted successfully!'),
              ],
            ),
            backgroundColor: context.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to delete transaction: $e')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _editTransaction(Transaction transaction) async {
    // Navigate to AddExpenseScreen with pre-filled data for editing
    final result = await Navigator.pushNamed(
      context,
      '/add-expense',
      arguments: {'transaction': transaction, 'isEditing': true},
    );

    // If the transaction was updated, show a success message
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Transaction updated successfully!')),
            ],
          ),
          backgroundColor: context.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
