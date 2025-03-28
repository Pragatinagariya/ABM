
import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'hsn_read.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HsnRead extends StatefulWidget {
  final String username; // Add username parameter
  final String clientcode;
  final String clientname;
  final String clientMap;
  const HsnRead(
      {super.key,
      required this.username,
      required this.clientcode,
      required this.clientname,
      required this.clientMap}); // Accept username in constructor

  @override
  State<HsnRead> createState() => HsnReadState();
}

class HsnReadState extends State<HsnRead> {
  List hsnData = [];
  late Database _database;
  List<Map<String, dynamic>> _switchOptions = [];
  bool _isFieldVisible(String zKeyword) {
  final option = _switchOptions.firstWhere(
    (element) => element['z_keyword'] == zKeyword,
    orElse: () => {'z_keyvalue': 0},
  );
  return option['z_keyvalue'] == 1;
}

  @override
  void initState() {
    super.initState();
    getRecord();
    _initializeDatabase();
  }

  Future<void> getRecord() async {
    String uri =
        "${uriname}hsn_read.php?clientcode=$clientcode&cmp=$cmpcode"; // Pass username in the query
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
            hsnData = jsonResponse;
            print("State updated with ${hsnData.length} items");
          });
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Request error: $e');
    }
  }
Future<void> _initializeDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'z_settings.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE z_settings(id INTEGER PRIMARY KEY, z_page TEXT, z_flag TEXT, z_keyword TEXT, z_keyvalue INTEGER, z_remarks TEXT)',
        );
      },
      version: 1,
    );
    await _loadSwitchOptions();
  }
  Future<void> _loadSwitchOptions() async {
    final List<Map<String, dynamic>> options = await _database.query('z_settings', where: 'z_page = ?', whereArgs: ['HSN']);
    if (options.isEmpty) {
      // Insert default values if table is empty
      await _database.insert('z_settings', {
      'z_page': 'HSN',
      'z_flag': '',
      'z_keyword': 'Remarks',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'HSN',
      'z_flag': '',
      'z_keyword': 'Description',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'HSN',
      'z_flag': '',
      'z_keyword': 'GST',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'HSN',
      'z_flag': '',
      'z_keyword': 'CGST',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'HSN',
      'z_flag': '',
      'z_keyword': 'SGST',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'HSN',
      'z_flag': '',
      'z_keyword': 'IGST',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'HSN',
      'z_flag': '',
      'z_keyword': 'Cess',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
      _loadSwitchOptions();
    } else {
      setState(() {
      _switchOptions = options.map((item) {
        return {
          'id': item['id'],
          'z_page': item['z_page'],
          'z_flag': item['z_flag'],
          'z_keyword': item['z_keyword'],
          'z_keyvalue': item['z_keyvalue'],
          'z_remarks': item['z_remarks'],
        };
      }).toList();
    });
    }
  }
 void _showListSettings(BuildContext context) async {
  // Fetch data from the 'z_settings' table for the 'Supplier' page
  List<Map<String, dynamic>> settings = await _database.query(
    'z_settings',
    where: 'z_page = ?',
    whereArgs: ['HSN'],
  );

  // Show the settings in a dialog with switches
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('List Settings'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: settings.map((option) {
                return SwitchListTile(
                  title: Text(option['z_keyword']),  // Display the setting name (e.g., "GST No")
                  value: option['z_keyvalue'] == 1,  // ON/OFF based on z_keyvalue
                  onChanged: (value) async {
                    // Update the visibility in the database immediately
                    await _updateVisibility(option['id'], value);

                    // Reload the settings from the database to get the latest state
                    List<Map<String, dynamic>> updatedSettings = await _database.query(
                      'z_settings',
                      where: 'z_page = ?',
                      whereArgs: ['HSN'],
                    );

                    // Update the local settings state in the dialog
                    setState(() {
                      // Update the local list with the new values
                      settings = updatedSettings; // Directly replace with the updated list
                    });
                  },
                  activeColor: Colors.green,  // Customize the active color
                  inactiveThumbColor: Colors.grey,  // Customize the inactive thumb color
                  inactiveTrackColor: Colors.grey,  // Customize the inactive track color
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

Future<void> _updateVisibility(int id, bool value) async {
  // Update the setting visibility in the database
  await _database.update(
    'z_settings',
    {'z_keyvalue': value ? 1 : 0},  // Set the visibility value based on the switch state
    where: 'id = ?',
    whereArgs: [id],
  );
  await _loadSwitchOptions();
}
   @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('HSN Code'),
        actions: [
          PopupMenuButton<int>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 1) {
              _showListSettings(context); // When List Settings is selected, open it
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<int>(
              value: 1,
              child: Text('List Settings'), // This opens the data list
            ),
          ],
        ),
      ],
      ),
      body: hsnData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: hsnData.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HsnDetails(
                          hsnid: hsnData[index]["HM_Id"],
                          hsncode: hsnData[index]["HM_HSNCode"],
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
                            children: [
                              // Text(
                              //   hsnData[index]["HM_Id"] ?? "N/A",
                              //   style: const TextStyle(fontWeight: FontWeight.bold),
                              // ),
                              // const SizedBox(width: 2),
                              // const Text(
                              //   '|',
                              //   style: TextStyle(color: Colors.black),
                              // ),
                              // const SizedBox(width: 2),
                              Text(
                                hsnData[index]["HM_HSNCode"] ?? "N/A",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 100),
                              if (_isFieldVisible('Remarks'))
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Remarks: ',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                      ),
                                      TextSpan(
                                        text:
                                            hsnData[index]["HM_Remarks"] ?? "N/A",
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                            ],
                          ),
                          const SizedBox(
                              height: 5), // Increased spacing for clarity
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_isFieldVisible('Discription'))
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Desc: ',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                      ),
                                      TextSpan(
                                        text:
                                            hsnData[index]["HM_Desc"] ?? "N/A",
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              if (_isFieldVisible('GST'))
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'GST: ',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                      ),
                                      TextSpan(
                                        text: hsnData[index]["HM_GSTPerc"] ??
                                            "N/A",
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              if (_isFieldVisible('CGST'))
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'CGST: ',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                      ),
                                      TextSpan(
                                        text: hsnData[index]["HM_CGST"],
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          if (_isFieldVisible('SGST'))
                          // Additional Rows for CGST, SGST, IGST, Cess
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'SGST: ',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                      ),
                                      TextSpan(
                                        text:
                                            hsnData[index]["HM_SGST"] ?? "N/A",
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              if (_isFieldVisible('IGST'))
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'IGST: ',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                      ),
                                      TextSpan(
                                        text:
                                            hsnData[index]["HM_IGST"] ?? "N/A",
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              if (_isFieldVisible('Cess'))
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Cess: ',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                      ),
                                      TextSpan(
                                        text:
                                            hsnData[index]["HM_Cess"] ?? "N/A",
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
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