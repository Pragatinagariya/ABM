import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'item_read.dart';

class AccountListBygroup extends StatefulWidget {
  final String username; // Add username parameter
  final String clientcode;
  final String clientname;
  final String clientMap;
  final String itemid;
  final String itemname;

  const AccountListBygroup({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
    required this.itemid,
    required this.itemname,
  }); // Accept username in constructor

  @override
  State<AccountListBygroup> createState() => AccountListBygroupState();
}

class AccountListBygroupState extends State<AccountListBygroup> {
  List userData = [];

  @override
  void initState() {
    super.initState();
    getRecord();
  }

  Future<void> getRecord() async {
    String uri =
        "${uriname}account_list_by_group.php?clientcode=$clientcode&cmp=$cmpcode&groupid=${widget.itemid}";
    // "${uriname}item_list_by_itemgroup.php?username=${widget.username}&clientcode=${widget.clientcode}&itemgroupid=${widget.itemgroupid}"; // Pass username in the query
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          widget.itemname,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.045, // responsive font size
          ),
        ),
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
                        builder: (context) => ItemDetail(
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
                    margin: EdgeInsets.only(
                      top: screenHeight * 0.005,
                      left: screenWidth * 0.03,
                      right: screenWidth * 0.02,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.025),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  userData[index]["AM_AccName"] ?? "N/A",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.04,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.005),
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
