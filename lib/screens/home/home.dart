import 'dart:io';

import 'package:budget_buddy/models/all_transactions.dart';
import 'package:budget_buddy/utils/currency_utils.dart';
import 'package:budget_buddy/screens/input/input.dart';
import 'package:budget_buddy/screens/stats_chats/stats_chats.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:budget_buddy/utils/stats.dart';
import 'package:budget_buddy/utils/streams.dart';
import 'package:image_picker/image_picker.dart';
import 'package:budget_buddy/screens/wallet/wallet.dart';
import 'package:budget_buddy/home_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_buddy/services/budget_service.dart';
import 'package:budget_buddy/utils/budget_utils.dart';
import 'package:budget_buddy/widgets/budget_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const String id = "home_screen";

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  File? _profileImage;

  final ImagePicker _picker = ImagePicker();

  final bool _isUploadingImage = false;
  final cloudinary = CloudinaryPublic(
    "dz2yhqe4w",
    'budget_buddy',
    cache: false,
  );
  Future<void> _uploadImage(File imageFile) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      String downloadUrl = response.secureUrl;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePhotoURL((downloadUrl));
        await user.reload();
        setState(() {});
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Image Upload error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        setState(() {
          _profileImage = imageFile;
        });
        await _uploadImage(imageFile);
      }
    } catch (e) {
      debugPrint("Failed to pick image");
    }
  }

  void _showImageActionSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? const Color(0xFF1A2035)
          : Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                title: Text(
                  'Use Camera',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                title: Text(
                  'Select from Library',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.redAccent),
                title: const Text(
                  'Leave it like that',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark
        ? const Color(0XFF6B7280)
        : const Color(0xFF6B7280);
    final surfaceColor = theme.cardColor;
    final borderColor = isDark
        ? const Color(0xFF2A3150)
        : const Color(0xFFE5E7EB);
    final userName = FirebaseAuth.instance.currentUser;
    final userIn = FirebaseAuth.instance.currentUser;
    if (userIn == null) return const SizedBox();

    final String displayName =
        userName?.displayName ?? userName?.email?.split('@')[0] ?? "Buddy";
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 96),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
                          child: Text(
                            _getGreeting(),
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: titleColor, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: _showImageActionSheet,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0XFF2A3150)
                              : const Color(0xFFE5E7EB),
                          shape: BoxShape.circle,
                          image: _profileImage != null
                              ? DecorationImage(
                                  image: FileImage(_profileImage!),
                                  fit: BoxFit.cover,
                                )
                              : userName?.photoURL != null
                              ? DecorationImage(
                                  image: NetworkImage(userName!.photoURL!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _isUploadingImage
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : (_profileImage == null &&
                                  userName?.photoURL == null)
                            ? const Icon(
                                Icons.person,
                                size: 28 * 0.5,
                                color: Color(0XFF6B7280),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('wallet')
                    .doc(userIn.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(color: Color(0XFF378ADD));
                  }
                  final data = snapshot.data?.data() as Map<String, dynamic>?;
                  final expenses = (data?['total_expense'] ?? 0.0).toDouble();
                  final balance = (data?['balance'] ?? 0.0).toDouble();
                  final currencySymbol =
                      (data?['currency'] as String?) ?? defaultCurrencySymbol;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    padding: EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Balance",
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.5,
                            color: titleColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          formatCurrency(currencySymbol, balance),
                          style: TextStyle(
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                            fontSize: 30,
                            color: balance < 0
                                ? Colors.redAccent
                                : Colors.greenAccent,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Stats(
                                label: "Wallet",
                                amount: formatCurrency(currencySymbol, balance),
                                dotColor: Color(0xFF1D9E75),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Stats(
                                label: "Expenses",
                                amount: formatCurrency(
                                  currencySymbol,
                                  expenses,
                                ),
                                dotColor: Color(0xFFD85A30),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Budget Health",
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, StatsPage.id);
                      },
                      child: const Text(
                        "Manage",
                        style: TextStyle(
                          color: Color(0xFF578ADD),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: HomeBudgetPreview(),
              ),
              SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Analytics",
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, StatsPage.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: const Text(
                          "See All",
                          style: TextStyle(
                            color: Color(0xFF578ADD),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.0),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, StatsPage.id);
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: const HomeChartPreview(),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          top: 16.0,
                          bottom: 16.0,
                        ),
                        child: Text(
                          "Recent Transactions",
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, AllTransactions.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "See All",
                            style: TextStyle(
                              color: Color(0xFF578ADD),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.all(16.0),
                    child: TransactionsStreams(limit: 5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => TopUpSheet(),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  "Top Up",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AddTransaction.id),
                icon: const Icon(Icons.arrow_upward, size: 18),
                label: const Text(
                  "Expense",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

class HomeBudgetPreview extends StatelessWidget {
  const HomeBudgetPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF9FAFB) : Colors.black87;
    final mutedColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final borderColor = isDark
        ? const Color(0xFF2A3150)
        : const Color(0xFFE5E7EB);

    return WalletCurrencyBuilder(
      builder: (context, currencySymbol) =>
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: monthlyBudgetQuery(user.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF378ADD)),
                  ),
                );
              }

              final budgetDocs = snapshot.data!.docs;
              if (budgetDocs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthLabelForDate(DateTime.now()),
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Set category budgets to see whether you're on track before you overspend.",
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final budgets = budgetDocs.map((doc) => doc.data()).toList()
                ..sort((a, b) {
                  final aRatio = budgetUsageRatio(
                    (a['spent'] as num?)?.toDouble() ?? 0,
                    (a['limit'] as num?)?.toDouble() ?? 0,
                  );
                  final bRatio = budgetUsageRatio(
                    (b['spent'] as num?)?.toDouble() ?? 0,
                    (b['limit'] as num?)?.toDouble() ?? 0,
                  );
                  return bRatio.compareTo(aRatio);
                });

              final totalBudgets = budgets.length;
              final healthyBudgets = budgets.where((budget) {
                final spent = (budget['spent'] as num?)?.toDouble() ?? 0;
                final limit = (budget['limit'] as num?)?.toDouble() ?? 0;
                return budgetHealth(spent, limit) == BudgetHealth.onTrack;
              }).length;

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            monthLabelForDate(DateTime.now()),
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '$healthyBudgets / $totalBudgets on track',
                          style: const TextStyle(
                            color: Color(0xFF578ADD),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...budgets.take(3).map((budget) {
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
                      ),
                    );
                  }),
                ],
              );
            },
          ),
    );
  }
}
