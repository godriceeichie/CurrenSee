import 'package:currensee/firebase_options.dart';
import 'package:currensee/screens/auth/auth_wrapper.dart';
import 'package:currensee/screens/auth/login_screen.dart';
import 'package:currensee/screens/auth/signup_screen.dart';
import 'package:currensee/screens/history_screen.dart';
import 'package:currensee/screens/rates_screen.dart';
import 'package:currensee/screens/settings_screen.dart';
import 'package:currensee/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

Future<void> checkAuthState() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    // User is already logged out
    print("No user is logged in.");
  } else {
    try {
      // Refresh the token to verify validity
      await user.reload();
      if (FirebaseAuth.instance.currentUser == null) {
        print("User is no longer valid. Logging out...");
        await FirebaseAuth.instance.signOut();
      } else {
        print("User is still authenticated.");
      }
    } catch (e) {
      print("Error refreshing user: $e");
      await FirebaseAuth.instance.signOut();
    }
  }
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // Ensures binding is initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Initialize Firebase
  checkAuthState();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  runApp(CurrenSee());
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Monitor exchange rates
    await FirebaseService().checkRateAlerts();
    return Future.value(true);
  });
}

class CurrenSee extends StatelessWidget {
  const CurrenSee({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "CurrenSee",
      initialRoute: '/', // Initial route
      routes: {
        '/': (context) => const AuthWrapper(),
        '/history': (context) =>  HistoryScreen(),
        '/rates': (context) => const RatesScreen(),
        '/settings': (context) => SettingsScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
      },

    );
  }
}

