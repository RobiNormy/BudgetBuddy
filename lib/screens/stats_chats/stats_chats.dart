import 'package:budget_buddy/services/budget_service.dart';
import 'package:budget_buddy/utils/budget_utils.dart';
import 'package:budget_buddy/widgets/budget_widgets.dart';
import 'package:budget_buddy/utils/category_utils.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});
  static const String id = "stats_page";

  static const List<String> _weekdayLabels = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _monthLabels = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;
    final labelColor = const Color(0xFF6B7280);
    final borderColor = isDark
        ? const Color(0xFF2A3150)
        : const Color(0xFFE5E7EB);
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "Statistics",
          style: TextStyle(
            color: titleColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: WalletCurrencyBuilder(
        builder: (context, currencySymbol) => StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('wallet')
              .doc(user.uid)
              .collection('expenses')
              .snapshots(),
          builder: (context, expenseSnapshot) {
            if (!expenseSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF378ADD)),
              );
            }

            final docs = expenseSnapshot.data!.docs;
            final expenseData = docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
            final categoryTotals = buildCategoryTotals(expenseData);
            final sortedEntries = categoryTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final totalAll = sortedEntries.fold<double>(
              0,
              (runningTotal, entry) => runningTotal + entry.value,
            );
            final chartEntries = sortedEntries.take(6).toList();
            final dailySpending = _buildDailySpending(expenseData);
            final monthlySpending = _buildMonthlySpending(expenseData);
            final currentMonthSummary = _buildCurrentMonthSummary(expenseData);

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: monthlyBudgetQuery(user.uid).snapshots(),
              builder: (context, budgetSnapshot) {
                final budgetDocs = budgetSnapshot.data?.docs ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total spent",
                              style: TextStyle(
                                fontSize: 11,
                                color: labelColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatCurrency(currencySymbol, totalAll),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${docs.length} transactions",
                              style: TextStyle(fontSize: 12, color: labelColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        label: "MONTHLY BUDGETS",
                        trailing: TextButton.icon(
                          onPressed: () =>
                              _showBudgetSheet(context, userId: user.uid),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text("Add budget"),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _BudgetSection(
                        currencySymbol: currencySymbol,
                        labelColor: labelColor,
                        borderColor: borderColor,
                        budgets: budgetDocs,
                        onEdit: (category, limit) => _showBudgetSheet(
                          context,
                          userId: user.uid,
                          initialCategory: category,
                          initialLimit: limit,
                        ),
                        onDelete: (category) => _confirmBudgetDelete(
                          context,
                          userId: user.uid,
                          category: category,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "THIS MONTH",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SummaryMetric(
                                label: "Spent this month",
                                value: formatCurrency(
                                  currencySymbol,
                                  currentMonthSummary.totalSpent,
                                ),
                                accentColor: const Color(0xFF378ADD),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SummaryMetric(
                                label: "Top category",
                                value: currentMonthSummary.topCategoryLabel,
                                accentColor:
                                    currentMonthSummary.topCategoryColor,
                                helper: formatCurrency(
                                  currencySymbol,
                                  currentMonthSummary.topCategoryAmount,
                                  decimals: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "SPENDING BREAKDOWN",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: totalAll == 0
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    "No expenses yet",
                                    style: TextStyle(color: labelColor),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  SizedBox(
                                    height: 200,
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 3,
                                        centerSpaceRadius: 55,
                                        sections: chartEntries
                                            .map(
                                              (entry) => PieChartSectionData(
                                                value: entry.value,
                                                color: colorForCategory(
                                                  entry.key,
                                                ),
                                                radius: 30,
                                                showTitle: false,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ...chartEntries.asMap().entries.map((item) {
                                    final index = item.key;
                                    final entry = item.value;
                                    final percentage = totalAll > 0
                                        ? (entry.value / totalAll * 100)
                                        : 0.0;
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: index == chartEntries.length - 1
                                            ? 0
                                            : 12,
                                      ),
                                      child: _CategoryRow(
                                        icon: iconForCategory(entry.key),
                                        label: displayCategory(entry.key),
                                        currencySymbol: currencySymbol,
                                        amount: entry.value,
                                        percentage: percentage,
                                        color: colorForCategory(entry.key),
                                        bgColor: iconBackgroundForCategory(
                                          entry.key,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "DAILY SPENDING",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: _TimeBarChart(
                          points: dailySpending,
                          labelColor: labelColor,
                          borderColor: borderColor,
                          barColor: const Color(0xFF378ADD),
                          emptyLabel: "No spending recorded in the last 7 days",
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "MONTHLY SPENDING",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: _TimeBarChart(
                          points: monthlySpending,
                          labelColor: labelColor,
                          borderColor: borderColor,
                          barColor: const Color(0xFF5DCAA5),
                          emptyLabel:
                              "No spending recorded in the last 6 months",
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "CATEGORY COMPARISON",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: SizedBox(
                          height: 200,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: ((chartEntries.length * 72).clamp(
                                240,
                                560,
                              )).toDouble(),
                              child: BarChart(
                                BarChartData(
                                  backgroundColor: Colors.transparent,
                                  borderData: FlBorderData(show: false),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (_) => FlLine(
                                      color: borderColor,
                                      strokeWidth: 0.5,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < 0 ||
                                              index >= chartEntries.length) {
                                            return const SizedBox.shrink();
                                          }
                                          final label = displayCategory(
                                            chartEntries[index].key,
                                          );
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Text(
                                              label.length > 10
                                                  ? '${label.substring(0, 10)}...'
                                                  : label,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: labelColor,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  barGroups: chartEntries.asMap().entries.map((
                                    item,
                                  ) {
                                    final index = item.key;
                                    final entry = item.value;
                                    return BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: entry.value,
                                          color: colorForCategory(entry.key),
                                          width: 32,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required String label, Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 1.2,
          ),
        ),
        ...switch (trailing) {
          final Widget trailingWidget => <Widget>[trailingWidget],
          _ => <Widget>[],
        },
      ],
    );
  }

  List<_SpendPoint> _buildDailySpending(
    List<Map<String, dynamic>> expenseData,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final points = <_SpendPoint>[];

    for (int offset = 6; offset >= 0; offset--) {
      final day = today.subtract(Duration(days: offset));
      double total = 0;
      for (final data in expenseData) {
        final timestamp = data['date'] as Timestamp?;
        final date = timestamp?.toDate();
        if (date == null) continue;
        final normalizedDate = DateTime(date.year, date.month, date.day);
        if (normalizedDate == day) {
          total += (data['amount'] as num?)?.toDouble() ?? 0;
        }
      }
      points.add(
        _SpendPoint(label: _weekdayLabels[day.weekday - 1], amount: total),
      );
    }

    return points;
  }

  List<_SpendPoint> _buildMonthlySpending(
    List<Map<String, dynamic>> expenseData,
  ) {
    final now = DateTime.now();
    final points = <_SpendPoint>[];

    for (int offset = 5; offset >= 0; offset--) {
      final monthDate = DateTime(now.year, now.month - offset, 1);
      double total = 0;
      for (final data in expenseData) {
        final timestamp = data['date'] as Timestamp?;
        final date = timestamp?.toDate();
        if (date == null) continue;
        if (date.year == monthDate.year && date.month == monthDate.month) {
          total += (data['amount'] as num?)?.toDouble() ?? 0;
        }
      }
      points.add(
        _SpendPoint(label: _monthLabels[monthDate.month - 1], amount: total),
      );
    }

    return points;
  }

  _MonthCategorySummary _buildCurrentMonthSummary(
    List<Map<String, dynamic>> expenseData,
  ) {
    final now = DateTime.now();
    double totalSpent = 0;
    final categoryTotals = <String, double>{};

    for (final data in expenseData) {
      final timestamp = data['date'] as Timestamp?;
      final date = timestamp?.toDate();
      if (date == null || date.year != now.year || date.month != now.month) {
        continue;
      }

      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final category = normalizeCategory((data['category'] ?? '').toString());
      totalSpent += amount;
      if (category.isNotEmpty) {
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }
    }

    if (categoryTotals.isEmpty) {
      return const _MonthCategorySummary(
        totalSpent: 0,
        topCategoryLabel: 'None',
        topCategoryAmount: 0,
        topCategoryColor: Color(0xFF9CA3AF),
      );
    }

    final topEntry = categoryTotals.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );

    return _MonthCategorySummary(
      totalSpent: totalSpent,
      topCategoryLabel: displayCategory(topEntry.key),
      topCategoryAmount: topEntry.value,
      topCategoryColor: colorForCategory(topEntry.key),
    );
  }

  Future<void> _showBudgetSheet(
    BuildContext context, {
    required String userId,
    String? initialCategory,
    double? initialLimit,
  }) async {
    final categoryController = TextEditingController(
      text: initialCategory != null ? displayCategory(initialCategory) : '',
    );
    final limitController = TextEditingController(
      text: initialLimit != null ? initialLimit.toStringAsFixed(0) : '',
    );
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final titleColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;
        final mutedColor = isDark
            ? const Color(0xFF9CA3AF)
            : const Color(0xFF6B7280);
        final borderColor = isDark
            ? const Color(0xFF2A3150)
            : const Color(0xFFE5E7EB);
        final categoryOptions = <String>{
          ...kBudgetCategoryOptions,
          if (initialCategory != null) normalizeCategory(initialCategory),
        }.toList()..sort();

        InputDecoration fieldDecoration({
          required String label,
          required IconData icon,
          Widget? suffixIcon,
        }) {
          return InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: mutedColor),
            prefixIcon: Icon(icon, color: mutedColor, size: 18),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? const Color(0xFF111827) : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF378ADD)),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  initialCategory == null
                      ? "Create monthly budget"
                      : "Edit monthly budget",
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  monthLabelForDate(DateTime.now()),
                  style: TextStyle(color: mutedColor, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: categoryController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: titleColor),
                  decoration: fieldDecoration(
                    label: "Category",
                    icon: Icons.label_outline,
                    suffixIcon: IconButton(
                      onPressed: () async {
                        final selected = await showModalBottomSheet<String>(
                          context: sheetContext,
                          isScrollControlled: true,
                          backgroundColor: Theme.of(sheetContext).cardColor,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (pickerContext) {
                            final pickerTitleColor =
                                Theme.of(pickerContext).brightness ==
                                    Brightness.dark
                                ? const Color(0xFFF9FAFB)
                                : Colors.black87;
                            return SafeArea(
                              child: SizedBox(
                                height:
                                    MediaQuery.of(pickerContext).size.height *
                                    0.6,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    12,
                                    12,
                                    20,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          "Choose a category",
                                          style: TextStyle(
                                            color: pickerTitleColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: categoryOptions.length,
                                          itemBuilder: (context, index) {
                                            final category =
                                                categoryOptions[index];
                                            return ListTile(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              leading: Icon(
                                                iconForCategory(category),
                                                color: colorForCategory(
                                                  category,
                                                ),
                                                size: 18,
                                              ),
                                              title: Text(
                                                displayCategory(category),
                                                style: TextStyle(
                                                  color: pickerTitleColor,
                                                ),
                                              ),
                                              onTap: () {
                                                Navigator.pop(
                                                  pickerContext,
                                                  displayCategory(category),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );

                        if (selected != null) {
                          categoryController.text = selected;
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_drop_down_circle_outlined,
                        size: 20,
                      ),
                      color: mutedColor,
                      tooltip: "Choose from list",
                    ),
                  ),
                  validator: (value) {
                    if (normalizeCategory(value ?? '').isEmpty) {
                      return "Enter a category";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  "Type your own or pick one from the list.",
                  style: TextStyle(color: mutedColor, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: limitController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: titleColor),
                  decoration: fieldDecoration(
                    label: "Budget limit",
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return "Enter a valid limit";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      await saveMonthlyBudget(
                        userId: userId,
                        category: categoryController.text,
                        limit: double.parse(limitController.text),
                      );

                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF378ADD),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      initialCategory == null ? "Save budget" : "Update budget",
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmBudgetDelete(
    BuildContext context, {
    required String userId,
    required String category,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete budget?",
          style: TextStyle(color: Color(0xFFF9FAFB), fontSize: 16),
        ),
        content: Text(
          "Remove the ${displayCategory(category)} budget for ${monthLabelForDate(DateTime.now())}.",
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () async {
              await deleteBudget(userId: userId, category: category);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Color(0xFFF09595)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSection extends StatelessWidget {
  final String currencySymbol;
  final Color labelColor;
  final Color borderColor;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> budgets;
  final void Function(String category, double limit) onEdit;
  final void Function(String category) onDelete;

  const _BudgetSection({
    required this.currencySymbol,
    required this.labelColor,
    required this.borderColor,
    required this.budgets,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          "No budgets yet. Add a monthly budget for a category and Budget Buddy will track whether you're on track, near the limit, or over budget.",
          style: TextStyle(fontSize: 13, color: labelColor, height: 1.5),
        ),
      );
    }

    final budgetEntries = budgets.map((doc) => doc.data()).toList()
      ..sort((a, b) {
        final aSpent = (a['spent'] as num?)?.toDouble() ?? 0;
        final aLimit = (a['limit'] as num?)?.toDouble() ?? 0;
        final bSpent = (b['spent'] as num?)?.toDouble() ?? 0;
        final bLimit = (b['limit'] as num?)?.toDouble() ?? 0;
        return budgetUsageRatio(
          bSpent,
          bLimit,
        ).compareTo(budgetUsageRatio(aSpent, aLimit));
      });

    final totalLimit = budgetEntries.fold<double>(
      0,
      (runningTotal, budget) =>
          runningTotal + ((budget['limit'] as num?)?.toDouble() ?? 0),
    );
    final trackedSpent = budgetEntries.fold<double>(
      0,
      (runningTotal, budget) =>
          runningTotal + ((budget['spent'] as num?)?.toDouble() ?? 0),
    );
    final onTrackCount = budgetEntries.where((budget) {
      final spent = (budget['spent'] as num?)?.toDouble() ?? 0;
      final limit = (budget['limit'] as num?)?.toDouble() ?? 0;
      return budgetHealth(spent, limit) == BudgetHealth.onTrack;
    }).length;
    final overCount = budgetEntries.where((budget) {
      final spent = (budget['spent'] as num?)?.toDouble() ?? 0;
      final limit = (budget['limit'] as num?)?.toDouble() ?? 0;
      return budgetHealth(spent, limit) == BudgetHealth.overLimit;
    }).length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: "Budgeted",
                  value: formatCurrency(currencySymbol, totalLimit),
                  accentColor: const Color(0xFF5DCAA5),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryMetric(
                  label: "Tracked spent",
                  value: formatCurrency(currencySymbol, trackedSpent),
                  accentColor: overCount > 0
                      ? const Color(0xFFEB5757)
                      : const Color(0xFF378ADD),
                  helper: '$onTrackCount / ${budgetEntries.length} on track',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...budgetEntries.map((budget) {
          final category = (budget['category'] as String?) ?? '';
          final spent = (budget['spent'] as num?)?.toDouble() ?? 0;
          final limit = (budget['limit'] as num?)?.toDouble() ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BudgetProgressCard(
              category: category,
              limit: limit,
              spent: spent,
              currencySymbol: currencySymbol,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => onEdit(category, limit),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: const Color(0xFF378ADD),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () => onDelete(category),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: const Color(0xFFF09595),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SpendPoint {
  final String label;
  final double amount;

  const _SpendPoint({required this.label, required this.amount});
}

class _MonthCategorySummary {
  final double totalSpent;
  final String topCategoryLabel;
  final double topCategoryAmount;
  final Color topCategoryColor;

  const _MonthCategorySummary({
    required this.totalSpent,
    required this.topCategoryLabel,
    required this.topCategoryAmount,
    required this.topCategoryColor,
  });
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final String? helper;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.accentColor,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;
    final labelColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper!,
            style: TextStyle(
              fontSize: 12,
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _TimeBarChart extends StatelessWidget {
  final List<_SpendPoint> points;
  final Color labelColor;
  final Color borderColor;
  final Color barColor;
  final String emptyLabel;

  const _TimeBarChart({
    required this.points,
    required this.labelColor,
    required this.borderColor,
    required this.barColor,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasSpending = points.any((point) => point.amount > 0);
    if (!hasSpending) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            emptyLabel,
            style: TextStyle(color: labelColor),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: ((points.length * 58).clamp(280, 520)).toDouble(),
          child: BarChart(
            BarChartData(
              backgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: borderColor, strokeWidth: 0.5),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          points[index].label,
                          style: TextStyle(fontSize: 11, color: labelColor),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: points.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.amount,
                      color: barColor,
                      width: 24,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String currencySymbol;
  final double amount;
  final double percentage;
  final Color color;
  final Color bgColor;

  const _CategoryRow({
    required this.icon,
    required this.label,
    required this.currencySymbol,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  Text(
                    formatCurrency(currencySymbol, amount, decimals: 0),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Stack(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3150),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: percentage / 100,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "${percentage.toStringAsFixed(1)}%",
                style: TextStyle(fontSize: 11, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
