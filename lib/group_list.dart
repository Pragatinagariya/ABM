import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'account_list_by_group.dart';
import 'group_read.dart';

class GroupList extends StatefulWidget {
  final String username;
  final String clientcode;
  final String clientname;
  final String clientMap;

  const GroupList({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
  });

  @override
  State<GroupList> createState() => GroupListState();
}

class GroupListState extends State<GroupList> {
  List userData = [];

  @override
  void initState() {
    super.initState();
    getRecord();
  }

  Future<void> getRecord() async {
    String uri = "${uriname}group_list.php?clientcode=$clientcode&cmp=$cmpcode";
    print(uri);
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
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Group'),
      ),
      body: userData.isEmpty
          ? const Center(
              child: Text('No data found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )))
          : ListView.builder(
              itemCount: userData.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(top: 2, left: 10, right: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AccountListBygroup(
                                    itemid: userData[index]["groupid"] ?? '',
                                    itemname:
                                        userData[index]["groupname"] ?? '',
                                    username: widget.username,
                                    clientcode: widget.clientcode,
                                    clientname: widget.clientname,
                                    clientMap: widget.clientMap,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData[index]["groupname"] ?? "N/A",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                // const SizedBox(height: 2),
                                // Text(
                                //   '(${userData[index]["IM_GroupName"] ?? "N/A"})',
                                // ),
                              ],
                            ),
                          ),
                        ),
                        // IconButton on the right side
                        IconButton(
                          icon:
                              const Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupDetail(
                                  itemid: userData[index]["groupid"] ?? '',
                                  itemname: userData[index]["groupname"] ?? '',
                                  username: widget.username,
                                  clientcode: widget.clientcode,
                                  clientname: widget.clientname,
                                  clientMap: widget.clientMap,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
