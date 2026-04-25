import 'package:budget_buddy/models/transactions.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_buddy/utils/category_utils.dart';
import 'package:budget_buddy/services/budget_service.dart';

final _theFirestore = FirebaseFirestore.instance;

class AddTransaction extends StatefulWidget {
  const AddTransaction({super.key});
  static const String id = 'input_page';

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  final _formKey = GlobalKey<FormState>();
  final moneyController = TextEditingController();
  final dateController = TextEditingController();
  final nameController = TextEditingController();
  final customCategoryController = TextEditingController();
  String? selectedCategory;
  void _takeToFirestore(Transactions transaction) async {
    final user = FirebaseAuth.instance.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    if (user == null) return;
    try {
      await _theFirestore
          .collection('wallet')
          .doc(user.uid)
          .collection('expenses')
          .add({
            'name': transaction.name,
            'amount': transaction.amount,
            'date': Timestamp.fromDate(transaction.date),
            'category': normalizeCategory(transaction.category),
          });
      await _theFirestore.collection('wallet').doc(user.uid).update({
        'balance': FieldValue.increment(-(transaction.amount ?? 0)),
        'total_expense': FieldValue.increment(transaction.amount ?? 0),
      });
      await applyExpenseToBudget(
        userId: user.uid,
        category: transaction.category,
        amount: transaction.amount ?? 0,
        expenseDate: transaction.date,
      );
    } catch (e) {
      debugPrint("Error: $e");
      messenger.showSnackBar(const SnackBar(content: Text("Failed to Save")));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      dateController.text = picked.toString().split(' ')[0];
    }
  }

  void _showCupertinoDatePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: Color.fromARGB(255, 255, 255, 255),
        child: CupertinoDatePicker(
          initialDateTime: DateTime.now(),
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (val) {
            setState(() {
              dateController.text = val.toString().split(" ")[0];
            });
          },
        ),
      ),
    );
  }

  void _saveTransction() {
    final customCategory = normalizeCategory(customCategoryController.text);
    final categoryToSave = customCategory.isNotEmpty
        ? customCategory
        : selectedCategory;
    if (_formKey.currentState!.validate()) {
      if (categoryToSave == null || categoryToSave.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Please select a category")));
        return;
      }
      final newTransaction = Transactions(
        name: nameController.text,
        amount: double.parse(moneyController.text),
        date: DateTime.parse(dateController.text),
        category: categoryToSave,
      );
      _takeToFirestore(newTransaction);
      _formKey.currentState!.reset();
      nameController.clear();
      moneyController.clear();
      dateController.clear();
      customCategoryController.clear();
      setState(() {
        selectedCategory = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Saved")));
    }
  }

  void pickDate() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _showCupertinoDatePicker(context);
    } else {
      _selectDate(context);
    }
  }

  InputDecoration _fieldDecoration({
    required BuildContext context,
    required String label,
    required IconData icon,
    String? prefix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF111827) : Colors.grey.shade50;
    final borderColor = isDark ? const Color(0xFF374151) : Colors.grey.shade300;
    final textColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;
    final labelColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: labelColor,
      ),
      prefixIcon: Icon(icon, size: 18, color: labelColor),
      prefixText: prefix,
      prefixStyle: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;
    final sectionColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final cardColor = theme.cardColor;
    final borderColor = isDark ? const Color(0xFF374151) : Colors.grey.shade200;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Add Transaction",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: titleColor,
            fontSize: 16,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: titleColor),
        ),

        actions: [
          IconButton(
            onPressed: _saveTransction,
            icon: Icon(Icons.save),
            color: Colors.blue,
          ),
        ],
      ),
      body: WalletCurrencyBuilder(
        builder: (context, currencySymbol) => SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Track Your spending",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Add a transaction",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.0),

                Text(
                  "Details",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: sectionColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameController,
                        style: TextStyle(color: titleColor),
                        keyboardType: TextInputType.text,
                        decoration: _fieldDecoration(
                          context: context,
                          label: "Description",
                          icon: Icons.edit_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please Keep where you used";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: moneyController,
                              style: TextStyle(color: titleColor),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: _fieldDecoration(
                                context: context,
                                label: "Amount",
                                icon: Icons.payment_outlined,
                                prefix: currencySymbol,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please Keep amount";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              style: TextStyle(color: titleColor),
                              onTap: () {
                                pickDate();
                              },
                              controller: dateController,
                              decoration: _fieldDecoration(
                                context: context,
                                label: "Date",
                                icon: Icons.calendar_today_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.0),
                Text(
                  "CATEGORY",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: sectionColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 50),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kDefaultCategories.map((category) {
                    final isSelected =
                        selectedCategory == category &&
                        customCategoryController.text.trim().isEmpty;
                    return GestureDetector(
                      onTap: () => setState(() {
                        selectedCategory = category;
                        customCategoryController.clear();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 104,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade600 : cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue.shade600
                                : borderColor,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              iconForCategory(category),
                              size: 22,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              displayCategory(category),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? const Color(0xFFD1D5DB)
                                          : const Color(0xFF374151)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: customCategoryController,
                  style: TextStyle(color: titleColor),
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      _fieldDecoration(
                        context: context,
                        label: "Custom category",
                        icon: Icons.add_chart_outlined,
                      ).copyWith(
                        helperText: "Use this to create any category you want",
                      ),
                  onChanged: (value) {
                    if (value.trim().isNotEmpty && selectedCategory != null) {
                      setState(() {
                        selectedCategory = null;
                      });
                      return;
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _saveTransction,
                    icon: Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      "Save Transaction",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
