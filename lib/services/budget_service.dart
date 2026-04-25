import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:budget_buddy/utils/budget_utils.dart';
import 'package:budget_buddy/utils/category_utils.dart';

final FirebaseFirestore _budgetFirestore = FirebaseFirestore.instance;

CollectionReference<Map<String, dynamic>> budgetCollectionForUser(
  String userId,
) {
  return _budgetFirestore
      .collection('wallet')
      .doc(userId)
      .collection('budgets');
}

Query<Map<String, dynamic>> monthlyBudgetQuery(
  String userId, {
  DateTime? date,
}) {
  final targetDate = date ?? DateTime.now();
  return budgetCollectionForUser(
    userId,
  ).where('monthKey', isEqualTo: monthKeyForDate(targetDate));
}

Future<void> applyExpenseToBudget({
  required String userId,
  required String category,
  required double amount,
  required DateTime expenseDate,
}) async {
  final normalizedCategory = normalizeCategory(category);
  if (normalizedCategory.isEmpty || amount <= 0) {
    return;
  }

  final budgetSnapshot = await budgetCollectionForUser(
    userId,
  ).where('monthKey', isEqualTo: monthKeyForDate(expenseDate)).get();

  final matchingBudget = budgetSnapshot.docs.where((doc) {
    final data = doc.data();
    return normalizeCategory((data['category'] ?? '').toString()) ==
        normalizedCategory;
  });

  if (matchingBudget.isEmpty) {
    return;
  }

  await matchingBudget.first.reference.set({
    'spent': FieldValue.increment(amount),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

Future<void> saveMonthlyBudget({
  required String userId,
  required String category,
  required double limit,
  DateTime? date,
}) async {
  final normalizedCategory = normalizeCategory(category);
  final targetDate = date ?? DateTime.now();
  final monthKey = monthKeyForDate(targetDate);
  final docId = budgetDocId(normalizedCategory, monthKey);
  final budgetDoc = budgetCollectionForUser(userId).doc(docId);
  final existingBudget = await budgetDoc.get();
  final currentSpent =
      (existingBudget.data()?['spent'] as num?)?.toDouble() ?? 0;

  await budgetDoc.set({
    'category': normalizedCategory,
    'limit': limit,
    'spent': currentSpent,
    'monthKey': monthKey,
    'monthLabel': monthLabelForDate(targetDate),
    'updatedAt': FieldValue.serverTimestamp(),
    if (!existingBudget.exists) 'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

Future<void> deleteBudget({
  required String userId,
  required String category,
  DateTime? date,
}) async {
  final normalizedCategory = normalizeCategory(category);
  final targetDate = date ?? DateTime.now();
  final docId = budgetDocId(normalizedCategory, monthKeyForDate(targetDate));
  await budgetCollectionForUser(userId).doc(docId).delete();
}

Future<void> resetAllBudgetSpent(String userId) async {
  final budgetDocs = await budgetCollectionForUser(userId).get();
  final batch = _budgetFirestore.batch();

  for (final doc in budgetDocs.docs) {
    batch.update(doc.reference, {
      'spent': 0.0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
}
