import 'package:budget_buddy/screens/all_screens.dart';
import 'package:budget_buddy/screens/home/home.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _wallet = FirebaseFirestore.instance;

String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

class MyWallet extends StatefulWidget {
  const MyWallet({super.key});
  static final String id = "wallet_id";

  @override
  State<MyWallet> createState() => _MyWalletState();
}

class _MyWalletState extends State<MyWallet> {
  final amountController = TextEditingController();
  String _selectedCurrency = defaultCurrencySymbol;
  bool _loading = false;

  Future<void> createWallet() async {
    if (amountController.text.isEmpty) return;

    if (userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: User not authenticated")),
        );
      }
      return;
    }

    setState(() {
      _loading = true;
    });
    try {
      await _wallet.collection("wallet").doc(userId).set({
        'balance': double.parse(amountController.text),
        'total_expense': 0.0,
        'currency': _selectedCurrency,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_launch', false);
      await prefs.setBool('tutorial_shown', false);
      await prefs.setBool('hasSeen', true);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          MainWrapper.id,
          (route) => false,
          arguments: {'showTutorial': true},
        );
      }
    } catch (e) {
      debugPrint("Firebase Error $e");
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: WalletCurrencyBuilder(
        builder: (context, currencySymbol) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome to\nBudget Buddy",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF9FAFB),
                  height: 1.2,
                ),
              ),
              SizedBox(height: 40),
              Text(
                "CURRENCY",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 8),
              InkWell(
                onTap: _showCurrencyPicker,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0XFF1A2035),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0XFF2A3150)),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: Color(0xFF5DCAA5),
                        size: 18,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedCurrency,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFF9FAFB),
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Color(0XFF1A2035),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0XFF2A3150)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      _selectedCurrency,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Color(0XFF6B7280),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0XFFF9FAFB),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "0.00",
                          hintStyle: TextStyle(color: Color(0XFF374151)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : createWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF378ADD),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Set up my wallet",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Choose currency",
                  style: TextStyle(
                    color: Color(0xFFF9FAFB),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...currencyOptions.map((currency) {
                  final symbol = currency["symbol"]!;
                  final label = currency["label"]!;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    title: Text(
                      label,
                      style: const TextStyle(color: Color(0xFFF9FAFB)),
                    ),
                    subtitle: Text(
                      symbol,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    trailing: symbol == _selectedCurrency
                        ? const Icon(
                            Icons.check,
                            color: Color(0xFF378ADD),
                            size: 18,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCurrency = symbol;
                      });
                      Navigator.pop(sheetContext);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class WalletStream extends StatelessWidget {
  const WalletStream({super.key});
  static final String id = "wallet_stream";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _wallet.collection("wallet").doc(userId).snapshots(),

      // .map((doc)=>(doc.data()?['balance']??0.0).toDouble()),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Text(
                "Error ${snapshot.error}",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF378ADD)),
            ),
          );
        }
        if (!snapshot.data!.exists) {
          return MyWallet();
        }
        return HomeScreen();
      },
    );
  }
}

class TopUpSheet extends StatefulWidget {
  const TopUpSheet({super.key});

  @override
  State<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<TopUpSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _loading = false;

  Future<void> _topUp() async {
    final messenger = ScaffoldMessenger.of(context);
    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Enter a valid amount to top up")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _wallet.collection('wallet').doc(userId).collection('topups').add({
        'amount': amount,
        'note': _noteController.text.isEmpty ? 'Top up' : _noteController.text,
        'date': Timestamp.now(),
      });
      await _wallet.collection('wallet').doc(userId).set({
        'balance': FieldValue.increment(amount),
      }, SetOptions(merge: true));
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text("Wallet topped up successfully")),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint("Error $e");
      messenger.showSnackBar(
        const SnackBar(content: Text("Failed to top up wallet")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WalletCurrencyBuilder(
      builder: (context, currencySymbol) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3150),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Top up wallet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF9FAFB),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Add money to your wallet",
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),

            const Text(
              "AMOUNT",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A3150)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    currencySymbol,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF9FAFB),
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "0.00",
                        hintStyle: TextStyle(color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "NOTE (OPTIONAL)",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A3150)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _noteController,
                style: const TextStyle(fontSize: 14, color: Color(0xFFF9FAFB)),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "optional",
                  hintStyle: TextStyle(color: Color(0xFF374151), fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "QUICK ADD",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [1000, 5000, 10000, 20000].map((amount) {
                final isLast = amount == 20000;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(
                      () => _amountController.text = amount.toString(),
                    ),
                    child: Container(
                      margin: EdgeInsets.only(right: isLast ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2A3150)),
                      ),
                      child: Text(
                        "${amount ~/ 1000}K",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF378ADD),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _topUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Add to wallet",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
