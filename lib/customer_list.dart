
import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'customer_read.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomerList extends StatefulWidget {
  final String username; // Add username parameter
  final String clientcode;
  final String clientname;
  final String clientMap;

  const CustomerList({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
  }); // Accept username in constructor

  @override
  State<CustomerList> createState() => CustomerListState();
}

class CustomerListState extends State<CustomerList> {
  List userData = [];
  String nameFilter = '';
  List<String> Names = [];
  String selectedFilter = '';
  String selectedNameRange = 'A-Z'; // Set default to 'A-Z'
  List<dynamic> filteredData = [];
  TextEditingController gstController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  String agentFilter = '';
  List<String> agentNames = [];
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
    _fetchNames();
    _fetchAgentNames();
     _initializeDatabase();
  }

  Future<void> getRecord() async {
    String uri =
        "${uriname}customer_list.php?clientcode=$clientcode&cmp=$cmpcode";

    // Add filters to the URL if they are not empty
    if (nameFilter.isNotEmpty) {
      uri += "&nameFilter=$nameFilter";
    }
    // if (groupFilter.isNotEmpty) {
    //   uri += "&groupFilter=$groupFilter";
    // }
    // if (agentFilter.isNotEmpty) {
    //   uri += "&rateFilter=$agentFilter";
    // }
    try {
      var response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        setState(() {
          userData = jsonResponse
              .map((e) => e as Map<String, dynamic>)
              .toList(); // Safely cast to Map<String, dynamic>

          filteredData = List.from(userData); // Initially show all data
        });
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Request error: $e');
    }
  }
  void _showFilterOptions(BuildContext context) {
  selectedFilter = "Name"; // Default to 'Name' filter

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                // Content of the Bottom Sheet
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        color: Colors.grey[300],
                        width: MediaQuery.of(context).size.width * 0.3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Row(
                                children: const [
                                  Text("Name"),
                                ],
                              ),
                              onTap: () {
                                setModalState(() => selectedFilter = "Name");
                              },
                            ),
                            const Divider(),
                            ListTile(
                              title: const Text("GST No."),
                              onTap: () {
                                setModalState(() => selectedFilter = "GST No.");
                              },
                            ),
                            const Divider(),
                            ListTile(
                              title: const Text("Agent"),
                              onTap: () {
                                setModalState(() => selectedFilter = "Agent");
                              },
                            ),
                            const Divider(),
                             ListTile(
                              title: const Text("City"),
                              onTap: () {
                                setModalState(() => selectedFilter = "City");
                              },
                            ),
                            const Divider(),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                selectedFilter ?? "Select Filter",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (selectedFilter == "Name")
                              _buildNameFilter(setModalState),
                            if (selectedFilter == "GST No.")
                            _buildGSTFilter(setModalState),
                            if (selectedFilter == "Agent")
                            _buildAgentFilter(setModalState),
                             if (selectedFilter == "City")
                            _buildCityFilter(setModalState),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Done button at the bottom
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _applyFilters(); // Apply the filters when clicked
                      Navigator.pop(context); // Close the bottom sheet
                    },
                     style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor, // Set the background color
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  ).then((_) {
    // Call the function to apply filters after bottom sheet is closed
    // _applyFilters();
  });
}
Widget _buildCityFilter(StateSetter setModalState) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: TextField(
      controller: cityController,
      decoration: const InputDecoration(
        labelText: "Enter City",
        border: OutlineInputBorder(),
      ),
    ),
  );
}

void _applyFilters() {
  setState(() {
    // Start with full data only if no filters are applied yet
    if (filteredData.isEmpty || filteredData.length == userData.length) {
      filteredData = List.from(userData);
    }

     // Apply Name Filter if selectedNameRange is not empty
    if (nameFilter != '--Select--' && nameFilter.isNotEmpty) {
      filteredData = filteredData.where((item) {
        return item["AM_AccName"] == nameFilter;
      }).toList();
    }

    // Apply GST No. filter without overwriting existing filtered data
    if (selectedFilter == "GST No.") {
      String gstValue = gstController.text.trim();
      if (gstValue.isNotEmpty) {
        filteredData = filteredData.where((item) {
          String gstNo = item["AD_CGSTNo"]?.toString() ?? '';
          return gstNo.toLowerCase().contains(gstValue.toLowerCase());
        }).toList();
      }
    }

    // Apply Agent filter without overwriting existing filtered data
    if (agentFilter != '--Select--' && agentFilter.isNotEmpty) {
      filteredData = filteredData.where((item) {
        return item["AgentName"] == agentFilter;
      }).toList();
    }

    // Apply City filter without overwriting existing filtered data
    if (selectedFilter == "City") {
      String cityValue = cityController.text.trim();
      if (cityValue.isNotEmpty) {
        filteredData = filteredData.where((item) {
          String city = item["AD_City"]?.toString() ?? '';
          return city.toLowerCase().contains(cityValue.toLowerCase());
        }).toList();
      }
    }

    print("Filtered Data after applying filters: $filteredData");
  });
}

