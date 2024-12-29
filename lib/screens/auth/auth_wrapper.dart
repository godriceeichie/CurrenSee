import 'package:currensee/screens/auth/login_screen.dart';
import 'package:currensee/screens/root.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blue,));
        }
        if (snapshot.hasData) {
          return const Root(); // Show the main app if authenticated
        }
        return const LoginScreen(); // Show login if not authenticated
      },
    );
  }
}
