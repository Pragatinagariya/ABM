import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'unit_read.dart';
import 'globals.dart' as globals;

class UnitList extends StatefulWidget {
  final String username;
  final String clientcode;
  final String clientname;
  final String clientMap;

  const UnitList({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
  });

  @override
  State<UnitList> createState() => UnitListState();
}

class UnitListState extends State<UnitList> {
  List userData = [];

  @override
  void initState() {
    super.initState();
    getRecord();
  }

  // Future<void> getRecord() async {
  //   String uri =
  //       "${uriname}read_unit.php?clientcode=$clientcode&cmp=$cmpcode";
  //   try {
  //     var response = await http.get(Uri.parse(uri));
  //     print('Raw response body: ${response.body}');
  //     if (response.statusCode == 200) {
  //       var jsonResponse;
  //       try {
  //         jsonResponse = jsonDecode(response.body);
  //         print('Parsed JSON Response: $jsonResponse');
  //       } catch (e) {
  //         print('JSON decoding error: $e');
  //         return;
  //       }
  //       if (jsonResponse is List) {
  //         setState(() {
  //           userData = jsonResponse;
  //           print("State updated with ${userData.length} items");
  //         });
  //       }
  //     } else {
  //       print('Request failed with status: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Request error: $e');
  //   }
  // }
  Future<void> getRecord() async {
    String uri = "http://intern.amisys.in:3000/unit";

    // ✅ Check if token is available
    if (globals.token.isEmpty) {
      print('Token is empty. Cannot proceed with request.');
      return;
    }

    try {
      var response = await http.get(
        Uri.parse(uri),
        headers: {
          'Authorization':
              'Bearer ${globals.token}', // ✅ Use token from globals
        },
      );

      print('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        var jsonResponse;
        try {
          jsonResponse = jsonDecode(response.body);
          print('Parsed JSON Response: $jsonResponse');
        } catch (e) {
          print('JSON decoding error: $e');
          return;
        }

        if (jsonResponse is List) {
          setState(() {
            userData = jsonResponse;
            print("State updated with ${userData.length} items");
          });
        } else {
          print('Unexpected data format: $jsonResponse');
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Unit'),
      ),
      body: userData.isEmpty
          ? const Center(
              child: Text("No data found",
                  style: TextStyle(
                    fontSize: 20,
                  )),
            )
          : ListView.builder(
              itemCount: userData.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UnitDetail(
                          unid: userData[index]["UM_Id"]?.toString() ?? '',
                          unitcode:
                              userData[index]["UM_UnitCode"]?.toString() ?? '',
                          ununit: userData[index]["UM_Unit"]?.toString() ?? '',
                          username: widget.username,
                          clientcode: widget.clientcode,
                          clientname: widget.clientname,
                          clientMap: widget.clientMap,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(top: 2, left: 10, right: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Row(
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        // const TextSpan(
                                        //   text: 'Due Days: ',
                                        //   style: TextStyle(
                                        //       color: Colors.grey,
                                        //       fontSize: 13), // Label in grey
                                        // ),
                                        TextSpan(
                                          text:
                                              '${userData[index]["UM_UnitCode"] ?? "N/A"}',
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 13), // Data in black
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    '-',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        // const TextSpan(
                                        //   text: 'Due Date: ',
                                        //   style: TextStyle(
                                        //       color: Colors.grey,
                                        //       fontSize: 13), // Label in grey
                                        // ),
                                        TextSpan(
                                          text:
                                              '${userData[index]["UM_Unit"] ?? "N/A"}',
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 13), // Data in black
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                        ],
                      ),
                    ),
                  ),
                ); // Close InkWell here
              },
            ),
    );
  }
}
