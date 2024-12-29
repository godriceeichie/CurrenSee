import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final String _projectId = "currensee-92827"; // Replace with your Firebase project ID
  final String _serviceAccountPath = "currensee-92827-4add0902482a.json"; // Path to your service account key

  /// Sends a notification using HTTP v1 API
  Future<void> sendRateAlertNotification(
      String userId, String baseCurrency, String targetCurrency, double rate) async {
    try {
      // Load service account credentials
      final credentials = ServiceAccountCredentials.fromJson(
        json.decode(await File(_serviceAccountPath).readAsString()),
      );

      // Authenticate and obtain access token
      final httpClient = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken == null) {
        print("No FCM token found for user: $userId");
        return;
      }

      final url = "https://fcm.googleapis.com/v1/projects/$_projectId/messages:send";

      // Prepare notification payload
      final payload = {
        "message": {
          "token": fcmToken,
          "notification": {
            "title": "Rate Alert",
            "body": "Exchange rate for $baseCurrency → $targetCurrency is now $rate!",
          },
          "data": {
            "baseCurrency": baseCurrency,
            "targetCurrency": targetCurrency,
            "rate": rate.toString(),
          },
        }
      };

      // Send notification
      final response = await httpClient.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        print("Notification sent successfully: ${response.body}");
      } else {
        print("Failed to send notification: ${response.body}");
      }

      httpClient.close();
    } catch (e) {
      print("Error sending notification: $e");
    }
  }
}
