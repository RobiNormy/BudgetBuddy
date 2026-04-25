import 'package:budget_buddy/utils/budget_utils.dart';
import 'package:budget_buddy/utils/category_utils.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:flutter/material.dart';

class BudgetStatusChip extends StatelessWidget {
  final BudgetStatusInfo status;

  const BudgetStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class BudgetProgressCard extends StatelessWidget {
  final String category;
  final double limit;
  final double spent;
  final String currencySymbol;
  final Widget? trailing;
  final String? subtitle;

  const BudgetProgressCard({
    super.key,
    required this.category,
    required this.limit,
    required this.spent,
    required this.currencySymbol,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;
    final mutedColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final status = budgetStatusInfo(spent, limit);
    final progress = budgetProgress(spent, limit);
    final remaining = limit - spent;
    final iconColor = colorForCategory(category);
    final iconBg = iconBackgroundForCategory(category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3150) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconForCategory(category),
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayCategory(category),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle ??
                          '${formatCurrency(currencySymbol, spent, decimals: 0)} of ${formatCurrency(currencySymbol, limit, decimals: 0)}',
                      style: TextStyle(fontSize: 12, color: mutedColor),
                    ),
                  ],
                ),
              ),
              ...switch (trailing) {
                final Widget trailingWidget => <Widget>[trailingWidget],
                _ => <Widget>[],
              },
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              BudgetStatusChip(status: status),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  remaining >= 0
                      ? '${formatCurrency(currencySymbol, remaining, decimals: 0)} left'
                      : '${formatCurrency(currencySymbol, remaining.abs(), decimals: 0)} over',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: status.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(status.color),
            ),
          ),
        ],
      ),
    );
  }
}
