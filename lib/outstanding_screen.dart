import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'outstanding_detail.dart';
import 'package:dropdown_search/dropdown_search.dart';

class OutstandingScreen extends StatefulWidget {
  final String username;
  final String clientcode;
  final String clientname;
  final String clientMap;

  const OutstandingScreen({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
  });

  @override
  State<OutstandingScreen> createState() => OutstandingScreenState();
}

class OutstandingScreenState extends State<OutstandingScreen> {
  List<dynamic> userData = [];
  List<dynamic> filteredData = [];

  String? selectedAgent;
  String? selectedCustomer;
  String? sortOption;

  Set<String> agentList = {};
  Set<String> customerList = {};

  @override
  void initState() {
    super.initState();
    getRecord();
  }

  Future<void> getRecord() async {
    String uri =
        "${uriname}outstanding_cust.php?clientcode=$clientcode&cmp=$cmpcode";
    print("Requesting URL: $uri");

    try {
      var response = await http.get(Uri.parse(uri));
      print('Raw response: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response looks like JSON
        if (response.body.trim().startsWith('{') ||
            response.body.trim().startsWith('[')) {
          var jsonResponse = jsonDecode(response.body);

          if (jsonResponse is List) {
            List<Map<String, dynamic>> mappedData = jsonResponse
                .whereType<Map<String, dynamic>>() // ensure only valid maps
                .toList();

            setState(() {
              userData = mappedData;
              filteredData = List.from(userData);

              agentList = mappedData
                  .map((e) => e['d_agentname']?.toString() ?? '')
                  .where((name) => name.isNotEmpty)
                  .toSet();

              customerList = mappedData
                  .map((e) => e['d_accname']?.toString() ?? '')
                  .where((name) => name.isNotEmpty)
                  .toSet();
            });
          } else {
            print('Unexpected JSON structure');
          }
        } else {
          print('❌ Response not in JSON format.');
          print(response.body);
        }
      } else {
        print('❌ Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Request error: $e');
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7, // 70% of screen height initially
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Filter Options",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Customer Dropdown with "-- All --"
                  DropdownSearch<String>(
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    items: ['-- All --', ...customerList.toList()],
                    selectedItem: selectedCustomer ?? '-- All --',
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "-- Select Customer --",
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedCustomer =
                            (value == '-- All --') ? null : value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Agent Dropdown with "-- All --"
                  DropdownSearch<String>(
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    items: ['-- All --', ...agentList.toList()],
                    selectedItem: selectedAgent ?? '-- All --',
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "-- Select Agent --",
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedAgent = (value == '-- All --') ? null : value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Sort Option Dropdown
                  DropdownButton<String>(
                    isExpanded: true,
                    value: sortOption,
                    hint: const Text("-- Sort By --"),
                    items: [
                      'Customer Name A-Z',
                      'Customer Name Z-A',
                      'Amount Low to High',
                      'Amount High to Low',
                    ].map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        sortOption = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Apply & Reset Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _applyFilters,
                        child: const Text("Apply"),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedAgent = null;
                            selectedCustomer = null;
                            sortOption = null;
                            filteredData = List.from(userData);
                          });
                          Navigator.pop(context);
                        },
                        child: const Text("Reset"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _applyFilters() {
    List<dynamic> data = userData;

    if (selectedCustomer != null) {
      data =
          data.where((item) => item['d_accname'] == selectedCustomer).toList();
    }

    if (selectedAgent != null) {
      data =
          data.where((item) => item['d_agentname'] == selectedAgent).toList();
    }

    if (sortOption != null) {
      switch (sortOption) {
        case 'Customer Name A-Z':
          data.sort((a, b) => a['d_accname'].compareTo(b['d_accname']));
          break;
        case 'Customer Name Z-A':
          data.sort((a, b) => b['d_accname'].compareTo(a['d_accname']));
          break;
        case 'Amount Low to High':
          data.sort((a, b) => double.parse(a['d_billamt'])
              .compareTo(double.parse(b['d_billamt'])));
          break;
        case 'Amount High to Low':
          data.sort((a, b) => double.parse(b['d_billamt'])
              .compareTo(double.parse(a['d_billamt'])));
          break;
      }
    }

    setState(() {
      filteredData = data;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Outstanding Customer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: filteredData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(top: 2, left: 10, right: 5),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    title: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Tooltip(
                              message:
                                  filteredData[index]["d_accname"] ?? 'No name',
                              child: Text(
                                filteredData[index]["d_accname"] ?? 'No name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Agent: ',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    TextSpan(
                                      text:
                                          '${filteredData[index]["d_agentname"] ?? 'No agent name'}',
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'City: ',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    TextSpan(
                                      text:
                                          '${filteredData[index]["d_acccity"] ?? 'No city'}',
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.currency_rupee,
                                color: Colors.red, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              '${filteredData[index]["d_billamt"] ?? '0.00'}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OutstandingDetailScreen(
                            accid: filteredData[index]["d_accid"] ?? '',
                            accname: filteredData[index]["d_accname"] ?? '',
                            username: widget.username,
                            clientcode: widget.clientcode,
                            clientname: widget.clientname,
                            clientMap: widget.clientMap,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
