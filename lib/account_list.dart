import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'account_read.dart';

class AccountList extends StatefulWidget {
  final String username; // Add username parameter
  final String clientcode;
  final String clientname;
  final String clientMap;

  const AccountList({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
  }); // Accept username in constructor

  @override
  State<AccountList> createState() => AccountListState();
}

class AccountListState extends State<AccountList> {
  List userData = [];

  @override
  void initState() {
    super.initState();
    getRecord();
  }

  Future<void> getRecord() async {
    String uri =
        "${uriname}account_list.php?clientcode=$clientcode&cmp=$cmpcode"; // Pass username in the query
    try {
      var response = await http.get(Uri.parse(uri));
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
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Request error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('Account'),
      ),
      body: userData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: userData.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountDetail(
                          itemid: userData[index]["AM_AccId"] ?? '',
                          itemname: userData[index]["AM_AccName"] ?? '',
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Displaying Account ID
                          Text(
                            userData[index]["AM_AccName"] ?? "N/A",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          // Spacing
                          // const SizedBox(height: 5),
                          // // Displaying Account Code below Account ID
                          // RichText(
                          //   text: TextSpan(
                          //     children: [
                          //       const TextSpan(
                          //         text: 'Code: ',
                          //         style: TextStyle(color: Colors.grey),
                          //       ),
                          //       TextSpan(
                          //         text: userData[index]["AM_AccCode"] ?? "N/A",
                          //         style: const TextStyle(color: Colors.black),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          // // Spacing
                          // const SizedBox(height: 5),
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     Expanded(
                          //       // Wrap with Expanded for text wrapping
                          //       child: RichText(
                          //         text: TextSpan(
                          //           children: [
                          //             const TextSpan(
                          //               text: 'Name: ',
                          //               style: TextStyle(
                          //                   color: Colors.grey, fontSize: 13),
                          //             ),
                          //             TextSpan(
                          //               text: userData[index]["AM_AccName"] ??
                          //                   "N/A",
                          //               style: const TextStyle(
                          //                   color: Colors.black, fontSize: 13),
                          //             ),
                          //           ],
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          // // Spacing
                          // const SizedBox(height: 5),
                          // Row(
                          //   children: [
                          //     Expanded(
                          //       // Wrap with Expanded for text wrapping
                          //       child: RichText(
                          //         text: TextSpan(
                          //           children: [
                          //             const TextSpan(
                          //               text: 'Alias: ',
                          //               style: TextStyle(color: Colors.grey),
                          //             ),
                          //             TextSpan(
                          //               text: userData[index]["AM_AccAlias"] ??
                          //                   "N/A",
                          //               style: const TextStyle(
                          //                   color: Colors.black),
                          //             ),
                          //           ],
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
