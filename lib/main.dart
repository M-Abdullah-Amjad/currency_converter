import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:currency_converter/currencies.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package

void main() {
  runApp(const MyApp());}


class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Currency Converter',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
          brightness: Brightness.dark,
        ).copyWith(secondary: Colors.teal),
        scaffoldBackgroundColor: const Color(0xFF121212),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            borderSide: BorderSide(color: Colors.teal, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            borderSide: BorderSide(color: Colors.teal, width: 2.0),
          ),
        ),
      ),
      home: const MyHomePage(title: 'Currency Converter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCurrencyFrom;
  String? _selectedCurrencyTo;
  TextEditingController _amountController = TextEditingController();
  String? _conversionResult;
  bool _isLoading = false;

  Future<void> _convertCurrency() async {
    // Check network connectivity
    bool isConnected = await isNetworkConnected();

    if (!isConnected) {
      // Show toast message and return if not connected
      Fluttertoast.showToast(
        msg: "No internet connection. Please turn on your network.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return; // Early exit if not connected
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final response = await http.get(
          Uri.parse('https://open.er-api.com/v6/latest/$_selectedCurrencyFrom'),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          double rate = data['rates'][_selectedCurrencyTo];
          double amount = double.parse(_amountController.text);
          double convertedAmount = amount * rate;

          setState(() {
            _conversionResult =
            "$amount $_selectedCurrencyFrom = ${convertedAmount.toStringAsFixed(2)} $_selectedCurrencyTo";
          });
          FocusScope.of(context).unfocus();
        } else {
          setState(() {
            _conversionResult = "Error fetching conversion rate!";
          });
        }
      } catch (e) {
        setState(() {
          _conversionResult = "Error: $e";
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  // Function to launch the URL
  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw 'Could not launch $url';
    }
  }

  Future<void> checkNetworkStatus() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    bool online = connectivityResult != ConnectivityResult.none;
    setState(() {
      isOnline = online;
    });
  }

  Future<bool> isNetworkConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    } else {
      // Check if we can actually reach the internet (via simple ping)
      try {
        final result = await InternetAddress.lookup('example.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true; // Internet is available
        }
      } catch (e) {
        // No actual internet despite being connected to a network
        Fluttertoast.showToast(
          msg: "No internet connection. Please check your network.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return false;
      }
    }
    return false;
  }

  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    _selectedCurrencyFrom = null; // Initially show hint text
    _selectedCurrencyTo = null; // Initially show hint text
    checkNetworkStatus(); // Check status on startup

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Handle the list of connectivity results
      bool online = results.isNotEmpty && results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi);
      setState(() {
        isOnline = online;
      });
      if (!online) {
        Fluttertoast.showToast(
          msg: "You are offline. Please check your internet connection.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(widget.title, style: GoogleFonts.poppins()),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.only(left: 16,top: 9,right:16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.teal],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [Align(
                        alignment: Alignment.topLeft,
                        child:Padding(
                          padding: EdgeInsets.only(left: 10.0),
                          child: Row(
                            // mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isOnline ? Icons.wifi : Icons.wifi_off,
                                color: isOnline ? Colors.green : Colors.red,
                              ),
                              SizedBox(width: 8), // Add some space between the icon and text
                              Text(
                                isOnline ? "Online" : "Offline",
                                style: GoogleFonts.roboto(
                                  textStyle: TextStyle(
                                    color: isOnline ? Colors.green : Colors.red,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )

                    ),
                      SizedBox(height: 15,),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Amount",
                          hintText: "Enter amount",
                          labelStyle:const TextStyle(color: Colors.white) ,
                          hintStyle: const TextStyle(color: Colors.white), // Set hint text color to grey
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12.0)),
                            borderSide: BorderSide(color: Colors.grey),

                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12.0)),
                            borderSide: BorderSide(color: Colors.teal, width: 2.0), // Border color for focused state
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter an amount";
                          }
                          return null;
                        },
                        style: GoogleFonts.poppins(),
                      ),
                      const SizedBox(height: 16.0),

                      // From Currency Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedCurrencyFrom,
                        items: CurrencyData.getCurrencyList().map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${entry.key} - ${entry.value}',  // e.g. "USD - United States Dollar"
                                    style: GoogleFonts.poppins(fontSize: 18.0),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: "From",
                          hintText: "Select currency",
                          labelStyle: TextStyle(color: Colors.white), // Ensure label text color remains white
                          hintStyle: TextStyle(color: Colors.grey),  // Set hint text color to grey
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12.0)),
                            borderSide: BorderSide(color: Colors.grey),  // Border color for focused state
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12.0)),
                            borderSide: BorderSide(color: Colors.teal, width: 2.0),  // Border color for enabled state
                          ),
                        ),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCurrencyFrom = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16.0),

                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedCurrencyTo,
                        items: CurrencyData.getCurrencyList().map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${entry.key} - ${entry.value}',  // e.g. "EUR - Euro"
                                    style: GoogleFonts.poppins(fontSize: 18.0),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: "To",
                          hintText: "Select currency",
                          labelStyle: TextStyle(color: Colors.white), // Ensure label text color remains white
                          hintStyle: TextStyle(color: Colors.grey),  // Set hint text color to grey
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12.0)),
                            borderSide: BorderSide(color: Colors.grey),  // Border color for focused state
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12.0)),
                            borderSide: BorderSide(color: Colors.teal, width: 2.0),  // Border color for enabled state
                          ),
                        ),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCurrencyTo = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Convert Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _convertCurrency,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50.0,
                            vertical: 15.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          textStyle: GoogleFonts.poppins(fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : const Text("Convert"),
                      ),

                      const SizedBox(height: 24.0),

                      // Conversion Result
                      if (_conversionResult != null)
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            _conversionResult!,
                            style: GoogleFonts.poppins(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 24.0),
                    ],
                  ),
                ),
              ),
            ),

            // Link to website
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Powered by:",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: ()=> _launchURL('https://codecamp.website'),
                    child: Text(
                      "codecamp.website",
                      style: GoogleFonts.poppins(
                        color: Colors.blue.shade900,
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3.0), // Optional spacing from the bottom
          ],
        ),
      ),
      floatingActionButton: CircleAvatar(
        radius: 18,
        child: FloatingActionButton(
          onPressed: () {
            exit(0); // Close the app
          },
          child: const Icon(Icons.exit_to_app,size: 18,),
          backgroundColor: Colors.red,
        ),
      ),
    );
  }
}
