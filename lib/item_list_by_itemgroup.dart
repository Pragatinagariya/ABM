import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'item_read.dart';

class ItemListByItemgroup extends StatefulWidget {
  final String username; // Add username parameter
  final String clientcode;
  final String clientname;
  final String clientMap;
  final String itemid;
  final String itemname;

  const ItemListByItemgroup({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
    required this.itemid,
    required this.itemname,
  }); // Accept username in constructor

  @override
  State<ItemListByItemgroup> createState() => ItemListByItemgroupState();
}

class ItemListByItemgroupState extends State<ItemListByItemgroup> {
  List userData = [];
  List<Map<String, dynamic>> _items = [];
   bool _isSearching = false;
TextEditingController searchController = TextEditingController();
FocusNode searchFocusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    getRecord();
  }


 Future<void> getRecord({String search = ""}) async {
  String uri =
      "${uriname}item_list_by_itemgroup.php?clientcode=$clientcode&cmp=$cmpcode&itemgroupid=${widget.itemid}";

  // Append search parameter only if it's not empty
  if (search.isNotEmpty) {
    uri += "&search=$search";
  }

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
      appBar:AppBar(
  backgroundColor: themeColor,
  title: _isSearching
      ? SizedBox(
          width: 250,
          height: 38,
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode, // Set the focus node
            onChanged: (value) {
              getRecord(search: value); // Call the function with search input
            },
            decoration: InputDecoration(
              hintText: 'Search...',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    searchController.clear();
                  });
                  getRecord(); // Fetch full list when search is cleared
                  searchFocusNode.unfocus(); // Unfocus when cleared
                },
              ),
            ),        ),
        )
      : const Text('Item'),
  actions: [
    !_isSearching
        ? IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
              // Trigger focus to open keyboard
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FocusScope.of(context).requestFocus(searchFocusNode);
              });
            },
          )
        : Container(),
  ],
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
                    margin: const EdgeInsets.only(top: 2, left: 10, right: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    (userData[index]["IM_ItemName"]
                                            as String?) ??
                                        "N/A", // Cast to String
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
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
