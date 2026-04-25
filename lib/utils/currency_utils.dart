import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const String defaultCurrencySymbol = "KSh";

const List<Map<String, String>> currencyOptions = [
  {"label": "Kenyan Shilling", "symbol": "KSh"},
  {"label": "US Dollar", "symbol": r"$"},
  {"label": "Euro", "symbol": "EUR"},
  {"label": "British Pound", "symbol": "GBP"},
];

String formatCurrency(
  String symbol,
  num amount, {
  int decimals = 2,
  bool negative = false,
}) {
  final value = amount.toDouble().toStringAsFixed(decimals);
  final prefix = negative ? "-" : "";
  return "$prefix$symbol $value";
}

class WalletCurrencyBuilder extends StatelessWidget {
  const WalletCurrencyBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, String currencySymbol) builder;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return builder(context, defaultCurrencySymbol);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("wallet")
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final currency =
            (data?["currency"] as String?) ?? defaultCurrencySymbol;
        return builder(context, currency);
      },
    );
  }
}
