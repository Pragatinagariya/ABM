import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart';

class UnitDetail extends StatefulWidget {
  final String username;
  final String clientcode;
  final String clientname;
  final String clientMap;
  final String unid;
  final String unitcode;
  final String ununit;

  const UnitDetail({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
    required this.unid,
    required this.unitcode,
    required this.ununit,
  });

  @override
  State<UnitDetail> createState() => _UnitDetailState();
}

class _UnitDetailState extends State<UnitDetail> {
  List userData = [];
  final List<TextEditingController> _controllers = [];
  final _formKey = GlobalKey<FormState>(); // Key for form validation

  @override
  void initState() {
    super.initState();
    getRecord();
  }

  // Future<void> getRecord() async {
  //   String uri =
  //       "${uriname}unit_details.php?UM_Id=${widget.unid}&clientcode=$clientcode&cmp=$cmpcode";
  //   try {
  //     var response = await http.get(Uri.parse(uri));
  //     if (response.statusCode == 200) {
  //       var jsonResponse;
  //       try {
  //         jsonResponse = jsonDecode(response.body); // Decode the JSON response
  //       } catch (e) {
  //         print('JSON decoding error: $e');
  //         return; // Early return on error
  //       }

  //       // Check if the response is a list
  //       if (jsonResponse is List) {
  //         setState(() {
  //           userData = jsonResponse; // Update userData state
  //           // Initialize controllers based on userData length
  //           _controllers.clear(); // Clear previous controllers
  //           for (var item in userData) {
  //             _controllers
  //                 .add(TextEditingController(text: item["UM_Id"] ?? "N/A"));
  //             _controllers.add(
  //                 TextEditingController(text: item["UM_UnitCode"] ?? "N/A"));
  //             _controllers
  //                 .add(TextEditingController(text: item["UM_Unit"] ?? "N/A"));
  //           }
  //         });
  //       } else {
  //         print('Unexpected response format: ${jsonResponse.runtimeType}');
  //       }
  //     } else {
  //       print(
  //           'Request failed with status: ${response.statusCode}'); // Handle non-200 responses
  //     }
  //   } catch (e) {
  //     print('Request error: $e'); // Handle request errors
  //   }
  // }

  Future<void> getRecord() async {
  String uri = "http://intern.amisys.in:3000/unit/${widget.unid}";
  
  if (token.isEmpty) {
    print('Token is empty. Cannot proceed with request.');
    return;
  }

  try {
    var response = await http.get(
      Uri.parse(uri),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body);
      } catch (e) {
        print('JSON decoding error: $e');
        return;
      }

      if (jsonResponse is List) {
        // ✅ If response is a list of records
        setState(() {
          userData = jsonResponse;
          _controllers.clear();
          for (var item in userData) {
            _controllers.add(TextEditingController(
                text: (item["UM_Id"] ?? "N/A").toString())); // ✅ Convert to string
            _controllers.add(TextEditingController(
                text: (item["UM_UnitCode"] ?? "N/A").toString())); // ✅ Convert to string
            _controllers.add(TextEditingController(
                text: (item["UM_Unit"] ?? "N/A").toString())); // ✅ Convert to string
          }
        });
      } else if (jsonResponse is Map) {
        // ✅ If response is a single record
        setState(() {
          userData = [jsonResponse];
          _controllers.clear();
          _controllers.add(TextEditingController(
              text: (jsonResponse["UM_Id"] ?? "N/A").toString())); // ✅ Convert to string
          _controllers.add(TextEditingController(
              text: (jsonResponse["UM_UnitCode"] ?? "N/A").toString())); // ✅ Convert to string
          _controllers.add(TextEditingController(
              text: (jsonResponse["UM_Unit"] ?? "N/A").toString())); // ✅ Convert to string
        });
      } else {
        print('Unexpected response format: ${jsonResponse.runtimeType}');
      }
    } else {
      print('Request failed with status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (e) {
    print('Request error: $e');
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
          widget.unitcode,
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
                            // TextFormField(
                            //   controller: TextEditingController(
                            //       text: item["UM_Id"] ?? "N/A"),
                            //   decoration: const InputDecoration(
                            //     border: OutlineInputBorder(),
                            //     labelText: 'Unit ID',
                            //   ),
                            //   readOnly: true,
                            // ),
                            // const SizedBox(height: 24),
                            TextFormField(
                              controller: TextEditingController(
                                  text: item["UM_UnitCode"] ?? "N/A"),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Unit Code',
                              ),
                              readOnly: true,
                            ),
                            const SizedBox(height: 25),
                            TextFormField(
                              controller: TextEditingController(
                                  text: item["UM_Unit"] ?? "N/A"),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Unit',
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
                    backgroundColor: themeColor,
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