import 'package:flutter/material.dart';

class CategoryConfig {
  static const Map<String, IconData> categoryIcons = {
    'Food': Icons.restaurant_menu_rounded,
    'Transport': Icons.directions_bus_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Bills': Icons.receipt_long_rounded,
    'Health': Icons.local_hospital_rounded,
    'Travel': Icons.flight_takeoff_rounded,
    'Entertainment': Icons.movie_rounded,
    'Others': Icons.category_rounded,
    'Groceries': Icons.local_grocery_store_rounded,
    'Education': Icons.school_rounded,
    'Home': Icons.home_rounded,
    'Lend/Borrow': Icons.handshake_rounded,
  };

  static const Map<String, Color> categoryColors = {
    'Food': Colors.redAccent,
    'Transport': Colors.blueAccent,
    'Shopping': Colors.orangeAccent,
    'Bills': Colors.green,
    'Health': Colors.pinkAccent,
    'Travel': Color.fromARGB(255, 29, 134, 134),
    'Entertainment': Colors.purpleAccent,
    'Others': Colors.grey,
    'Groceries': Colors.lightGreen,
    'Education': Colors.indigoAccent,
    'Home': Colors.brown,
    'Lend/Borrow': Color.fromARGB(255, 56, 164, 139),
  };

  static List<String> get categories => categoryIcons.keys.toList();

  static List<String> get categoriesWithAll => ['All', ...categories];

  static IconData getIcon(String category) {
    return categoryIcons[category] ?? Icons.category_rounded;
  }

  static Color getColor(String category) {
    return categoryColors[category] ?? Colors.grey;
  }
}
