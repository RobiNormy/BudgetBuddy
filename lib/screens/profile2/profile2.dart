import 'package:budget_buddy/widgets/profile_reusablecards.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:budget_buddy/screens/login/login.dart';
import 'package:budget_buddy/theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:budget_buddy/utils/category_utils.dart';
import 'package:budget_buddy/services/budget_service.dart';

const String _privacyPolicyUrl =
    'https://doc-hosting.flycricket.io/budgetbuddy-privacy-policy/0f0a52ad-f282-4a38-9b32-31d8a06228e6/privacy';
const String _termsUrl =
    'https://doc-hosting.flycricket.io/budgetbuddy-terms-of-use/7055e9ac-1f70-4d5b-a1e9-643c648708e1/terms';

class ProfilePage2 extends StatelessWidget {
  const ProfilePage2({super.key});

  static String id = "profile_page";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;
    final sectionColor = isDark
        ? const Color(0xFF6B7280)
        : const Color(0xFF6B7280);
    final borderColor = isDark
        ? const Color(0xFF2A3150)
        : const Color(0xFFE5E7EB);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          title: Text(
            "Profile",
            style: TextStyle(
              color: titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Text(
            "No signed-in user found.",
            style: TextStyle(
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final displayName =
        user.displayName ?? user.email?.split("@")[0] ?? "Buddy";
    final userId = user.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "Profile",
          style: TextStyle(
            color: titleColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("wallet")
            .doc(userId)
            .collection("expenses")
            .snapshots(),
        builder: (context, expenseSnapshot) {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("wallet")
                .doc(userId)
                .snapshots(),
            builder: (context, walletSnapshot) {
              final walletData =
                  walletSnapshot.data?.data() as Map<String, dynamic>?;
              final balance =
                  walletSnapshot.hasData && walletSnapshot.data!.exists
                  ? (walletData?["balance"] as num).toDouble()
                  : 0.0;
              final currencySymbol =
                  (walletData?["currency"] as String?) ?? "KSh";

              final docs = expenseSnapshot.data?.docs ?? [];
              final totalTransactions = docs.length;
              double totalSpent = 0;
              double biggestExpense = 0;
              final categoryTotals = <String, double>{};

              for (final doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data["amount"] as num?)?.toDouble() ?? 0;
                final category = normalizeCategory(
                  (data["category"] ?? "").toString(),
                );

                totalSpent += amount;
                if (amount > biggestExpense) {
                  biggestExpense = amount;
                }

                if (category.isNotEmpty) {
                  categoryTotals[category] =
                      (categoryTotals[category] ?? 0) + amount;
                }
              }

              String topCategory = "None";
              if (categoryTotals.values.any((value) => value > 0)) {
                topCategory = categoryTotals.entries
                    .reduce((a, b) => a.value > b.value ? a : b)
                    .key;
                topCategory = displayCategory(topCategory);
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeader(
                      displayName: displayName,
                      balance: balance,
                      currencySymbol: currencySymbol,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "YOUR STATS",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sectionColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          StatRow(
                            icon: Icons.receipt_long_outlined,
                            iconColor: const Color(0xFF378ADD),
                            iconBg: const Color(0xFF1A2535),
                            label: "Total Transactions",
                            value: "$totalTransactions",
                          ),
                          const MyDivider(),
                          StatRow(
                            icon: Icons.arrow_downward_outlined,
                            iconColor: const Color(0xFFF09595),
                            iconBg: const Color(0xFF2A1A2A),
                            label: "Total Spent",
                            value:
                                "$currencySymbol ${totalSpent.toStringAsFixed(0)}",
                          ),
                          const MyDivider(),
                          StatRow(
                            icon: Icons.arrow_upward_outlined,
                            iconColor: const Color(0xFFF0997B),
                            iconBg: const Color(0xFF2A1A1A),
                            label: "Biggest Expense",
                            value:
                                "$currencySymbol ${biggestExpense.toStringAsFixed(0)}",
                          ),
                          const MyDivider(),
                          StatRow(
                            icon: Icons.star,
                            iconColor: const Color(0xFF5DCAA5),
                            iconBg: const Color(0xFF1A2E1F),
                            label: "Most Spent On",
                            value: topCategory,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "SETTINGS",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sectionColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => _showCurrencyPicker(
                              context,
                              userId,
                              currencySymbol,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A2E1F),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.attach_money,
                                      color: Color(0xFF5DCAA5),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Currency",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? const Color(0xFF9CA3AF)
                                            : const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    currencySymbol,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFFF9FAFB)
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: isDark
                                        ? const Color(0xFF4B5563)
                                        : const Color(0xFF9CA3AF),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const MyDivider(),
                          SwitchRow(
                            icon: themeProvider.isDarkMode
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                            iconColor: const Color(0xFF378ADD),
                            iconBg: const Color(0xFF1A2535),
                            label: themeProvider.isDarkMode
                                ? "Dark Mode"
                                : "Light Mode",
                            value: themeProvider.isDarkMode,
                            onChanged: themeProvider.toggleTheme,
                          ),
                          const MyDivider(),
                          ActionRow(
                            icon: Icons.alternate_email,
                            iconColor: const Color(0xFF378ADD),
                            iconBg: const Color(0xFF1A2535),
                            label: "Change Email",
                            onTap: () => _showChangeEmailDialog(context),
                          ),
                          const MyDivider(),
                          ActionRow(
                            icon: Icons.lock_reset,
                            iconColor: const Color(0xFF5DCAA5),
                            iconBg: const Color(0xFF1A2E1F),
                            label: "Change Password",
                            onTap: () => _showChangePasswordDialog(context),
                          ),
                          const MyDivider(),
                          ActionRow(
                            icon: Icons.person_remove_outlined,
                            iconColor: const Color(0xFFF09595),
                            iconBg: const Color(0xFF2A1A1A),
                            label: "Delete Account",
                            onTap: () => _confirmDeleteAccount(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "WALLET",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sectionColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          ActionRow(
                            icon: Icons.refresh,
                            iconColor: const Color(0xFF378ADD),
                            iconBg: const Color(0xFF1A2535),
                            label: "Reset Wallet",
                            onTap: () => _confirmReset(context),
                          ),
                          const MyDivider(),
                          ActionRow(
                            icon: Icons.delete_outline,
                            iconColor: const Color(0xFFF09595),
                            iconBg: const Color(0xFF2A1A1A),
                            label: "Clear All Transactions",
                            onTap: () => _confirmClearTransactions(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          ActionRow(
                            icon: Icons.logout_outlined,
                            iconColor: Colors.red,
                            iconBg: Colors.transparent,
                            label: "Log Out",
                            onTap: () => _confirmLogout(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _LegalLinks(isDark: isDark),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks({required this.isDark});

  final bool isDark;

  Future<void> _openLegalLink(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Could not open link.")));
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Link opening is unavailable right now. Restart the app and try again.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        GestureDetector(
          onTap: () => _openLegalLink(context, _termsUrl),
          child: const Text(
            "Terms & Conditions",
            style: TextStyle(
              color: Color(0xFF378ADD),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _openLegalLink(context, _termsUrl),
          child: const Icon(
            Icons.open_in_new,
            size: 14,
            color: Color(0xFF378ADD),
          ),
        ),
        Text(
          "|",
          style: TextStyle(
            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            fontSize: 12,
          ),
        ),
        GestureDetector(
          onTap: () => _openLegalLink(context, _privacyPolicyUrl),
          child: const Text(
            "Privacy Policy",
            style: TextStyle(
              color: Color(0xFF378ADD),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _openLegalLink(context, _privacyPolicyUrl),
          child: const Icon(
            Icons.open_in_new,
            size: 14,
            color: Color(0xFF378ADD),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.balance,
    required this.currencySymbol,
  });

  final String displayName;
  final double balance;
  final String currencySymbol;

  String get initials {
    if (displayName.isEmpty || displayName == "Buddy") {
      return "BU";
    }

    final nameParts = displayName.trim().split(" ");
    if (nameParts.length >= 2) {
      return "${nameParts[0][0]}${nameParts[1][0]}".toUpperCase();
    }

    return displayName.length > 1
        ? displayName.substring(0, 2).toUpperCase()
        : displayName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3150) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF378ADD),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8FB7EB),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$currencySymbol ${balance.toStringAsFixed(2)} in wallet",
                style: TextStyle(
                  fontSize: 13,
                  color: balance < 0
                      ? Colors.redAccent
                      : const Color(0xFF1D9E75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _logOut(BuildContext context) async {
  try {
    await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, Login.id, (route) => false);
    }
  } catch (e) {
    debugPrint("Logout Error");
  }
}

void _confirmLogout(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final titleColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "Log out?",
        style: TextStyle(color: titleColor, fontSize: 16),
      ),
      content: const Text(
        "You will be signed out of your Budget Buddy account on this device.",
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await _logOut(context);
          },
          child: const Text(
            "Log Out",
            style: TextStyle(color: Color(0xFFF09595)),
          ),
        ),
      ],
    ),
  );
}

void _showCurrencyPicker(
  BuildContext context,
  String userId,
  String currentCurrency,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final titleColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;
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
              Text(
                "Choose currency",
                style: TextStyle(
                  color: titleColor,
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
                  leading: Icon(
                    Icons.attach_money,
                    color: symbol == currentCurrency
                        ? const Color(0xFF378ADD)
                        : const Color(0xFF6B7280),
                  ),
                  title: Text(
                    label,
                    style: TextStyle(color: titleColor, fontSize: 14),
                  ),
                  subtitle: Text(
                    symbol,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                  trailing: symbol == currentCurrency
                      ? const Icon(
                          Icons.check,
                          color: Color(0xFF378ADD),
                          size: 18,
                        )
                      : null,
                  onTap: () async {
                    await FirebaseFirestore.instance
                        .collection("wallet")
                        .doc(userId)
                        .set({"currency": symbol}, SetOptions(merge: true));
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
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

bool _hasPasswordProvider(User user) {
  return user.providerData.any((provider) => provider.providerId == "password");
}

bool _hasGoogleProvider(User user) {
  return user.providerData.any(
    (provider) => provider.providerId == "google.com",
  );
}

Future<void> _deleteWalletData(String uid) async {
  final walletRef = FirebaseFirestore.instance.collection("wallet").doc(uid);
  final expenses = await walletRef.collection("expenses").get();
  final topups = await walletRef.collection("topups").get();
  final budgets = await walletRef.collection("budgets").get();
  final batch = FirebaseFirestore.instance.batch();

  for (final doc in expenses.docs) {
    batch.delete(doc.reference);
  }
  for (final doc in topups.docs) {
    batch.delete(doc.reference);
  }
  for (final doc in budgets.docs) {
    batch.delete(doc.reference);
  }
  batch.delete(walletRef);

  await batch.commit();
}

void _showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _confirmDeleteAccount(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final confirmController = TextEditingController();
  final passwordController = TextEditingController();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final titleColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;
  final usesPassword = _hasPasswordProvider(user);
  bool deleting = false;

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        Future<void> handleDelete() async {
          if (confirmController.text.trim().toUpperCase() != "DELETE") {
            _showInfoSnackBar(dialogContext, 'Type DELETE to confirm.');
            return;
          }

          if (usesPassword && passwordController.text.isEmpty) {
            _showInfoSnackBar(
              dialogContext,
              "Enter your current password to continue.",
            );
            return;
          }

          setDialogState(() {
            deleting = true;
          });

          try {
            final userId = user.uid;

            if (usesPassword && user.email != null) {
              final credential = auth.EmailAuthProvider.credential(
                email: user.email!,
                password: passwordController.text,
              );
              await user.reauthenticateWithCredential(credential);
            }

            await _deleteWalletData(userId);
            await user.delete();
            await FirebaseAuth.instance.signOut();
            await GoogleSignIn.instance.signOut();

            if (dialogContext.mounted) {
              Navigator.of(dialogContext, rootNavigator: true).pop();
            }
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                Login.id,
                (route) => false,
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Account deleted.")));
            }
          } on FirebaseAuthException catch (e) {
            if (dialogContext.mounted) {
              _showInfoSnackBar(
                dialogContext,
                e.code == "requires-recent-login"
                    ? "Please sign out and sign back in before deleting your account."
                    : (e.message ?? "Could not delete account."),
              );
            }
          } catch (e) {
            if (dialogContext.mounted) {
              _showInfoSnackBar(
                dialogContext,
                "Could not delete account right now: $e",
              );
            }
          } finally {
            if (dialogContext.mounted) {
              setDialogState(() {
                deleting = false;
              });
            }
          }
        }

        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Delete account?",
            style: TextStyle(color: titleColor, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "This permanently deletes your Budget Buddy account, wallet, budgets, top-ups, and transaction history.",
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (usesPassword) ...[
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: titleColor),
                    decoration: const InputDecoration(
                      labelText: "Current password",
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: confirmController,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(color: titleColor),
                  decoration: const InputDecoration(
                    labelText: 'Type DELETE to confirm',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: deleting ? null : () => Navigator.pop(dialogContext),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            TextButton(
              onPressed: deleting ? null : handleDelete,
              child: deleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      "Delete",
                      style: TextStyle(color: Color(0xFFF09595)),
                    ),
            ),
          ],
        );
      },
    ),
  );
}

void _showChangeEmailDialog(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  if (!_hasPasswordProvider(user)) {
    _showInfoSnackBar(
      context,
      "Email changes are currently available for email/password accounts only.",
    );
    return;
  }

  final currentPasswordController = TextEditingController();
  final newEmailController = TextEditingController(text: user.email ?? "");
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final titleColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "Change email",
        style: TextStyle(color: titleColor, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: newEmailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: titleColor),
            decoration: const InputDecoration(labelText: "New email"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: currentPasswordController,
            obscureText: true,
            style: TextStyle(color: titleColor),
            decoration: const InputDecoration(labelText: "Current password"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
        TextButton(
          onPressed: () async {
            final email = newEmailController.text.trim();
            final password = currentPasswordController.text;
            if (email.isEmpty || password.isEmpty || user.email == null) {
              _showInfoSnackBar(context, "Fill in the new email and password.");
              return;
            }
            try {
              final credential = auth.EmailAuthProvider.credential(
                email: user.email!,
                password: password,
              );
              await user.reauthenticateWithCredential(credential);
              await user.verifyBeforeUpdateEmail(email);
              if (context.mounted) {
                Navigator.pop(context);
                _showInfoSnackBar(
                  context,
                  "Verification email sent to $email.",
                );
              }
            } on FirebaseAuthException catch (e) {
              if (context.mounted) {
                _showInfoSnackBar(
                  context,
                  e.message ?? "Could not update email.",
                );
              }
            }
          },
          child: const Text(
            "Update",
            style: TextStyle(color: Color(0xFF378ADD)),
          ),
        ),
      ],
    ),
  );
}

void _showChangePasswordDialog(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  if (!_hasPasswordProvider(user)) {
    _showInfoSnackBar(
      context,
      "Password changes are currently available for email/password accounts only.",
    );
    return;
  }

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$',
  );
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final titleColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "Change password",
        style: TextStyle(color: titleColor, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: currentPasswordController,
            obscureText: true,
            style: TextStyle(color: titleColor),
            decoration: const InputDecoration(labelText: "Current password"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newPasswordController,
            obscureText: true,
            style: TextStyle(color: titleColor),
            decoration: const InputDecoration(labelText: "New password"),
          ),
          const SizedBox(height: 8),
          const Text(
            "Use 8+ chars with upper, lower, number, and symbol.",
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
        TextButton(
          onPressed: () async {
            final currentPassword = currentPasswordController.text;
            final newPassword = newPasswordController.text;
            if (currentPassword.isEmpty ||
                newPassword.isEmpty ||
                user.email == null) {
              _showInfoSnackBar(context, "Fill in both password fields.");
              return;
            }
            if (!passwordRegex.hasMatch(newPassword)) {
              _showInfoSnackBar(
                context,
                "Use 8+ chars with upper, lower, number, and symbol.",
              );
              return;
            }
            try {
              final credential = auth.EmailAuthProvider.credential(
                email: user.email!,
                password: currentPassword,
              );
              await user.reauthenticateWithCredential(credential);
              await user.updatePassword(newPassword);
              if (context.mounted) {
                Navigator.pop(context);
                _showInfoSnackBar(context, "Password updated.");
              }
            } on FirebaseAuthException catch (e) {
              if (context.mounted) {
                _showInfoSnackBar(
                  context,
                  e.message ?? "Could not update password.",
                );
              }
            }
          },
          child: const Text(
            "Update",
            style: TextStyle(color: Color(0xFF378ADD)),
          ),
        ),
      ],
    ),
  );
}

void _confirmReset(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Reset wallet?",
        style: TextStyle(color: Color(0xFFF9FAFB), fontSize: 16),
      ),
      content: const Text(
        "This will reset your wallet balance. You will need to set it up again.",
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
        TextButton(
          onPressed: () async {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) {
              final walletRef = FirebaseFirestore.instance
                  .collection("wallet")
                  .doc(uid);
              final expenses = await walletRef.collection("expenses").get();
              final topups = await walletRef.collection("topups").get();
              final budgets = await walletRef.collection("budgets").get();
              final batch = FirebaseFirestore.instance.batch();

              for (final doc in expenses.docs) {
                batch.delete(doc.reference);
              }
              for (final doc in topups.docs) {
                batch.delete(doc.reference);
              }
              for (final doc in budgets.docs) {
                batch.delete(doc.reference);
              }
              batch.delete(walletRef);

              await batch.commit();
            }
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text(
            "Reset",
            style: TextStyle(color: Color(0xFFF09595)),
          ),
        ),
      ],
    ),
  );
}

void _confirmClearTransactions(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Clear transactions?",
        style: TextStyle(color: Color(0xFFF9FAFB), fontSize: 16),
      ),
      content: const Text(
        "All your transaction history will be permanently deleted.",
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
        TextButton(
          onPressed: () async {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid == null) {
              return;
            }

            final batch = FirebaseFirestore.instance.batch();
            final docs = await FirebaseFirestore.instance
                .collection("wallet")
                .doc(uid)
                .collection("expenses")
                .get();

            for (final doc in docs.docs) {
              batch.delete(doc.reference);
            }

            batch.set(
              FirebaseFirestore.instance.collection("wallet").doc(uid),
              {"total_expense": 0.0},
              SetOptions(merge: true),
            );

            await batch.commit();
            await resetAllBudgetSpent(uid);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text(
            "Clear",
            style: TextStyle(color: Color(0xFFF09595)),
          ),
        ),
      ],
    ),
  );
}
