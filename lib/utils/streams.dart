import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'currency_utils.dart';
import 'category_utils.dart';

final _theFirestore = FirebaseFirestore.instance;

class TransactionsStreams extends StatelessWidget {
  const TransactionsStreams({super.key, this.limit});

  final int? limit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;
    final mutedColor = isDark
        ? const Color(0XFF6B7280)
        : const Color(0xFF6B7280);
    final borderColor = isDark
        ? const Color(0xFF2A3150)
        : const Color(0xFFE5E7EB);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();
    return WalletCurrencyBuilder(
      builder: (context, currencySymbol) {
        Query query = _theFirestore
            .collection('wallet')
            .doc(user.uid)
            .collection('expenses')
            .orderBy('date', descending: true);
        if (limit != null) {
          query = query.limit(limit!);
        }
        return StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    SizedBox(height: 24),
                    Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFF4B5563),
                      size: 40,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "No Transactions Yet",
                      style: TextStyle(color: mutedColor, fontSize: 14),
                    ),
                  ],
                ),
              );
            }
            final transactionDocs = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: transactionDocs.length,
              primary: false,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final data =
                    transactionDocs[index].data() as Map<String, dynamic>;
                final name = data['name'] ?? 'No Name';
                final String category = normalizeCategory(
                  (data['category'] ?? 'general').toString(),
                );
                final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                final timestamp = data['date'] as Timestamp?;
                final date = timestamp != null
                    ? "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}"
                    : "No date";

                final iconColor = colorForCategory(category);
                final iconBg = iconBackgroundForCategory(category);
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          iconForCategory(category),
                          color: iconColor,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: titleColor,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              displayCategory(category),
                              style: TextStyle(fontSize: 11, color: iconColor),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCurrency(
                              currencySymbol,
                              amount,
                              decimals: 0,
                              negative: true,
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFF09595),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            date,
                            style: TextStyle(fontSize: 11, color: mutedColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
