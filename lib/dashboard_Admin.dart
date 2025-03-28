import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'agency_outstanding_c.dart';
import 'agency_outstanding_s.dart';
import 'dart:developer'; // for logging
import 'main.dart';
import 'shared_pref_helper.dart'; // Import the shared preferences helper
import 'globals.dart' as globals;
import 'z_settings.dart';

class HomeScreenAdmin extends StatefulWidget {
  final String username; // Declare the username
  const HomeScreenAdmin(
      {super.key, required this.username}); // Constructor for passing username

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreenAdmin> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    Text('Dashboard Content'),
    Text('Tap "Outstanding" to go to a new page'),
    Text('Reports Content'),
  ];

  String dropdownValue = ''; // Initial value for dropdown
  Map<String, String> clientMap = {}; // Map to store client names and codes

  @override
  void initState() {
    super.initState();
    fetchDropdownData();

    // generatePdfShare();
  }

  // Function to fetch data from API
  Future<void> fetchDropdownData() async {
    final String apiUrl = '${globals.uriname}dropdown.php?username=${widget.username}';
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        log('API Response: ${response.body}'); // Log response for debugging

        // Parse the JSON response as a List of Maps
        final List<dynamic> jsonData = jsonDecode(response.body);

        if (jsonData.isNotEmpty && jsonData[0] is Map) {
          setState(() {
            clientMap = Map.fromEntries(
              jsonData.map((item) {
                final map = item as Map<String, dynamic>;
                return MapEntry(map['d_clientname'] as String,
                    map['d_clientcode'] as String);
              }),
            );
            dropdownValue = clientMap.keys.isNotEmpty
                ? clientMap.keys.first
                : ''; // Set initial value
          });
        } else {
          log('Unexpected data format');
          throw Exception('Unexpected data format');
        }
      } else {
        log('Failed to load data: ${response.statusCode}');
        throw Exception('Failed to load dropdown data');
      }
    } catch (e) {
      log('Error fetching data: $e');
    }
  }

  void _onItemTapped(int index) {
    // Check if dropdownValue is valid before proceeding
    if (dropdownValue.isNotEmpty && clientMap.containsKey(dropdownValue)) {
      if (index == 1) {
        log('Navigating to OutstandingScreen with client: $dropdownValue and code: ${clientMap[dropdownValue]}');

        // Navigate to the new "Outstanding" page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AgencyOutstandingScreen(
              username: widget.username,
              clientcode:
                  clientMap[dropdownValue]!, // Fetch client code from map
              clientname: dropdownValue.isNotEmpty ? dropdownValue : 'Unknown',
              clientMap: dropdownValue,
            ),
          ),
        );
      } else if (index == 2) {
        log('Navigating to OutstandingSupplier with client: $dropdownValue and code: ${clientMap[dropdownValue]}');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AgencyOutstandingSupplier(
              username: widget.username,
              clientcode:
                  clientMap[dropdownValue]!, // Fetch client code from map
              clientname: dropdownValue.isNotEmpty ? dropdownValue : 'Unknown',
              clientMap: dropdownValue,
            ),
          ),
        );
      }
    } else {
      // Show an error message if no client is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a valid client before proceeding.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: globals.themeColor,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: const Text('My App'),
        actions: <Widget>[
          clientMap.isEmpty
              ? const CircularProgressIndicator()
              : DropdownButton<String>(
                  value: dropdownValue,
                  icon: const Icon(Icons.arrow_downward, color: Colors.white),
                  elevation: 16,
                  style: const TextStyle(color: Colors.black),
                  underline: Container(
                    height: 2,
                    color: Colors.blueAccent,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        dropdownValue = newValue; // Update the selected value
                        log('Selected Client: $dropdownValue');
                      });

                      // Check if client code is being retrieved correctly
                      String? clientCode = clientMap[
                          dropdownValue]; // Fetch client code using dropdown value

                      if (clientCode != null) {
                        log('Client Code for $dropdownValue: $clientCode');

                        // Call your PDF generation function after selecting a new client
                        // generateAndSharePDF(widget.clientcode, widget.clientname); // Pass the client code and name
                      } else {
                        log('Client not found in map for: $dropdownValue');
                        // Show an error message if the client code is not found
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Error: Client not found.')),
                        );
                      }
                    }
                  },
                  items: clientMap.keys
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
          const SizedBox(width: 20),
        ],
      ),
      drawer: Drawer(
  child: ListView(
    padding: EdgeInsets.zero,
    children: <Widget>[
      DrawerHeader(
        decoration: BoxDecoration(
          color: globals.themeColor,  // Using the global color
        ),
        child: Text(
          'Menu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.home),
        title: const Text('Home'),
        onTap: () {
          Navigator.pop(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.settings),
        title: const Text('Settings'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsPage()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Logout'),
        onTap: () async {
          await SharedPrefHelper.clearLoginState();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
          );
        },
      ),
    ],
  ),
),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _widgetOptions.elementAt(_selectedIndex),
            Text(
              'Selected: $dropdownValue',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard_A',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.outbox),
            label: 'Customers_A',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Suppliers_A',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: globals.themeColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
