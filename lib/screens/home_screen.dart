import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:currensee/services/firebase_service.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService(); // FirebaseService instance
  String fromCurrency = "USD";
  String toCurrency = "EUR";
  double rate = 0.0;
  double total = 0.0;
  TextEditingController amountController = TextEditingController();
  List<String> currencies = [];

  @override
  void initState() {
    super.initState();
    _getCurrencies();
  }

  Future<void> _getCurrencies() async {
    try {
      var response = await http.get(Uri.parse("https://api.exchangerate-api.com/v4/latest/USD"));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        setState(() {
          currencies = (data['rates'] as Map<String, dynamic>?)?.keys.toList() ?? [];
          if (currencies.isNotEmpty) {
            rate = data['rates'][toCurrency] ?? 0.0;
          }
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

  Future<void> _convertAndSave() async {
    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an amount to convert")),
      );
      return;
    }

    double amount = double.tryParse(amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    try {
      // Fetch the latest rate
      await _getRate();

      // Calculate total
      total = amount * rate;

      // Save the conversion to Firestore
      await _firebaseService.saveConversion(fromCurrency, toCurrency, amount, rate, total);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Conversion saved successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _getRate() async {
    var response = await http.get(Uri.parse("https://api.exchangerate-api.com/v4/latest/$fromCurrency"));
    var data = json.decode(response.body);
    setState(() {
      rate = data['rates'][toCurrency] ?? 0.0;
    });
  }

  void _swapCurrencies() {
    setState(() {
      String temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;
      _getRate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 5.0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text("CurrenSee"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: currencies.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.blue,))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Image.asset(
                    'images/exchange.png',
                    width: MediaQuery.of(context).size.width / 4,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: "Amount",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCurrencyDropdown(fromCurrency, (newValue) {
                        setState(() {
                          fromCurrency = newValue!;
                          _getRate();
                        });
                      }),
                      IconButton(
                        onPressed: _swapCurrencies,
                        icon: const Icon(Icons.swap_horiz),
                        iconSize: 40,
                        color: Colors.grey,
                      ),
                      _buildCurrencyDropdown(toCurrency, (newValue) {
                        setState(() {
                          toCurrency = newValue!;
                          _getRate();
                        });
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text("Rate: $rate", style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 20),
                Text(
                  total.toStringAsFixed(3),
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 40),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _convertAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Convert and Save",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown(String selectedCurrency, ValueChanged<String?> onChanged) {
    return SizedBox(
      width: 100,
      child: DropdownButton<String>(
        value: selectedCurrency,
        isExpanded: true,
        items: currencies.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
