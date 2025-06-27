import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'item_read.dart';

class ItemList extends StatefulWidget {
  final String username; // Add username parameter
  final String clientcode;
  final String clientname;
  final String clientMap;

  const ItemList({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
  }); // Accept username in constructor

  @override
  State<ItemList> createState() => ItemListState();
}

class ItemListState extends State<ItemList> {
  List userData = [];
  bool isLoading = true; // <-- Add loading flag

  @override
  void initState() {
    super.initState();
    getRecord();
  }

  Future<void> getRecord() async {
    String uri =
        "${uriname}item_list.php?clientcode=${widget.clientcode}&cmp=$cmpcode";
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
          setState(() {
            isLoading = false;
          });
          return;
        }

        if (jsonResponse is List) {
          setState(() {
            userData = jsonResponse;
            isLoading = false;
            print("State updated with ${userData.length} items");
          });
        } else {
          setState(() {
            userData = [];
            isLoading = false;
          });
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
        setState(() {
          userData = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Request error: $e');
      setState(() {
        userData = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Item'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData.isEmpty
              ? const Center(
                  child: Text(
                    "Data Not Found",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  itemCount: userData.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetail(
                              itemid: userData[index]["IM_ItemId"] ?? '',
                              itemname: userData[index]["IM_ItemName"] ?? '',
                              username: widget.username,
                              clientcode: widget.clientcode,
                              clientname: widget.clientname,
                              clientMap: widget.clientMap,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin:
                            const EdgeInsets.only(top: 2, left: 10, right: 5),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (userData[index]["IM_ItemName"]
                                                as String?) ??
                                            "N/A",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '(${userData[index]["IM_GroupName"] ?? "N/A"})',
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.currency_rupee,
                                          color: Colors.red, size: 15),
                                      Flexible(
                                        child: Text(
                                          '${userData[index]["IM_SRate1"] ?? '0.00'}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                    );
                  },
                ),
    );
  }
}
