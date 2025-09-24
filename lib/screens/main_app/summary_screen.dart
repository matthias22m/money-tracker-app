import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/firebase_service.dart';
import '../../models/transaction.dart';
import '../../config/categories.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Transaction>>(
          stream: firebaseService.getTransactions(),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading data',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions to show',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some transactions to see your summary',
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

            final transactions = snapshot.data!;
            final monthlyTransactions = transactions
                .where(
                  (t) =>
                      t.date.month == selectedDate.month &&
                      t.date.year == selectedDate.year,
                )
                .toList();

            double totalIncome = 0;
            double totalExpense = 0;
            final Map<String, double> categorySpending = {};

            for (var t in monthlyTransactions) {
              if (t.isExpense) {
                totalExpense += t.amount;
                categorySpending.update(
                  t.category,
                  (value) => value + t.amount,
                  ifAbsent: () => t.amount,
                );
              } else {
                totalIncome += t.amount;
              }
            }

            final pieChartSections = categorySpending.entries.map((entry) {
              return PieChartSectionData(
                color: CategoryConfig.getColor(entry.key),
                value: entry.value,
                title: '${entry.key}\n\$${entry.value.toStringAsFixed(0)}',
                radius: 50,
                titleStyle: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Monthly Summary',
                    style: GoogleFonts.lato(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMMM yyyy').format(selectedDate),
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Month Picker Button
                  _buildMonthPickerButton(),
                  const SizedBox(height: 24),

                  // Summary Cards
                  _buildSummaryCard(totalIncome, totalExpense),
                  const SizedBox(height: 24),

                  // Spending Breakdown
                  Text(
                    'Spending Breakdown',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pie Chart
                  if (categorySpending.isNotEmpty) ...[
                    Container(
                      height: 250,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: PieChart(
                        PieChartData(
                          sections: pieChartSections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 50,
                          startDegreeOffset: -90,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Legend
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: categorySpending.entries
                            .map(
                              (entry) => _buildCategoryLegend(
                                entry.key,
                                entry.value,
                                CategoryConfig.getColor(entry.key),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ] else ...[
                    Container(
                      height: 250,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pie_chart_outline,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No expenses this month',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double totalIncome, double totalExpense) {
    final netBalance = totalIncome - totalExpense;
    final isPositive = netBalance >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Total Income',
            totalIncome,
            Colors.white,
            Colors.white70,
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Total Expenses',
            totalExpense,
            Colors.white,
            Colors.white70,
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Net Balance',
            netBalance,
            Colors.white,
            Colors.white70,
            isBold: true,
            isPositive: isPositive,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    double amount,
    Color titleColor,
    Color amountColor, {
    bool isBold = false,
    bool isPositive = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: titleColor,
          ),
        ),
        Row(
          children: [
            if (isBold && amount != 0)
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: titleColor,
                size: 20,
              ),
            const SizedBox(width: 4),
            Text(
              NumberFormat.currency(symbol: '\$').format(amount),
              style: GoogleFonts.lato(
                fontSize: isBold ? 20 : 18,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: amountColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryLegend(String category, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPickerButton() {
    return GestureDetector(
      onTap: _showMonthPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Change Month',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMonthPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
}
