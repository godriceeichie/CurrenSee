// firebase_service.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:currensee/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Singleton Pattern
  static final FirebaseService _instance = FirebaseService._privateConstructor();
  FirebaseService._privateConstructor();
  factory FirebaseService() => _instance;

  // Getter for the current user
  User? get currentUser => _auth.currentUser;

  // User Registration and Authentication
  Future<User?> registerUser(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Create Firestore user document
      if (userCredential.user != null) {
        await createUserInFirestore(userCredential.user!, name);
         return userCredential.user;
      } else {
        throw Exception("User registration failed. No user found.");
      }
    } catch (e) {
      throw Exception("Registration failed: $e");
    }
  }

  Future<void> createUserInFirestore(User user, String name) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'preferences': {
          'defaultCurrency': "AZN"
        }
      });
    } catch (e) {
      throw Exception("Error creating user in Firestore: $e");
    }
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch Firestore user data
      Map<String, dynamic> userData = await fetchUserData(userCredential.user!.uid);

      print("Welcome ${userData['name']}, your default currency is ${userData['defaultCurrency']}.");
      return userCredential.user;
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>> fetchUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        throw Exception("User data not found.");
      }
    } catch (e) {
      throw Exception("Error fetching user data: $e");
    }
  }


  Future<void> storeConversionHistory(String userId, Map<String, dynamic> transaction) async {
    await _firestore.collection('users/$userId/conversions').add(transaction);
  }

  Future<void> saveConversion(String fromCurrency, String toCurrency, double amount, double rate, double total) async {
    final user = _auth.currentUser;
    if (user != null) {
      final conversion = {
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        'amount': amount,
        'rate': rate,
        'total': total,
        'timestamp': FieldValue.serverTimestamp(),
      };
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversions')
          .add(conversion);
    } else {
      throw Exception("User not logged in. Cannot save conversion.");
    }
  }

  Future<List<Map<String, dynamic>>> fetchConversionHistory(String userId) async {
    QuerySnapshot history = await _firestore.collection('users/$userId/conversions').orderBy('timestamp', descending: true).get();
    return history.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Currency Conversion and Data
  Future<Map<String, dynamic>> fetchExchangeRate(String base, String target) async {
    // Simulated fetching from an API or database.
    DocumentSnapshot rateDoc = await _firestore.collection('exchangeRates').doc('$base-$target').get();
    if (rateDoc.exists) {
      return rateDoc.data() as Map<String, dynamic>;
    } else {
      throw Exception("Exchange rate not found.");
    }
  }

  // Future<void> storeConversionHistory(String userId, Map<String, dynamic> transaction) async {
  //   await _firestore.collection('users/$userId/conversions').add(transaction);
  // }
  //
  // Future<List<Map<String, dynamic>>> fetchConversionHistory(String userId) async {
  //   QuerySnapshot history = await _firestore.collection('users/$userId/conversions').orderBy('date', descending: true).get();
  //   return history.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  // }

  // Currency List
  Future<List<Map<String, dynamic>>> fetchCurrencies() async {
    QuerySnapshot currencySnapshot = await _firestore.collection('currencies').get();
    return currencySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Rate Alerts
  Future<void> setRateAlert(String userId, Map<String, dynamic> alert) async {
    await _firestore.collection('users/$userId/rateAlerts').add(alert);
  }

  Future<List<Map<String, dynamic>>> fetchRateAlerts(String userId) async {
    QuerySnapshot alerts = await _firestore.collection('users/$userId/rateAlerts').get();
    return alerts.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> checkRateAlerts() async {
    final firestore = FirebaseFirestore.instance;
    final notificationService = NotificationService(); // Ensure this is imported

    try {
      // Fetch all users
      final usersSnapshot = await firestore.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;

        // Fetch the user's rate alerts
        final alertsSnapshot = await firestore
            .collection('users')
            .doc(userId)
            .collection('rateAlerts')
            .get();

        for (var alertDoc in alertsSnapshot.docs) {
          final alert = alertDoc.data();
          final baseCurrency = alert['baseCurrency'];
          final targetCurrency = alert['targetCurrency'];
          final threshold = alert['rateThreshold'];

          // Fetch the current exchange rate
          final response = await http.get(
            Uri.parse("https://api.exchangerate-api.com/v4/latest/$baseCurrency"),
          );

          if (response.statusCode == 200) {
            final rates = json.decode(response.body)['rates'];
            final currentRate = rates[targetCurrency];

            // Check if the current rate meets or exceeds the threshold
            if (currentRate != null && currentRate >= threshold) {
              // Notify the user
              await notificationService.sendRateAlertNotification(
                userId,
                baseCurrency,
                targetCurrency,
                currentRate,
              );
            }
          } else {
            print("Failed to fetch rates for $baseCurrency. Status: ${response.statusCode}");
          }
        }
      }
    } catch (e) {
      print("Error checking rate alerts: $e");
    }
  }


  // User Preferences
  Future<void> setUserPreferences(String userId, Map<String, dynamic> preferences) async {
    await _firestore.collection('users').doc(userId).update({'preferences': preferences});
  }

  Future<Map<String, dynamic>> fetchUserPreferences(String userId) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data() != null) {
      return (userDoc.data() as Map<String, dynamic>)['preferences'] ?? {};
    } else {
      return {};
    }
  }

  // News and Market Trends
  Future<List<Map<String, dynamic>>> fetchMarketNews() async {
    QuerySnapshot newsSnapshot = await _firestore.collection('marketNews').orderBy('date', descending: true).get();
    return newsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Notifications
  Future<void> subscribeToNotifications() async {
    await _messaging.requestPermission();
    String? token = await _messaging.getToken();
    if (token != null) {
      print("Firebase Messaging Token: $token");
      // Save the token to Firestore for notifications.
    }
  }

  Future<void> sendRateAlertNotification(String userId, String message) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      String? token = (userDoc.data() as Map<String, dynamic>)['fcmToken'];
      if (token != null) {
        // Send notification using Firebase Cloud Messaging.
      }
    }
  }

  // User Feedback
  Future<void> submitUserFeedback(String userId, String feedback) async {
    await _firestore.collection('feedback').add({
      'userId': userId,
      'feedback': feedback,
      'date': FieldValue.serverTimestamp(),
    });
  }

  // FAQs and Support
  Future<List<Map<String, dynamic>>> fetchFAQs() async {
    QuerySnapshot faqsSnapshot = await _firestore.collection('faqs').get();
    return faqsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }
}
