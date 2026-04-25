import 'package:flutter/material.dart';

import 'category_utils.dart';

enum BudgetHealth { onTrack, nearLimit, overLimit }

class BudgetStatusInfo {
  final BudgetHealth health;
  final String label;
  final Color color;
  final Color backgroundColor;

  const BudgetStatusInfo({
    required this.health,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });
}

String monthKeyForDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  return '${date.year}-$month';
}

String monthLabelForDate(DateTime date) {
  const monthLabels = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${monthLabels[date.month - 1]} ${date.year}';
}

String budgetDocId(String category, String monthKey) {
  final normalizedCategory = normalizeCategory(category)
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return '$monthKey-$normalizedCategory';
}

double budgetUsageRatio(double spent, double limit) {
  if (limit <= 0) return 0;
  return spent / limit;
}

double budgetProgress(double spent, double limit) {
  final ratio = budgetUsageRatio(spent, limit);
  return ratio.clamp(0.0, 1.0);
}

BudgetHealth budgetHealth(double spent, double limit) {
  final ratio = budgetUsageRatio(spent, limit);
  if (ratio > 1) {
    return BudgetHealth.overLimit;
  }
  if (ratio >= 0.8) {
    return BudgetHealth.nearLimit;
  }
  return BudgetHealth.onTrack;
}

BudgetStatusInfo budgetStatusInfo(double spent, double limit) {
  switch (budgetHealth(spent, limit)) {
    case BudgetHealth.onTrack:
      return const BudgetStatusInfo(
        health: BudgetHealth.onTrack,
        label: 'On track',
        color: Color(0xFF27AE60),
        backgroundColor: Color(0x1A27AE60),
      );
    case BudgetHealth.nearLimit:
      return const BudgetStatusInfo(
        health: BudgetHealth.nearLimit,
        label: 'Near limit',
        color: Color(0xFFF2C94C),
        backgroundColor: Color(0x1AF2C94C),
      );
    case BudgetHealth.overLimit:
      return const BudgetStatusInfo(
        health: BudgetHealth.overLimit,
        label: 'Over budget',
        color: Color(0xFFEB5757),
        backgroundColor: Color(0x1AEB5757),
      );
  }
}
