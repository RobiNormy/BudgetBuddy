import 'package:flutter/material.dart';

const List<String> kDefaultCategories = <String>[
  'food',
  'transport',
  'entertainment',
];

const List<String> kBudgetCategoryOptions = <String>[
  'food',
  'transport',
  'entertainment',
  'shopping',
  'rent',
  'bills',
  'health',
  'education',
  'travel',
];

const List<Color> kCategoryPalette = <Color>[
  Color(0xFF5DCAA5),
  Color(0xFF378ADD),
  Color(0xFFF0997B),
  Color(0xFFF2C94C),
  Color(0xFFBB6BD9),
  Color(0xFF27AE60),
  Color(0xFFEB5757),
  Color(0xFF56CCF2),
];

String normalizeCategory(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

String displayCategory(String value) {
  final normalized = normalizeCategory(value);
  if (normalized.isEmpty) return 'Uncategorized';
  return normalized
      .split(' ')
      .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

IconData iconForCategory(String category) {
  switch (normalizeCategory(category)) {
    case 'food':
      return Icons.restaurant;
    case 'transport':
      return Icons.directions_car;
    case 'entertainment':
      return Icons.movie;
    case 'shopping':
      return Icons.shopping_bag_outlined;
    case 'rent':
      return Icons.home_outlined;
    case 'bills':
      return Icons.receipt_long_outlined;
    case 'health':
      return Icons.favorite_outline;
    case 'education':
      return Icons.school_outlined;
    case 'travel':
      return Icons.flight_takeoff;
    default:
      return Icons.label_outline;
  }
}

Color colorForCategory(String category) {
  final normalized = normalizeCategory(category);
  switch (normalized) {
    case 'food':
      return const Color(0xFF5DCAA5);
    case 'transport':
      return const Color(0xFF378ADD);
    case 'entertainment':
      return const Color(0xFFF0997B);
    default:
      final hash = normalized.isEmpty ? 0 : normalized.hashCode;
      final index = hash.abs() % kCategoryPalette.length;
      return kCategoryPalette[index];
  }
}

Color iconBackgroundForCategory(String category) {
  final base = colorForCategory(category);
  return Color.alphaBlend(base.withValues(alpha: 0.18), const Color(0xFF111827));
}

Map<String, double> buildCategoryTotals(Iterable<Map<String, dynamic>> items) {
  final totals = <String, double>{};
  for (final data in items) {
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final category = normalizeCategory((data['category'] ?? '').toString());
    final key = category.isEmpty ? 'uncategorized' : category;
    totals[key] = (totals[key] ?? 0) + amount;
  }
  totals.removeWhere((_, value) => value <= 0);
  return totals;
}
