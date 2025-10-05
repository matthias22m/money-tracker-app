import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SharedExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _collection(String appId) {
    return _firestore.collection('artifacts/$appId/sharedExpenses');
  }

  Future<String?> _uid() async => _auth.currentUser?.uid;

  Future<void> logSharedExpense({
    required String appId,
    required String borrowerId,
    required double amount,
    required String description,
    required String lenderUsername,
    required String borrowerUsername,
  }) async {
    final lenderId = await _uid();
    if (lenderId == null) throw Exception('User not authenticated');

    await _collection(appId).add({
      'lenderId': lenderId,
      'borrowerId': borrowerId,
      'amount': amount,
      'description': description,
      // Approval flow: initial state requires borrower acceptance
      'status': 'pending_approval',
      'createdAt': FieldValue.serverTimestamp(),
      'lenderUsername': lenderUsername,
      'borrowerUsername': borrowerUsername,
    });
  }

  // Active debts where I am lender
  Stream<QuerySnapshot<Map<String, dynamic>>> owedToMe({
    required String appId,
  }) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _collection(appId)
        .where('lenderId', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Active debts where I am borrower
  Stream<QuerySnapshot<Map<String, dynamic>>> iOwe({required String appId}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _collection(appId)
        .where('borrowerId', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Pending approvals for current borrower
  Stream<QuerySnapshot<Map<String, dynamic>>> pendingApprovals({
    required String appId,
  }) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _collection(appId)
        .where('borrowerId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending_approval')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Pending settlements that I need to confirm (initiated by the other party)
  Future<void> acceptDebt({required String appId, required String expenseId}) {
    return _collection(appId).doc(expenseId).update({'status': 'active'});
  }

  Future<void> rejectDebt({required String appId, required String expenseId}) {
    return _collection(appId).doc(expenseId).delete();
  }
}
