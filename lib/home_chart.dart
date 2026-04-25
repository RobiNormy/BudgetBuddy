import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'utils/currency_utils.dart';
import 'utils/category_utils.dart';

class DonutChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> categories;
  final double total;

  DonutChartPainter({required this.categories, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        min(size.width / 2, size.height / 2) - (paint.strokeWidth / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (total == 0) {
      paint.color = const Color(0xFF2A3150);
      canvas.drawArc(rect, 0, 2 * pi, false, paint);
      return;
    }

    double startAngle = -pi / 2;

    for (final entry in categories) {
      if (entry.value <= 0) {
        continue;
      }
      paint.color = colorForCategory(entry.key);
      final sweepAngle = (entry.value / total) * 2 * pi;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CustomCategoryChart extends StatelessWidget {
  final Map<String, double> categoryTotals;

  const CustomCategoryChart({super.key, required this.categoryTotals});

  @override
  Widget build(BuildContext context) {
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final double total = entries.fold<double>(
      0,
      (runningTotal, entry) => runningTotal + entry.value,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0xFF2A3150)
        : const Color(0xFFE5E7EB);

    return WalletCurrencyBuilder(
      builder: (context, currencySymbol) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CustomPaint(
                      painter: DonutChartPainter(
                        categories: entries,
                        total: total,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Total Spent",
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF4B5563),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency(currencySymbol, total, decimals: 0),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            ...entries
                .take(6)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildCategoryBar(
                      context: context,
                      currencySymbol: currencySymbol,
                      title: displayCategory(entry.key),
                      amount: entry.value,
                      total: total,
                      color: colorForCategory(entry.key),
                      icon: iconForCategory(entry.key),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar({
    required BuildContext context,
    required String currencySymbol,
    required String title,
    required double amount,
    required double total,
    required Color color,
    required IconData icon,
  }) {
    final double percentage = total == 0 ? 0 : amount / total;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFF9FAFB) : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Text(
              formatCurrency(currencySymbol, amount, decimals: 0),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2A3150),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 8,
                  width: constraints.maxWidth * percentage,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class HomeChartPreview extends StatelessWidget {
  const HomeChartPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (user == null) return const SizedBox();
    return WalletCurrencyBuilder(
      builder: (context, currencySymbol) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('wallet')
            .doc(user.uid)
            .collection('expenses')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF378ADD)),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No data",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
            );
          }

          final expenseData = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
          final categoryTotals = buildCategoryTotals(expenseData);
          final categories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final total = categories.fold<double>(
            0,
            (runningTotal, entry) => runningTotal + entry.value,
          );

          return SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CustomPaint(
                    painter: DonutChartPainter(
                      categories: categories,
                      total: total,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Spent",
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF4B5563),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      formatCurrency(currencySymbol, total, decimals: 0),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
