import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:currensee/services/firebase_service.dart';
import 'package:intl/intl.dart'; // For date formatting

class HistoryScreen extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  Future<List<Map<String, dynamic>>> _fetchConversions() async {
    final user = _firebaseService.currentUser;
    if (user == null) throw Exception("User not logged in");
    print("Yeah");
    print(user.uid);
    return await _firebaseService.fetchConversionHistory(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Conversion History", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white), // Makes the back arrow white
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchConversions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue,));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No conversions found",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final conversions = snapshot.data!;
          return ListView.builder(
            itemCount: conversions.length,
            itemBuilder: (context, index) {
              final conversion = conversions[index];
              final timestamp = (conversion['timestamp'] as Timestamp?)?.toDate();
              final formattedDate = timestamp != null
                  ? DateFormat.yMMMMd().add_jm().format(timestamp)
                  : "Unknown";

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      conversion['fromCurrency'][0], // Initial of from currency
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    "${conversion['amount']} ${conversion['fromCurrency']} → ${conversion['toCurrency']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Rate: ${conversion['rate']} | Total: ${conversion['total']}\n"
                        "Date: $formattedDate",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
