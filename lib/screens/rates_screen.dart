import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key});

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  // API Configuration
  final String apiKey = "28ad0d031eb681515524cfe6";
  final String secondApiKey = "ec0c5964956b9b11026d3670d3de5d5c";
  String baseCurrency = "USD"; // Default base currency
  DateTime? selectedDate; // Selected date for historical data

  // State variables
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = "";
  Map<String, dynamic> _exchangeRates = {};

  // List of currencies
  final List<String> currencies = ["USD", "EUR", "GBP", "JPY", "AUD", "CAD"];

  @override
  void initState() {
    super.initState();
    _fetchExchangeRates();
  }

  Future<void> _fetchExchangeRates() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    // Format the date if a specific date is selected
    String formattedDate = "";
    if (selectedDate != null) {
      formattedDate =
      "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
    }

    // Construct the appropriate URL
    final String url = selectedDate == null
        ? "https://v6.exchangerate-api.com/v6/$apiKey/latest/$baseCurrency" // Latest rates API
        : "https://api.exchangeratesapi.io/v1/$formattedDate?access_key=$secondApiKey"; // Historical rates API

    print("API URL: $url");

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse based on API response structure
        if (selectedDate == null) {
          // Latest rates
          if (data["conversion_rates"] != null) {
            setState(() {
              _exchangeRates = data['conversion_rates'] ?? {};
              _isLoading = false;
              _isError = false;
            });
          } else {
            throw Exception("Unexpected response structure for latest rates API.");
          }
        } else {
          // Historical rates
          print(data["rates"]);
          if (data["success"] && data["rates"] != null) {
            setState(() {
              _exchangeRates = data['rates'] ?? {};
              _isLoading = false;
              _isError = false;
              baseCurrency = data['base'];

            });
          } else {
            String errorMessage = data['error']?['info'] ?? "Unknown error occurred.";
            throw Exception("API Error: $errorMessage");
          }
        }
      } else {
        throw Exception("Failed to fetch exchange rates. HTTP Status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print("Error fetching exchange rates: $e");
    }
  }



  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
      _fetchExchangeRates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exchange Rates", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Base Currency Selector
                DropdownButton<String>(
                  value: baseCurrency,
                  items: currencies.map((currency) {
                    return DropdownMenuItem<String>(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        baseCurrency = value;
                      });
                      _fetchExchangeRates();
                    }
                  },
                ),
                // Date Picker Button
                TextButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today, color: Colors.blue),
                  label: Text(
                    selectedDate == null
                        ? "Select Date"
                        : "${selectedDate!.toLocal()}".split(' ')[0],
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blue,))
                : _isError
                ? Center(
              child: Text(
                "Error: $_errorMessage",
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
                : _exchangeRates.isEmpty
                ? const Center(
              child: Text(
                "No exchange rates available.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _exchangeRates.keys.length,
              itemBuilder: (context, index) {
                final currency = _exchangeRates.keys.elementAt(index);
                final rate = _exchangeRates[currency];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        currency[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      currency,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Exchange Rate: $rate"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
