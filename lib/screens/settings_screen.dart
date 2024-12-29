import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:currensee/services/firebase_service.dart';
import 'package:http/http.dart' as http;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  String _defaultCurrency = "USD"; // Default base currency
  List<String> currencies = []; // List of currency codes
  User? _user;
  String _userName = "Not Set";
  String _userEmail = "Not Set";
  bool _isLoading = true;

  // Rate alert fields
  String _baseCurrency = "USD"; // Default base currency
  String _targetCurrency = "";
  final TextEditingController _rateThresholdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _getCurrencies() async {
    try {
      var response = await http.get(Uri.parse("https://api.exchangerate-api.com/v4/latest/USD"));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        setState(() {
          currencies = (data['rates'] as Map<String, dynamic>).keys.toList();
        });

        print("Fetched Currencies: $currencies");
      } else {
        throw Exception("Failed to fetch data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in fetching currencies: $e");
      setState(() {
        currencies = []; // Ensure it's not null
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _user = FirebaseAuth.instance.currentUser;

      if (_user != null) {
        // Fetch user data and currencies
        final userData = await _firebaseService.fetchUserData(_user!.uid);
        await _getCurrencies(); // Fetch available currencies

        setState(() {
          _userName = userData['name'] ?? "Not Set";
          _userEmail = userData['email'] ?? "Not Set";
          _defaultCurrency = userData['defaultCurrency'] ?? "USD";
          _baseCurrency = _defaultCurrency;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading data: $e")),
      );
    }
  }

  Future<void> _setRateAlert() async {
    if (_baseCurrency.isEmpty || _targetCurrency.isEmpty || _rateThresholdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields to set the alert.")),
      );
      return;
    }

    try {
      double threshold = double.parse(_rateThresholdController.text);

      await _firebaseService.setRateAlert(_user!.uid, {
        'baseCurrency': _baseCurrency,
        'targetCurrency': _targetCurrency,
        'rateThreshold': threshold,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _rateThresholdController.clear();
      setState(() {
        _targetCurrency = "";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rate alert set successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error setting rate alert: $e")),
      );
    }
  }

  Future<void> _setDefaultCurrency(String currency) async {
    if (_user != null) {
      try {
        await _firebaseService.setUserPreferences(_user!.uid, {'defaultCurrency': currency});
        setState(() {
          _defaultCurrency = currency;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Default currency updated to $currency")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating default currency: $e")),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.blue,
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              icon: Icons.person,
              title: "User Info",
              content: _buildUserInfo(),
            ),
            const SizedBox(height: 20),
            _buildCard(
              icon: Icons.currency_exchange,
              title: "Default Currency",
              content: _buildCurrencyDropdown(),
            ),
            const SizedBox(height: 20),
            _buildCard(
              icon: Icons.notifications,
              title: "Set Rate Alerts",
              content: _buildRateAlertForm(),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _logout(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              icon: const Icon(Icons.logout, color: Colors.white,),
              label: const Text("Logout", style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Name: $_userName", style: TextStyle(fontWeight: FontWeight.w500),),
        Text("Email: $_userEmail", style: TextStyle(fontWeight: FontWeight.w500))
      ],
    );
  }

  Widget _buildCurrencyDropdown() {
    return DropdownButton<String>(
      value: _defaultCurrency.isNotEmpty ? _defaultCurrency : null,
      hint: const Text("Select a default currency"),
      items: currencies.map((currency) {
        return DropdownMenuItem<String>(
          value: currency,
          child: Text(currency),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          _setDefaultCurrency(value);
        }
      },
    );
  }

  Widget _buildRateAlertForm() {
    return Column(
      children: [
        DropdownButton<String>(
          value: _baseCurrency,
          hint: const Text("Base Currency"),
          items: currencies.map((currency) {
            return DropdownMenuItem<String>(
              value: currency,
              child: Text(currency),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _baseCurrency = value;
              });
            }
          },
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: _targetCurrency.isNotEmpty ? _targetCurrency : null,
          hint: const Text("Target Currency"),
          items: currencies.map((currency) {
            return DropdownMenuItem<String>(
              value: currency,
              child: Text(currency),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _targetCurrency = value;
              });
            }
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _rateThresholdController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Rate Threshold",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _setRateAlert,
          child: const Text("Set Alert"),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firebaseService.logoutUser();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
