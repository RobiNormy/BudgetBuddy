import 'package:budget_buddy/screens/all_screens.dart';
import 'package:budget_buddy/screens/login/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  static String id = "auth_gate";
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MainWrapper();
        }
        return Login();
      },
    );
  }
}
