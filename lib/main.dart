import 'package:budget_buddy/models/all_transactions.dart';
import 'package:budget_buddy/theme/app_theme.dart';
import 'package:budget_buddy/services/auth.dart';
import 'package:budget_buddy/screens/all_screens.dart';
import 'package:budget_buddy/screens/home/home.dart';
import 'package:budget_buddy/screens/input/input.dart';
import 'package:budget_buddy/screens/intro/intro.dart';
import 'package:budget_buddy/screens/login/login.dart';
import 'package:budget_buddy/screens/profile2/profile2.dart';
import 'package:budget_buddy/screens/splash/splash_screen.dart';
import 'package:budget_buddy/screens/wallet/wallet.dart';
import 'package:budget_buddy/theme/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/stats_chats/stats_chats.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  await GoogleSignIn.instance.initialize();
  final prefs = await SharedPreferences.getInstance();
  final hasSeen = prefs.getBool('hasSeen') ?? false;
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: BudgetBuddy(hasSeen: hasSeen),
    ),
  );
}

class BudgetBuddy extends StatelessWidget {
  const BudgetBuddy({super.key, required this.hasSeen});

  final bool hasSeen;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      home: hasSeen ? SplashScreen() : IntroScreen(),
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      routes: {
        IntroScreen.id: (context) => IntroScreen(),
        SplashScreen.id: (context) => SplashScreen(),
        AuthGate.id: (context) => AuthGate(),
        HomeScreen.id: (context) => HomeScreen(),
        AddTransaction.id: (context) => AddTransaction(),
        MyWallet.id: (context) => MyWallet(),
        WalletStream.id: (context) => WalletStream(),
        StatsPage.id: (context) => StatsPage(),
        AllTransactions.id: (context) => AllTransactions(),
        ProfilePage2.id: (context) => ProfilePage2(),
        Login.id: (context) => Login(),
        MainWrapper.id: (context) => MainWrapper(),
      },
    );
  }
}