Widget _buildGSTFilter(StateSetter setModalState) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: TextField(
      controller: gstController,
      decoration: const InputDecoration(
        labelText: "Enter GST Number",
        border: OutlineInputBorder(),
      ),
    ),
  );
}
Widget _buildNameFilter(StateSetter setModalState) {
  return Column(
    children: [
      // Dropdown for group selection
      DropdownButton<String>(
        value: nameFilter == '' ? '--Select--' : nameFilter, // Default to '--Select--'
        hint: Text('Select Customer'), // Placeholder text
        isExpanded: true, // Makes dropdown take the full width
        items: ['--Select--', ...Names] // Add '--Select--' at the top of the list
            .map((String name) {
          return DropdownMenuItem<String>(
            value: name,
            child: Text(name),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setModalState(() {
            nameFilter = newValue ?? '--Select--'; // Set selected agent or '--Select--'
          });
        },
      ),
    ],
  );
}
Future<void> _fetchNames() async {
  try {
    final response = await http.get(Uri.parse(
        '${uriname}customer_list.php?clientcode=$clientcode&cmp=$cmpcode'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        setState(() {
          // Extract 'AgentName', remove duplicates, and sort in ascending order
          Names = data
              .where((item) =>
                  item['AM_AccName'] != null && item['AM_AccName'].isNotEmpty)
              .map((item) => item['AM_AccName'] as String)
              .toSet()
              .toList();

          // Sort the agent names in ascending order
          Names.sort();

          // Ensure agentFilter is set to '--Select--' initially
          nameFilter = '--Select--'; 
          
          print('Fetched names: $Names');
        });
      } else {
        print('No transport names found in the API response.');
      }
    } else {
      print('Failed to load transport names. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching transport names: $e');
  }
}
 
Widget _buildAgentFilter(StateSetter setModalState) {
  return Column(
    children: [
      // Dropdown for group selection
      DropdownButton<String>(
        value: agentFilter == '' ? '--Select--' : agentFilter, // Default to '--Select--'
        hint: Text('Select Agent'), // Placeholder text
        isExpanded: true, // Makes dropdown take the full width
        items: ['--Select--', ...agentNames] // Add '--Select--' at the top of the list
            .map((String agent) {
          return DropdownMenuItem<String>(
            value: agent,
            child: Text(agent),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setModalState(() {
            agentFilter = newValue ?? '--Select--'; // Set selected agent or '--Select--'
          });
        },
      ),
    ],
  );
}
Future<void> _fetchAgentNames() async {
  try {
    final response = await http.get(Uri.parse(
        '${uriname}customer_list.php?clientcode=$clientcode&cmp=$cmpcode'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        setState(() {
          // Extract 'AgentName', remove duplicates, and sort in ascending order
          agentNames = data
              .where((item) =>
                  item['AgentName'] != null && item['AgentName'].isNotEmpty)
              .map((item) => item['AgentName'] as String)
              .toSet()
              .toList();

          // Sort the agent names in ascending order
          agentNames.sort();

          // Ensure agentFilter is set to '--Select--' initially
          agentFilter = '--Select--'; 
          
          print('Fetched agent names: $agentNames');
        });
      } else {
        print('No agent names found in the API response.');
      }
    } else {
      print('Failed to load agent names. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching agent names: $e');
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
    final List<Map<String, dynamic>> options = await _database.query('z_settings', where: 'z_page = ?', whereArgs: ['Customer']);
    if (options.isEmpty) {
      // Insert default values if table is empty
      await _database.insert('z_settings', {
      'z_page': 'Customer',
      'z_flag': '',
      'z_keyword': 'Customer',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'Customer',
      'z_flag': '',
      'z_keyword': 'GST No',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'Customer',
      'z_flag': '',
      'z_keyword': 'Agent',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'Customer',
      'z_flag': '',
      'z_keyword': 'City',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'Customer',
      'z_flag': '',
      'z_keyword': 'Mobile',
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
    whereArgs: ['Customer'],
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
                      whereArgs: ['Customer'],
                    );

                    // Update the local settings state in the dialog
                    setState(() {
                      // Update the local list with the new values
                      settings = updatedSettings; // Directly replace with the updated list
                    });
                  },
                  activeColor: themeColor,  // Customize the active color
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
  Future<void> _launchPhoneDialer(String phoneNumber) async {
  var status = await Permission.phone.request();
  if (status.isGranted) {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunch(phoneUri.toString())) {
      await launch(phoneUri.toString());
    } else {
      throw 'Could not launch $phoneNumber';
    }
  } else {
    throw 'Phone permission not granted';
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('Customer'),
        actions: [
        IconButton(
          icon: const Icon(Icons.filter_alt),
          onPressed: () {
            _showFilterOptions(context); // Trigger the filter dialog
          },
        ),
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
      
      body: Column(
          children: [
            Expanded(
              child: filteredData.isEmpty
                  ? Center(
                      child: Text(
                        'No Data found',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    )
                  : ListView.builder(
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                  final item = filteredData[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerDetail(
                          itemid: item["AM_AccId"] ?? '',
                          itemname: item["AM_AccName"] ?? '',
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
                          // Displaying City and Account ID together
                       if (_isFieldVisible('Customer'))
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                item["AM_AccName"] ?? "N/A",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),

                          // Spacing
                          const SizedBox(height: 5),
                          // Displaying GST NO
                          if (_isFieldVisible('GST No'))
                            RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'GST NO: ',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  TextSpan(
                                    text: item["AD_CGSTNo"] ?? "N/A",
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                            ),

                          // Spacing
                          const SizedBox(height: 5),
                          if (_isFieldVisible('Agent'))
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Agent: ',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                      ),
                                      TextSpan(
                                        text: item["AgentName"] ??
                                            "N/A",
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
                          if (_isFieldVisible('City'))
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'City: ',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                      ),
                                      TextSpan(
                                        text:
                                            item["AD_City"] ?? "N/A",
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Spacing
                          const SizedBox(height: 5),
                          if (_isFieldVisible('Mobile'))
                          Row(
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Mobile: ',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      TextSpan(
                                        text: item["AD_Mobile1"] ??
                                            "N/A",
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                      icon: const Icon(Icons.phone, color: Colors.blue),
                                      onPressed: () {
                                        // Pass the fetched phone number to the dialer method
                                        _launchPhoneDialer(item["AD_Mobile1"] ?? "N/A");
                                      },
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            ),
          ],
        ),
    );
  }
}
