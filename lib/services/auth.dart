import 'package:budget_buddy/screens/all_screens.dart';
import 'package:budget_buddy/screens/login/login.dart';
import 'package:budget_buddy/screens/intro/intro.dart';
import 'package:budget_buddy/screens/wallet/wallet.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  static String id = "auth_gate";

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  String _destination = '';

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final walletDoc = await FirebaseFirestore.instance
            .collection('wallet')
            .doc(user.uid)
            .get();

        if (!walletDoc.exists) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasSeen', false);

          setState(() {
            _destination = 'wallet';
            _isLoading = false;
          });
        } else {
          final prefs = await SharedPreferences.getInstance();
          final hasSeenIntro = prefs.getBool('hasSeen') ?? false;

          setState(() {
            _destination = hasSeenIntro ? 'home' : 'intro';
            _isLoading = false;
          });
        }
      } catch (e) {
        final prefs = await SharedPreferences.getInstance();
        final hasSeenIntro = prefs.getBool('hasSeen') ?? false;

        setState(() {
          _destination = hasSeenIntro ? 'home' : 'intro';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _destination = 'login';
        _isLoading = false;
      });
    }
  }

  void _navigate() {
    if (!mounted) return;

    switch (_destination) {
      case 'wallet':
        Navigator.pushReplacementNamed(context, MyWallet.id);
        break;
      case 'intro':
        Navigator.pushReplacementNamed(context, IntroScreen.id);
        break;
      case 'home':
        Navigator.pushReplacementNamed(context, MainWrapper.id);
        break;
      default:
        Navigator.pushReplacementNamed(context, Login.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigate();
    });

    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
