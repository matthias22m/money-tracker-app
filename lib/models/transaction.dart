import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final bool isExpense;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.isExpense,
  });

  // Factory constructor to create a Transaction from a Firestore document
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] ?? 'Other',
      isExpense: data['isExpense'] ?? true,
    );
  }

  // Method to convert a Transaction to a Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'isExpense': isExpense,
    };
  }
}
