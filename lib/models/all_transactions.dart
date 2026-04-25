import 'package:flutter/material.dart';
import 'package:budget_buddy/utils/streams.dart';

class AllTransactions extends StatelessWidget {
  const AllTransactions({super.key});
  static const String id = 'all_transactions';

  @override
  Widget build(BuildContext context) {
    final titleColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF9FAFB)
        : Colors.black87;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "All Transactions",
          style: TextStyle(
            color: titleColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: titleColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: const TransactionsStreams(),
      ),
    );
  }
}
