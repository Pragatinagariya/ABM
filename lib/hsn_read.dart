import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart';

class HsnDetails extends StatefulWidget {
  final String username;
  final String clientcode;
  final String clientname;
  final String clientMap;
  final String hsnid;
  final String hsncode;

  const HsnDetails({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
    required this.hsnid,
    required this.hsncode,
  });

  @override
  State<HsnDetails> createState() => _HsnDetailsState();
}

class _HsnDetailsState extends State<HsnDetails> {
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
        "${uriname}hsn_details.php?HM_Id=${widget.hsnid}&clientcode=$clientcode&cmp=$cmpcode";
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
            for (var hsn in userData) {
              _controllers
                  .add(TextEditingController(text: hsn["hsnid"] ?? "N/A"));
              _controllers
                  .add(TextEditingController(text: hsn["hsncode"] ?? "N/A"));
              _controllers
                  .add(TextEditingController(text: hsn["hsndesc"] ?? "N/A"));
              _controllers
                  .add(TextEditingController(text: hsn["gstperc"] ?? "N/A"));
              _controllers
                  .add(TextEditingController(text: hsn["cgst"] ?? "N/A"));
              _controllers
                  .add(TextEditingController(text: hsn["sgst"] ?? "N/A"));
              _controllers
                  .add(TextEditingController(text: hsn["igst"] ?? "N/A"));
              _controllers
                  .add(TextEditingController(text: hsn["cess"] ?? "N/A"));
            }
          });
        } else {
          print('Unexpected response format: ${jsonResponse.runtimeType}');
        }
      } else {
        print(
            'Request failed with status: ${response.statusCode}'); // Handle non-200 responses
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
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          widget.hsncode,
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
                  final itemIndex =
                      index * 8; // Calculate starting index for each card
                  return Card(
                    margin: const EdgeInsets.only(top: 2, left: 10, right: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _controllers[itemIndex + 1],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'HSN Code',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _controllers[itemIndex + 2],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Description',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _controllers[itemIndex + 3],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'GST Percentage',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _controllers[itemIndex + 4],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'CGST',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _controllers[itemIndex + 5],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'SGST',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _controllers[itemIndex + 6],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'IGST',
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _controllers[itemIndex + 7],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Cess',
                            ),
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),
                  );
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
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context)
                        .pop(); // Navigate back to the previous screen
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