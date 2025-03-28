import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart';

class SupplierDetail extends StatefulWidget {
  final String username;
  final String clientcode;
  final String clientname;
  final String clientMap;
  final String itemid;
  final String itemname;

  const SupplierDetail({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
    required this.itemid,
    required this.itemname,
  });

  @override
  State<SupplierDetail> createState() => _SupplierDetailState();
}

class _SupplierDetailState extends State<SupplierDetail> {
  List userData = [];
  final List<TextEditingController> _controllers = [];
  final _formKey = GlobalKey<FormState>(); // Key for form validation

  @override
  void initState() {
    super.initState();
    getRecord();
  }

  Future<void> getRecord() async {
  String uri =
      "${uriname}account_read.php?AM_AccId=${widget.itemid}&clientcode=$clientcode&cmp=$cmpcode";
  try {
    var response = await http.get(Uri.parse(uri));
    if (response.statusCode == 200) {
      var jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body); // Decode the JSON response
      } catch (e) {
        print('JSON decoding error: $e');
        return; // Early return on error
      }

      // Check if the response is a list
      if (jsonResponse is List) {
        setState(() {
          userData = jsonResponse; // Update userData state
          // Initialize controllers based on userData length
          _controllers.clear(); // Clear previous controllers
          for (var item in userData) {
            _controllers.add(TextEditingController(text: item["AM_AccId"] ?? "N/A"));
            _controllers.add(TextEditingController(text: item["AM_AccCode"] ?? "N/A"));
            _controllers.add(TextEditingController(text: item["AM_AccName"] ?? "N/A"));
            _controllers.add(TextEditingController(text: item["AM_AccAlias"] ?? "N/A"));
             _controllers.add(TextEditingController(text: item["AD_Address1"] ?? "N/A"));
             _controllers.add(TextEditingController(text: item["AD_CGSTNo"] ?? "N/A"));
             _controllers.add(TextEditingController(text: item["AD_GState"] ?? "N/A"));
             _controllers.add(TextEditingController(text: item["AgentName"] ?? "N/A"));
             _controllers.add(TextEditingController(text: item["AD_Transport"] ?? "N/A"));
             _controllers.add(TextEditingController(text: item["AD_CtPerson1"] ?? "N/A"));
             _controllers.add(TextEditingController(text: item["AD_CtPerson2"] ?? "N/A"));
             _controllers.add(TextEditingController(text: item["AD_CtMob1"] ?? "N/A"));
             _controllers.add(TextEditingController(text: item["AD_CtMob2"] ?? "N/A"));
          }
        });
      } else {
        print('Unexpected response format: ${jsonResponse.runtimeType}');
      }
    } else {
      print('Request failed with status: ${response.statusCode}'); // Handle non-200 responses
    }
  } catch (e) {
    print('Request error: $e'); // Handle request errors
  }
}

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose(); // Dispose of each controller
    }
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: themeColor,
      title: Text(
        widget.itemname,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    body: userData.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView.builder(
              itemCount: userData.length,
              itemBuilder: (context, index) {
                if (index < _controllers.length) {
                  final item = userData[index];
                  return Card(
                    margin: const EdgeInsets.only(top: 2, left: 10, right: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: TextEditingController(text: item["AM_AccName"] ?? "N/A"),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Name',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: TextEditingController(text: item["AM_AccCode"] ?? "N/A"),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Code',
                            ),
                            readOnly: true,
                          ),
                          
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: TextEditingController(text: item["AM_AccAlias"] ?? "N/A"),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Display Name',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: TextEditingController(text: item["AD_Address1"] ?? "N/A"),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Address',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: TextEditingController(text: item["AD_CGSTNo"] ?? "N/A"),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'GST No',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: TextEditingController(text: item["AD_GState"] ?? "N/A"),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'GST State',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: TextEditingController(text: item["AD_Transport"] ?? "N/A"),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Transport',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: TextEditingController(text: item["AgentName"] ?? "N/A"),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Agent',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: TextEditingController(text: item["AD_CtPerson1"] ?? "N/A"),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Contatct 1',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: TextEditingController(text: item["AD_CtMob1"] ?? "N/A"),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Contact NO.1',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: TextEditingController(text: item["AD_CtPerson2"] ?? "N/A"),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Contatct 2',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: TextEditingController(text: item["AD_CtMob2"] ?? "N/A"),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Contact NO.2',
                            ),
                            readOnly: true,
                          ),
                          // Additional fields can be added here
                        ],
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
    bottomNavigationBar: BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Other buttons can be added here (e.g., Save)
          
          // Cancel button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Navigate back to the previous screen
                },
                child: const Text('Cancel'), // Button label
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}