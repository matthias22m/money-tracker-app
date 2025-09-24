import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pie_chart/pie_chart.dart';

import '../../services/firebase_service.dart';
import '../../models/transaction.dart';
import 'history_screen.dart';
import '../../config/categories.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return StreamBuilder<List<Transaction>>(
      stream: firebaseService.getTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final transactions = snapshot.data ?? [];

        // Calculate totals

        final totalExpenses = transactions
            .where((t) => t.isExpense)
            .fold(0.0, (sum, item) => sum + item.amount);

        final recentTransactions = transactions.take(5).toList();

        // Calculate spending by category
        final Map<String, double> categorySpending = {};

        for (final transaction in transactions.where((t) => t.isExpense)) {
          final category = transaction.category;
          categorySpending[category] =
              (categorySpending[category] ?? 0) + transaction.amount;
        }

        // Convert to percentages for pie chart
        final totalSpending = categorySpending.values.fold(
          0.0,
          (sum, amount) => sum + amount,
        );
        final Map<String, double> dataMap = {};
        if (totalSpending > 0) {
          categorySpending.forEach((category, amount) {
            dataMap[category] = (amount / totalSpending * 100);
          });
        }

        final colorList = dataMap.keys
            .map((category) => CategoryConfig.getColor(category))
            .toList();

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(firebaseService, context),
                  const SizedBox(height: 30),
                  _buildTotalSpentCard(totalExpenses, context),
                  const SizedBox(height: 30),
                  _buildSpendingByCategory(
                    context,
                    dataMap,
                    colorList,
                    categorySpending,
                  ),
                  const SizedBox(height: 20),
                  _buildRecentTransactions(recentTransactions, context),
                  const SizedBox(height: 20),
                  _buildBottomInfoCards(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Header Widget: "Hello, Sarah!" and Add button
  Widget _buildHeader(FirebaseService firebaseService, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello! 👋',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Track your expenses wisely',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // You can add notifications functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Notifications coming soon!',
                    style: GoogleFonts.lato(),
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Total Spent Card Widget
  Widget _buildTotalSpentCard(double totalExpenses, BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final now = DateTime.now();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day + 1;

    return StreamBuilder(
      stream: firebaseService.getCurrentBudgetStream(),
      builder: (context, budgetSnapshot) {
        final budget = budgetSnapshot.data;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Spent This Month',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to budget screen
                      Navigator.pushNamed(context, '/budget');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            budget == null ? Icons.add : Icons.edit,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            budget == null ? 'Set Budget' : 'Manage Budget',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '\$${totalExpenses.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (budget != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget: \$${budget.amount.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Remaining: \$${(budget.amount - totalExpenses).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: (budget.amount - totalExpenses) >= 0
                            ? Colors.white70
                            : Colors.red[200],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$daysLeft days left',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${((totalExpenses / budget.amount) * 100).clamp(0, 100).toStringAsFixed(1)}% used',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'No budget set',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '$daysLeft days left in month',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Spending by Category Widget: Includes Chart and Legend
  Widget _buildSpendingByCategory(
    BuildContext context,
    Map<String, double> dataMap,
    List<Color> colorList,
    Map<String, double> categorySpending,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spending by Category',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              child: Text(
                DateFormat.yMMMM().format(DateTime.now()),
                style: GoogleFonts.lato(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
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
          child: dataMap.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No spending data yet'),
                  ),
                )
              : Row(
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: PieChart(
                        dataMap: dataMap,
                        animationDuration: const Duration(milliseconds: 800),
                        chartLegendSpacing: 32,
                        chartRadius: 75,
                        colorList: colorList,
                        initialAngleInDegree: 0,
                        chartType: ChartType.ring,
                        ringStrokeWidth: 20,
                        centerText: "",
                        legendOptions: const LegendOptions(showLegends: false),
                        chartValuesOptions: const ChartValuesOptions(
                          showChartValueBackground: false,
                          showChartValues: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: dataMap.entries.map((entry) {
                          final category = entry.key;
                          final percentage = entry.value;
                          final amount = categorySpending[category] ?? 0.0;
                          final color = CategoryConfig.getColor(category);
                          return _buildLegendItem(
                            color,
                            category,
                            '\$${amount.toStringAsFixed(0)}',
                            '${percentage.toStringAsFixed(0)}%',
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // A single legend item
  Widget _buildLegendItem(
    Color color,
    String title,
    String amount,
    String percentage,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.lato(fontSize: 14)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.lato(fontWeight: FontWeight.bold),
              ),
              Text(
                percentage,
                style: GoogleFonts.lato(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Recent Transactions List Widget
  Widget _buildRecentTransactions(
    List<Transaction> transactions,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
              child: Text(
                'View All',
                style: GoogleFonts.lato(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (transactions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No recent transactions'),
            ),
          )
        else
          ...transactions.map(
            (transaction) => _buildTransactionItem(
              CategoryConfig.getIcon(transaction.category),
              CategoryConfig.getColor(transaction.category),
              transaction.title,
              transaction.category,
              '${transaction.isExpense ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
            ),
          ),
      ],
    );
  }

  // A single transaction list item
  Widget _buildTransactionItem(
    IconData icon,
    Color color,
    String title,
    String category,
    String amount,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 1,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(category, style: GoogleFonts.lato()),
        trailing: Text(
          amount,
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  // Bottom summary cards
  Widget _buildBottomInfoCards(BuildContext context) {
    final now = DateTime.now();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day + 1;
    final firebaseService = Provider.of<FirebaseService>(context);

    return StreamBuilder<Map<String, double>>(
      stream: firebaseService.getMonthlyComparisonStream(),
      builder: (context, snapshot) {
        double percentageChange = 0.0;
        bool isIncrease = true;
        Color trendColor = Colors.green;
        IconData trendIcon = Icons.trending_up;

        if (snapshot.hasData) {
          final data = snapshot.data!;
          final currentMonth = data['current']!;
          final previousMonth = data['previous']!;

          if (previousMonth > 0) {
            percentageChange =
                ((currentMonth - previousMonth) / previousMonth) * 100;
            isIncrease = percentageChange >= 0;
            trendColor = isIncrease ? Colors.green : Colors.red;
            trendIcon = isIncrease ? Icons.trending_up : Icons.trending_down;
          } else if (currentMonth > 0) {
            percentageChange = 100.0; // First month with expenses
            isIncrease = true;
            trendColor = Colors.green;
            trendIcon = Icons.trending_up;
          }
        }

        return Row(
          children: [
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 1,
                shadowColor: Colors.grey.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(trendIcon, color: trendColor, size: 28),
                      SizedBox(height: 8),
                      Text(
                        '${isIncrease ? '+' : ''}${percentageChange.toStringAsFixed(1)}%',
                        style: GoogleFonts.lato(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: trendColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'vs Last Month',
                        style: GoogleFonts.lato(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 1,
                shadowColor: Colors.grey.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '$daysLeft',
                        style: GoogleFonts.lato(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Days Left',
                        style: GoogleFonts.lato(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
