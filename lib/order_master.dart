import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'order_edit.dart';
import 'package:intl/intl.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'order_new.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'challan_new.dart';
import 'package:sqflite/sqflite.dart';
import 'shared_pref_helper.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';

class OrderMaster extends StatefulWidget {
  final String username; // Add username parameter
  final String clientcode;
  final String clientname;
  final String clientMap;
  final String cmpcode;
  final List<Map<String, dynamic>> orders;
  const OrderMaster(
      {super.key,
      required this.username,
      required this.clientcode,
      required this.clientname,
      required this.clientMap,
      required this.cmpcode,
      required this.orders
      
      }); // Accept username in constructor
      

  @override
  State<OrderMaster> createState() => OrderMasterState();
}

class OrderMasterState extends State<OrderMaster> {
  List userData = [];
  String flag = '';
  String nameFilter = '';
  List<String> Names = [];
  String selectedFilter = '';
  String selectedNameRange = 'A-Z'; // Set default to 'A-Z'
  List<dynamic> filteredData = [];
  TextEditingController invoiceController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  DateTime? fromDate; // For Custom Date Range
  DateTime? toDate;
  String? _selectedDateRange;
  String selectedDateFilter = ''; // Stores the selected date filter
  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  String agentFilter = '';
  List<String> agentNames = [];
  String transportFilter = '';
  List<String> transportNames = [];
  List<String> dropdownItems = ['--Select--', 'Order List', 'CustWise Outstanding'];
  String selectedItem = '--Select--';
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  late Database _database;
 

  List<Map<String, dynamic>> _switchOptions = [];
  bool _isFieldVisible(String zKeyword) {
  final option = _switchOptions.firstWhere(
    (element) => element['z_keyword'] == zKeyword,
    orElse: () => {'z_keyvalue': 0},
  );
  return option['z_keyvalue'] == 1;
}
 RangeValues rateRange = const RangeValues(0, 10000000);

  @override
  void initState() {
    super.initState();
    // print("Received cmpcode in OrderMaster: ${widget.cmpcode}");
    
    getRecord();
    _fetchNames();
    _fetchAgentNames();
    _fetchTransportNames();
    _initializeDatabase();
  }
bool _shouldRefresh = false; // Flag to track if we need to refresh

// @override
// void didChangeDependencies() {
//   super.didChangeDependencies();
//   if (_shouldRefresh) {
//     _shouldRefresh = false; // Reset flag
//     getRecord(); // Refresh list when user comes back
//   }
// }


  Future<void> getRecord() async {
  await SharedPrefHelper.debugSharedPreferences();
  print("clientcode----------${clientcode}");
  print("cmpcode----------${widget.cmpcode}");

  String uri = "${uriname}orders.php?clientcode=${clientcode}&cmp=${cmpcode}";
  print('${uri}');

  try {
    var response = await http.get(Uri.parse(uri));
    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);

      if (jsonResponse.isEmpty) {
        print('No data received from API.');
        setState(() {
          userData = []; // Ensure it's not null
          filteredData = [];
        });
        return; // Stop execution to prevent further errors
      }

      setState(() {
        userData = jsonResponse.map((e) => e as Map<String, dynamic>).toList();
        filteredData = List.from(userData);
      });
    } else {
      print('Request failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print('Request error: $e');
  }
}



  Future<void> deleteOrderData(int omId) async {
  if (omId == 0) {
    print('Error: Invalid Order ID');
    return; // Stop execution if no valid order ID is provided
  }

  final url = Uri.parse('${uriname}order_delete.php');
  print('Delete URL: $url');

  final payload = {
    "clientcode": clientcode,  // Ensure correct client code
    "cmp": cmpcode,            // Ensure correct company code
    "om_id": omId.toString(),          // Pass the order ID
  };

  print('Sending payload: ${json.encode(payload)}');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        print('✅ Order deleted successfully: ${responseData['message']}');
      } else {
        print('❌ Server Error: ${responseData['message']}');
      }
    } else {
      print('❌ HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    print('❌ Network Error: $error');
  }
}
 Color getCardColor(Map<String, dynamic> item) {
  print("Raw RefQty: ${item["om_refqty"]}, Raw PendingQty: ${item["om_pendingqty"]}");

  double refQty = double.tryParse(item["om_refqty"]?.toString().trim() ?? "0") ?? 0.0;
  double pendingQty = double.tryParse(item["om_pendingqty"]?.toString().trim() ?? "0") ?? 0.0;

  print("Parsed RefQty: $refQty, Parsed PendingQty: $pendingQty");

  if (refQty == 0) {
    return Colors.pink.shade100; // Pink when RefQty = 0
  } else if (refQty > 0 && pendingQty > 0) {
    return Colors.blue.shade100; // Blue when RefQty > 0 and PendingQty > 0
  } else if (pendingQty == 0) {
    return Colors.green.shade100; // Green when PendingQty = 0
  }

  return Colors.white;  // Default
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
                                title: Row(
                                  children: const [
                                    Text("Date"),
                                  ],
                                ),
                                onTap: () {
                                  setModalState(() => selectedFilter = "Date");
                                },
                              ),
                              const Divider(),
                            //   ListTile(
                            //   title: Row(
                            //     children: const [
                            //       Text("Invoice"),
                            //     ],
                            //   ),
                            //   onTap: () {
                            //     setModalState(() => selectedFilter = "Invoice");
                            //   },
                            // ),
                            // const Divider(),
                            ListTile(
                              title: Row(
                                children: const [
                                  Text("Agent"),
                                ],
                              ),
                              onTap: () {
                                setModalState(() => selectedFilter = "Agent");
                              },
                            ),
                            const Divider(),
                            ListTile(
                              title: Row(
                                children: const [
                                  Text("Transport"),
                                ],
                              ),
                              onTap: () {
                                setModalState(() => selectedFilter = "Transport");
                              },
                            ),
                            const Divider(),
                            ListTile(
                              title: Row(
                                children: const [
                                  Text("Rate"),
                                ],
                              ),
                              onTap: () {
                                setModalState(() => selectedFilter = "Rate");
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
                              if (selectedFilter == "Date")
                              _buildDateFilter(setModalState),
                              // if (selectedFilter == "Invoice")
                              // _buildInvoiceFilter(setModalState),
                              if (selectedFilter == "Agent")
                             _buildAgentFilter(setModalState),
                             if (selectedFilter == "Transport")
                             _buildTransportFilter(setModalState),
                            if (selectedFilter == "Rate")
                                _buildRateFilter(setModalState),
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
                        backgroundColor:themeColor
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
Widget _buildNameFilter(StateSetter setModalState) {
  return Column(
    children: [
      // Dropdown for group selection
      DropdownButton<String>(
        value: nameFilter == '' ? '--Select--' : nameFilter, // Default to '--Select--'
        hint: Text('Select Name'), // Placeholder text
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
        '${uriname}orders.php?clientcode=${clientcode}&cmp=${cmpcode}'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        setState(() {
          // Extract 'AgentName', remove duplicates, and sort in ascending order
          Names = data
              .where((item) =>
                  item['CustName'] != null && item['CustName'].isNotEmpty)
              .map((item) => item['CustName'] as String)
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
Widget _buildDateFilter(StateSetter setModalState) {
  final dateOptions = [
    'This Year',
    'This Month',
    'Last Month',
    'This Week',
    'Yesterday',
    'Today',
    'Custom Date Range',
  ];

  return Column(
    children: [
      for (var option in dateOptions)
        RadioListTile<String>(
          title: Text(option),
          value: option,
          groupValue: selectedDateFilter,
          onChanged: (value) {
            setModalState(() {
              selectedDateFilter = value!;
              _setDateRange(value); // Apply the selected date range
            });
          },
        ),
      if (selectedDateFilter == 'Custom Date Range')
        Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                DateTime? pickedStartDate = await DatePicker.showSimpleDatePicker(
                  context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  dateFormat: "dd-MM-yyyy",
                  titleText: "Select Start Date",
                  locale: DateTimePickerLocale.en_us,
                );
                if (pickedStartDate != null) {
                  setModalState(() {
                    startDate = pickedStartDate;
                  });
                }
              },
              child: Text(
                "Select Start Date: ${startDate != null ? startDate.toString().split(' ')[0] : 'Not Selected'}"),
            ),
            ElevatedButton(
              onPressed: () async {
                DateTime? pickedEndDate = await DatePicker.showSimpleDatePicker(
                  context,
                  initialDate: DateTime.now(),
                  firstDate: startDate ?? DateTime(2000),
                  lastDate: DateTime.now(),
                  dateFormat: "dd-MM-yyyy",
                  titleText: "Select End Date",
                  locale: DateTimePickerLocale.en_us,
                );
                if (pickedEndDate != null) {
                  setModalState(() {
                    endDate = pickedEndDate;
                  });
                }
              },
              child: Text(
                "Select End Date: ${endDate != null ? endDate.toString().split(' ')[0] : 'Not Selected'}"),
            ),
          ],
        ),
    ],
  );
}
void filterByDate(String dateFilter) {
  setState(() {
    DateTime now = DateTime.now();
    DateTime? startDateFilter;
    DateTime? endDateFilter;

    switch (dateFilter) {
      case 'This Year':
        startDateFilter = DateTime(now.year, 1, 1);
        endDateFilter = DateTime(now.year, 12, 31);
        break;
      case 'This Month':
        startDateFilter = DateTime(now.year, now.month, 1);
        endDateFilter = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Last Month':
        startDateFilter = DateTime(now.year, now.month - 1, 1);
        endDateFilter = DateTime(now.year, now.month, 0);
        break;
      case 'This Week':
        startDateFilter = now.subtract(Duration(days: now.weekday - 1)); // Monday
        endDateFilter = startDateFilter.add(Duration(days: 6)); // Sunday
        break;
      case 'Yesterday':
        startDateFilter = DateTime(now.year, now.month, now.day - 1);
        endDateFilter = startDateFilter;
        break;
      case 'Today':
        startDateFilter = DateTime(now.year, now.month, now.day);
        endDateFilter = startDateFilter;
        break;
      default:
        return;
    }

    // Log for debugging
    print("Start Date: $startDateFilter");
    print("End Date: $endDateFilter");

    // Apply the filtering
    filteredData = filteredData.where((item) {
      final dateStr = item["om_date"];
      DateTime? itemDate = parseDate(dateStr);
      if (itemDate != null) {
        return (itemDate.isAtSameMomentAs(startDateFilter!) || itemDate.isAfter(startDateFilter)) &&
               (itemDate.isAtSameMomentAs(endDateFilter!) || itemDate.isBefore(endDateFilter));
      }
      return false;
    }).toList();

    // Log filtered data
    print("Filtered Data: $filteredData");
  });
}


 void _setDateRange(String option) {
  DateTime now = DateTime.now();
  switch (option) {
    case 'This Year':
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31);
      break;
    case 'This Month':
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0);
      break;
    case 'Last Month':
      startDate = DateTime(now.year, now.month - 1, 1);
      endDate = DateTime(now.year, now.month, 0);
      break;
    case 'This Week':
      startDate = now.subtract(Duration(days: now.weekday - 1)); // Monday of this week
      endDate = startDate?.add(const Duration(days: 6));
      break;
    case 'Yesterday':
      startDate = DateTime(now.year, now.month, now.day - 1);
      endDate = startDate; // Only one day range
      break;
    case 'Today':
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate; // Only one day range
      break;
  }
}

DateTime? parseDate(String? dateStr) {
  try {
    if (dateStr != null && dateStr.isNotEmpty) {
      return DateFormat('dd-MM-yyyy').parse(dateStr); // Parse DD-MM-YYYY format
    }
  } catch (e) {
    print("Date parsing error: $e");
  }
  return null;
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
        '${uriname}orders.php?clientcode=${clientcode}&cmp=${cmpcode}'));

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
 Widget _buildTransportFilter(StateSetter setModalState) {
  return Column(
    children: [
      // Dropdown for group selection
      DropdownButton<String>(
        value: transportFilter == '' ? '--Select--' : transportFilter, // Default to '--Select--'
        hint: Text('Select Transport'), // Placeholder text
        isExpanded: true, // Makes dropdown take the full width
        items: ['--Select--', ...transportNames] // Add '--Select--' at the top of the list
            .map((String transport) {
          return DropdownMenuItem<String>(
            value: transport,
            child: Text(transport),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setModalState(() {
            transportFilter = newValue ?? '--Select--'; // Set selected agent or '--Select--'
          });
        },
      ),
    ],
  );
}
Future<void> _fetchTransportNames() async {
  try {
    final response = await http.get(Uri.parse(
        '${uriname}orders.php?clientcode=${clientcode}&cmp=${cmpcode}'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        setState(() {
          // Extract 'AgentName', remove duplicates, and sort in ascending order
          transportNames = data
              .where((item) =>
                  item['om_transport'] != null && item['om_transport'].isNotEmpty)
              .map((item) => item['om_transport'] as String)
              .toSet()
              .toList();

          // Sort the agent names in ascending order
          transportNames.sort();

          // Ensure agentFilter is set to '--Select--' initially
          transportFilter = '--Select--'; 
          
          print('Fetched transport names: $transportNames');
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
  Widget _buildRateFilter(StateSetter setModalState) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Select Rate Range",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        // Container to control the width of the slider
        SizedBox(
          width: MediaQuery.of(context).size.width *
              0.8, // Adjust the width as needed
          child: RangeSlider(
            values: rateRange,
            min: 0, // Min value
            max: 10000000, // Max value
            divisions: 100000, // Adjust for finer granularity
            labels: RangeLabels(
              rateRange.start.round().toString(),
              rateRange.end.round().toString(),
            ),
            onChanged: (RangeValues values) {
              // Update the rateRange using setModalState
              setModalState(() {
                rateRange = values;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Selected Range: ₹${rateRange.start.toStringAsFixed(0)} - ₹${rateRange.end.toStringAsFixed(0)}",
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  void filterByRate(RangeValues rateRange) {
    setState(() {
      filteredData = filteredData.where((item) {
        final itemRate = double.tryParse(item["IM_SRate1"].toString()) ?? 0.0;

        // Ensure the rate exists and falls within the selected range
        return itemRate >= rateRange.start && itemRate <= rateRange.end;
      }).toList();

      print(
          "Filtered data by rate: $filteredData"); // Debugging: Check filtered data
    });
  }

void _applyFilters() {
  setState(() {
    // Start with the complete dataset
    filteredData = List.from(userData);

    // Apply Name Filter if selectedNameRange is not empty
    if (nameFilter != '--Select--' && nameFilter.isNotEmpty) {
      filteredData = filteredData.where((item) {
        return item["CustName"] == nameFilter;
      }).toList();
    }

    // Apply Date Range Filter if startDate and endDate are selected
    if (startDate != null && endDate != null) {
      filteredData = filteredData.where((item) {
        final dateStr = item["om_date"] ?? item["om_date"];
        DateTime? itemDate = parseDate(dateStr);
        if (itemDate != null) {
          return (itemDate.isAtSameMomentAs(startDate!) || itemDate.isAfter(startDate!)) &&
                 (itemDate.isAtSameMomentAs(endDate!) || itemDate.isBefore(endDate!));
        }
        return false;
      }).toList();
    }

    // Apply Agent Filter if agentFilter is selected and not empty
    if (agentFilter != '--Select--' && agentFilter.isNotEmpty) {
      filteredData = filteredData.where((item) {
        return item["AgentName"] == agentFilter;
      }).toList();
    }

    // Apply Transport Filter if transportFilter is selected and not empty
    if (transportFilter != '--Select--' && transportFilter.isNotEmpty) {
      filteredData = filteredData.where((item) {
        return item["om_transport"] == transportFilter;
      }).toList();
    }
    // Apply Rate Filter
      filterByRate(rateRange);

    // Log the results
    print("Filtered Data after applying filters: $filteredData");
  });
}

Future<void> _generatePDF(String omId) async {
  final apiUrl =
      '${uriname}order_formate_pdf.php?clientcode=${clientcode}&cmp=${cmpcode}&om_id=$omId';

  try {
    // Fetching data from the API based on om_id
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);

      // Debugging the response
      print("Response Data: $userData");

      // Check if the response contains data
      if (userData is List && userData.isNotEmpty) {
        // Initialize PDF document
        final pdf = pw.Document();

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4.copyWith(
                marginTop: 20, // Adjust top margin
                marginLeft: 20, // Adjust left margin
                marginRight: 20, // Adjust right margin
                marginBottom: 20, // Adjust bottom margin
              ),
              build: (pw.Context context) {
                final int totalqty =
                    int.tryParse(userData[0]['om_total_quantity'].toString()) ?? 0;
                final double totalrate =
                    double.tryParse(userData[0]['om_amt'].toString()) ?? 0.0;

                return pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                        width: 3,
                      ),
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(20)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          widget.clientname,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text('Exclusive Dress Materials',
                            style: pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 10),
                        pw.Text(
                            'E-25, Ground Floor, Sumel Business Park-1 (Safal),',
                            style: pw.TextStyle(fontSize: 10)),
                        pw.Text(
                            'B/h. New Cloth Market, Sarangpur, Ahmedabad-1.',
                            style: pw.TextStyle(fontSize: 10)),
                        pw.Text(
                            'Ph. No.: 079 22191185 Mo: 09998260490, 08980072422, 9913910663',
                            style: pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 10),
                        pw.Text(
                            'GSTIN: 24ADGPP7174D1ZJ        MSME No: UDYAM-GJ-01-00000',
                            style: pw.TextStyle(fontSize: 10)),
                        pw.Divider(),
                        pw.Text(
                          'ORDER FORM', style: pw.TextStyle(fontWeight: pw.FontWeight.bold,),
                        ),
                        pw.Divider(),

                        // Row with two columns (expanded for equal space)
                        pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.start,
                              crossAxisAlignment: pw.CrossAxisAlignment.start, // Ensure alignment from the top
                              children: [
                                pw.Expanded(
                                  child: pw.Align(
                                    alignment: pw.Alignment.topLeft, // Align content to the top
                                    child: pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text('Customer: ${userData[0]['CustName']}',
                                            style: pw.TextStyle(fontSize: 10)),
                                        pw.Text('Address: 4158, NAI SARAK, DELHI, 110006, Delhi',
                                            style: pw.TextStyle(fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ),
                                pw.SizedBox(width: 10), // Add spacing instead of a divider
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Row(
                                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text('Order No: ${userData[0]['om_invno']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                          pw.Text('Date: ${userData[0]['om_date']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                      pw.Row(
                                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text('Cust Ref No: ${userData[0]['om_custrefno']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                          pw.Text('Date: ${userData[0]['om_custrefdate']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                      pw.Text('Agent: ${userData[0]['AgentName']}',
                                          style: pw.TextStyle(fontSize: 10)),
                                      pw.Text('Transport: ${userData[0]['om_transport']}',
                                          style: pw.TextStyle(fontSize: 10)),
                                      pw.Row(
                                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text('Payment Days: ${userData[0]['om_pymtdays']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                          pw.Text('Delivery Days: ${userData[0]['om_deliverydays']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                        pw.Divider(color: PdfColors.black),
                        // Item Details Header
                        pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                'Sr No',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                'Item Name',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                'Qty',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                'Unit',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                'Rate',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                'Total',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        pw.Divider(color: PdfColors.black),

                        // Item Rows
                        ...userData.map((order) {
                          final int srNo = int.tryParse(order['ot_srno'].toString()) ?? 0;
                          final String itemName = order['IM_ItemName'] ?? '';
                          final int qty = int.tryParse(order['ot_qty'].toString()) ?? 0;
                          final double rate = double.tryParse(order['ot_rate'].toString()) ?? 0.0;
                          final double total = qty * rate;

                          return pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 1,
                                child: pw.Text(srNo.toString(),
                                    style: pw.TextStyle(fontSize: 10)),
                              ),
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(itemName,
                                    style: pw.TextStyle(fontSize: 10)),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Text(
                                  qty.toString(),
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Text(
                                  'pcs', // Default unit
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Text(
                                  rate.toStringAsFixed(2),
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Text(
                                  total.toStringAsFixed(2),
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          );
                        }),

                        // Divider before totals
                        pw.Divider(color: PdfColors.black),

                        // Row for displaying totals
                        pw.Row(
                          children: [
                            pw.Expanded(flex: 1, child: pw.Text('')), // Empty space
                            pw.Expanded(flex: 3,  child: pw.Text('Total', style: pw.TextStyle(fontSize: 12,  fontWeight: pw.FontWeight.bold))), // 'Total' text
                            pw.Expanded(
                                flex: 1,
                                child: pw.Text(totalqty.toString(),
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(fontSize: 10))), // Total quantity
                            pw.Expanded(flex: 1, child: pw.Text('')), // Empty space
                            pw.Expanded(flex: 1, child: pw.Text('')), // Empty space
                            pw.Expanded(
                                flex: 1,
                                child: pw.Text(totalrate.toStringAsFixed(2),
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(fontSize: 10))), // Total amount (same as rate)
                          ],
                        ),

                        pw.Divider(color: PdfColors.black),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Payment Terms: Payment within 30 days.'),
                                pw.Text('Delivery Terms: Delivery within 0 days.'),
                                pw.Text('No guarantee for color, zari & material.'),
                              ],
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

          // Save PDF to a file
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/order_formate.pdf');
          await file.writeAsBytes(await pdf.save());

          // Share the PDF file
          await Share.shareFiles([file.path], text: 'Order Formate PDF');
        } else {
          throw Exception('Unexpected data format');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching or generating PDF: $e');
    }
  }
  Future<void> orderList() async {
  final apiUrl =
      '${uriname}orders.php?clientcode=${clientcode}&cmp=${cmpcode}';

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Response Data: $data");

      if (data is List) {
        final pdf = pw.Document();
        const int itemsPerPage = 17; // Items per page
        final totalPages = (data.length / itemsPerPage).ceil(); // Total pages
        final totalBillAmount = data.fold<double>(
          0.0,
          (sum, item) => sum + (double.tryParse(item["om_billamt"] ?? '0') ?? 0.0),
        ); // Calculate total bill amount
        int globalSrNo = 1; // Initialize global serial number

        for (int pageNum = 0; pageNum < totalPages; pageNum++) {
          final startIndex = pageNum * itemsPerPage;
          final endIndex = startIndex + itemsPerPage;
          final pageData = data.sublist(
            startIndex,
            endIndex > data.length ? data.length : endIndex,
          );

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.all(16),
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Header for the first page only
                    if (pageNum == 0) ...[
                      pw.Text(widget.clientMap,
                          style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold),),
                      pw.SizedBox(height: 2),
                      pw.Text('Exclusive Dress Materials', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('E-25, Ground Floor, Sumel Business Park-1 (Safal),', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('B/h. New Cloth Market, Sarangpur, Ahmedabad-1.', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Ph. No.: 079 22191185 Mo: 09998260490, 08980072422, 9913910663', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('GSTIN: 24ADGPP7174D1ZJ        MSME No: UDYAM-GJ-01-00000', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        'As on ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.Divider(),
                    ],
                    // Table Header
                    pw.Table(
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1),
                        1: const pw.FlexColumnWidth(1.5),
                        2: const pw.FlexColumnWidth(2),
                        3: const pw.FlexColumnWidth(2.5),
                        4: const pw.FlexColumnWidth(2),
                        5: const pw.FlexColumnWidth(2.5),
                        6: const pw.FlexColumnWidth(2),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Text('Sr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('Invoice', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('Customer', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('City', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('Agent', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('Bill Amt', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)
                          ],
                        ),
                      ],
                    ),
                    pw.Divider(),

                    // Data Rows
                    pw.Table(
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1),
                        1: const pw.FlexColumnWidth(1.5),
                        2: const pw.FlexColumnWidth(2),
                        3: const pw.FlexColumnWidth(2.5),
                        4: const pw.FlexColumnWidth(2),
                        5: const pw.FlexColumnWidth(2.5),
                        6: const pw.FlexColumnWidth(2),
                      },
                      children: [
                        for (int i = 0; i < pageData.length; i++)
                          pw.TableRow(
                            children: [
                              pw.Text('${globalSrNo++}'),
                              pw.Text(pageData[i]["om_invno"] ?? "N/A"),
                              pw.Text(pageData[i]["om_date"] ?? "N/A"),
                              pw.Text(pageData[i]["CustName"] ?? "N/A"),
                              pw.Text(pageData[i]["CustCity"] ?? "N/A"),
                              pw.Text(pageData[i]["AgentName"] ?? "N/A"),
                              pw.Text(
                                '${pageData[i]["om_billamt"] ?? "0.0"}',
                                textAlign: pw.TextAlign.right, // Use this for text alignment
                              ),
                            ],
                          ),
                      ],
                    ),
                    pw.SizedBox(height: 10),

                    // Total Amount on the last page only
                    if (pageNum == totalPages - 1) ...[
                      pw.Divider(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total:',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(totalBillAmount.toStringAsFixed(1),
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          );
        }

        // Print the document
        await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save());
      }
    } else {
      print('Failed to fetch data from API');
    }
  } catch (e) {
    print("Error: $e");
  }
}
Future<void> custWise() async {
  final apiUrl =
      '${uriname}order_custwise.php?clientcode=${clientcode}&cmp=${cmpcode}';

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Response Data: $data");

      if (data is List) {
        final pdf = pw.Document();
        const int itemsPerPage = 17; // Items per page
        final totalPages = (data.length / itemsPerPage).ceil(); // Total pages
        int globalSrNo = 1; // Initialize global serial number

        for (int pageNum = 0; pageNum < totalPages; pageNum++) {
          final startIndex = pageNum * itemsPerPage;
          final endIndex = startIndex + itemsPerPage;
          final pageData = data.sublist(
            startIndex,
            endIndex > data.length ? data.length : endIndex,
          );
          final totalBillAmount = data.fold<double>(
          0.0,
          (sum, item) =>
              sum + (double.tryParse(item["om_billamt"] ?? '0') ?? 0.0),
        );

        final totalPendingAmount = data.fold<double>(
          0.0,
          (sum, item) =>
              sum + (double.tryParse(item["PendingAmt"] ?? '0') ?? 0.0),
        );

        final totalRcvdAmount = data.fold<double>(
          0.0,
          (sum, item) =>
              sum + (double.tryParse(item["RcvdAmt"] ?? '0') ?? 0.0),
        );

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.all(16),
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Header for the first page only
                    if (pageNum == 0) ...[
                      pw.Text(widget.clientMap,
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('Exclusive Dress Materials',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('E-25, Ground Floor, Sumel Business Park-1 (Safal),',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('B/h. New Cloth Market, Sarangpur, Ahmedabad-1.',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          'Ph. No.: 079 22191185 Mo: 09998260490, 08980072422, 9913910663',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                          'GSTIN: 24ADGPP7174D1ZJ        MSME No: UDYAM-GJ-01-00000',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        'As on ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                      pw.Divider(),
                    ],
                    // Order Details for each page
                    pw.Row(
                      children: [
                        pw.Text('Customer: ${pageData[0]['CustName']}',style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 16),
                       pw.Text('MSME No.:${pageData[0]['']}',style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 16),
                        pw.Text('Agent: ${pageData[0]['AgentName']}',style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    // Table Header
                      pw.Table(
                        border: pw.TableBorder.all(
                          color: PdfColors.black, // Border color
                          width: 0.5,             // Border width
                        ),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(0.5),
                        1: const pw.FlexColumnWidth(0.5),
                        2: const pw.FlexColumnWidth(1),
                        3: const pw.FlexColumnWidth(1.5),
                        4: const pw.FlexColumnWidth(1),
                        5: const pw.FlexColumnWidth(0.5),
                        6: const pw.FlexColumnWidth(1),
                        7: const pw.FlexColumnWidth(1),
                        8: const pw.FlexColumnWidth(1),
                        9: const pw.FlexColumnWidth(1),
                        10: const pw.FlexColumnWidth(1),
                      },
                      children: [
                        pw.TableRow(
                          
                          children: [
                            pw.Text('Sr', textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7,fontWeight: pw.FontWeight.bold)),
                            pw.Text('Inv.no', textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7,fontWeight: pw.FontWeight.bold)),
                            pw.Text('Inv.Date', textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7,fontWeight: pw.FontWeight.bold)),
                            pw.Text('Transport', textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7,fontWeight: pw.FontWeight.bold)),
                            pw.Text('Haste', textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7,fontWeight: pw.FontWeight.bold)),
                            pw.Text('Due', textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7,fontWeight: pw.FontWeight.bold)),
                            pw.Text('Bill Amt', textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7,fontWeight: pw.FontWeight.bold)),
                            pw.Text('Rcvd Amt', textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7,fontWeight: pw.FontWeight.bold)),
                            pw.Text('Rcpt Date', textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7,fontWeight: pw.FontWeight.bold)),
                            pw.Text('OnAccount', textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7,fontWeight: pw.FontWeight.bold)),
                            pw.Text('Pending Amt', textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7,fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        for (int i = 0; i < pageData.length; i++)
                          pw.TableRow(
                            children: [
                              pw.Text('${globalSrNo++}', textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7)),
                              pw.Text(pageData[i]["om_invno"] ?? "N/A", textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7)),
                              pw.Text(pageData[i]["om_date"] ?? "N/A", textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7)),
                              pw.Text(pageData[i]["om_transport"] ?? "N/A",style: pw.TextStyle(fontSize: 7)),
                              pw.Text(pageData[i]["HasteName"] ?? "N/A", textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7)),
                              pw.Text(pageData[i][""] ?? "N/A", textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7)),
                              pw.Text(pageData[i]["om_billamt"] ?? "N/A", textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7)),
                              pw.Text(pageData[i][""] ?? "N/A", textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7)),
                              pw.Text(pageData[i][""] ?? "N/A", textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7)),
                              pw.Text(pageData[i][""] ?? "N/A", textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7)),
                              pw.Text(
                                '${pageData[i][""] ?? "0.0"}',
                                textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7)
                              ),
                            ],
                          ),
                           pw.TableRow(
                        children: [
                          pw.Text(''),
                          pw.Text(''),
                          pw.Text(''),
                          pw.Text(''),
                          pw.Text(''),
                          pw.Text(''),
                          pw.Text(''),
                           pw.Text(totalBillAmount.toStringAsFixed(2),
                              textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7)),
                          pw.Text(totalRcvdAmount.toStringAsFixed(2),
                              textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7)),
                          pw.Text(''),
                          pw.Text(''),
                          pw.Text(totalPendingAmount.toStringAsFixed(2),
                              textAlign: pw.TextAlign.center,style: pw.TextStyle(fontSize: 7)),
                        ],
                      ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    // Total Amount on the last page only
                    if (pageNum == totalPages - 1) ...[
                      pw.Divider(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total:',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(totalBillAmount.toStringAsFixed(1),
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          );
        }

        // Print the document
        await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save());
      }
    } else {
      print('Failed to fetch data from API');
    }
  } catch (e) {
    print("Error: $e");
  }
}

Future<void> _initializeDatabase() async {
    _database = await openDatabase(
      p.join(await getDatabasesPath(), 'z_settings.db'),
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
  final List<Map<String, dynamic>> options = 
      await _database.query('z_settings', where: 'z_page = ?', whereArgs: ['Order']);

  if (options.isEmpty) {
    // Insert default values for Supplier page if not present
    await _database.insert('z_settings', {
      'z_page': 'Order',
      'z_flag': '',
      'z_keyword': 'Customer',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'Order',
      'z_flag': '',
      'z_keyword': 'Transport',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'Order',
      'z_flag': '',
      'z_keyword': 'Agent',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'Order',
      'z_flag': '',
      'z_keyword': 'Quantity',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'Order',
      'z_flag': '',
      'z_keyword': 'No of Item',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'Order',
      'z_flag': '',
      'z_keyword': 'Bill Amount',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
    await _database.insert('z_settings', {
      'z_page': 'Order',
      'z_flag': '',
      'z_keyword': 'Assignment',
      'z_keyvalue': 1,
      'z_remarks': ''
    });
     await _database.insert('z_settings', {
      'z_page': 'Order',
      'z_flag': '',
      'z_keyword': 'Share',
      'z_keyvalue': 1,
      'z_remarks': ''
    });

    // Reload options after inserting
    await _loadSwitchOptions();
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
    whereArgs: ['Order'],
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
                      whereArgs: ['Order'],
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

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('Orders'),
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
        // Dropdown above the ListView
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center horizontally
          crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
          children: [
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  value: selectedItem,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedItem = newValue!;
                    });
                  },
                  items: dropdownItems.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                if (selectedItem == "Order List") {
                    orderList();
                  } else if (selectedItem == "CustWise Outstanding") {
                    custWise();
                  }
              },
            ),
          ],
        ),
        Expanded(
          child: filteredData.isEmpty
              ? const Center(
                  child: Text('No Data Found',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                )
              : Expanded(
                child: ListView.builder(
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final item = filteredData[index]; // Access the map directly here
                      return InkWell(
                  onTap: () async {
                    setState(() {
                    flag = 'Edit'; // Set the flag to 'new' when an item is added
                  });
                  print('Flag value before navigating: $flag'); 
                  final selectedOmId = (item["om_id"] != null) ? item["om_id"].toString() : '';
                
                        print("Passing om_id: $selectedOmId");
                         final omQty = item['om_qty']?.toString() ?? "0";
                         final omPendingQty = item['om_pendingqty']?.toString() ?? "0";
final omVerify = item["om_verify"].toString();  // Ensure it's a string
                    final result = await Navigator.push(
                      context,
                     MaterialPageRoute(
                       builder: (context) => OrderNew(
                 omid: selectedOmId,
                
                  username: widget.username,
                  clientcode: widget.clientcode,
                  clientname: widget.clientname,
                  clientMap: widget.clientMap,
                  cmpcode:cmpcode,
                  orders: widget.orders.cast<Map<String, dynamic>>(),
                  IdController: TextEditingController(),
                  DateController: TextEditingController(),
                  flag: flag,
                  omQty:omQty,
                  omPendingQty:omPendingQty,
                  isApproveDisabled: (omVerify == '1' || omVerify.toLowerCase() == 'approved'), // Pass flag
                ),
                  
                                ),
                              );
                               // Print the value to debug
                
                              if (result == true) {
                                setState(() {
                                  getRecord(); // Refresh data after returning
                                });
                              }
                            },
                            
                        child: Card(
                           color: getCardColor(item),
                          
                          // color: item["om_verify"] == "Approved" ? Colors.white : Colors.white,
                         margin: EdgeInsets.only(top: 12, left: 10, right: 10), // Adjust the margin here
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(item["om_invno"] ?? "N/A",
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 5),
                                              const Text('|', style: TextStyle(color: Colors.black)),
                                              const SizedBox(width: 5),
                                              Text(item["om_date"] ?? "N/A"),
                                            ],
                                          ),
                                          if (_isFieldVisible('Customer'))
                                          Text(
                                            item["CustName"] ?? 'No name',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (_isFieldVisible('Transport'))
                                          Row(
                                            children: [
                                              const Text(
                                                'Transport: ',
                                                style: TextStyle(fontSize: 14, color: Colors.grey),
                                              ),
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Text(
                                                    item["om_transport"] ?? 'No name',
                                                    style: const TextStyle(fontSize: 14),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_isFieldVisible('Agent'))
                                          Row(
                                            children: [
                                              const Text(
                                                'Agent: ',
                                                style: TextStyle(fontSize: 14, color: Colors.grey),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  item["AgentName"] ?? 'No name',
                                                  style: const TextStyle(fontSize: 14),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (_isFieldVisible('Quantity'))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Row(
                            children: [
                const Text("Qty: ", style: TextStyle(color: Colors.grey)),
                Text(
                  (item["om_qty"] ?? "N/A").toString(), // Convert to String
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                            ],
                          ),
                          const SizedBox(width: 5),
                          const Text('|', style: TextStyle(color: Colors.black)),
                          const SizedBox(width: 5),
                          if (_isFieldVisible('No of Item'))
                            Row(
                children: [
                  const Text("Item: ", style: TextStyle(color: Colors.grey)),
                  Text(
                    (item["om_noofitems"] ?? "N/A").toString(), // Convert to String
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                            ),
                        ],
                
                      ),
                      const SizedBox(height: 5), // Add spacing before the table
                
                      // Small table with three columns: Qty, Ref Qty, Pending Qty
                      Table(
                        border: TableBorder.all(color: Colors.grey), // Adds border to the table
                        columnWidths: const {
                          0: FlexColumnWidth(1), // First column (Qty)
                          1: FlexColumnWidth(1), // Second column (Ref Qty)
                          2: FlexColumnWidth(1), // Third column (Pending Qty)
                        },
                        children: [
                          // Table Header
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey[300]), // Header background
                            children: const [
                Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text("Qty", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text("Ref Qty", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text("Pending Qty", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                            ],
                          ),
                          // Table Data
                          TableRow(
                            children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text((item["om_qty"] ?? "N/A").toString(), textAlign: TextAlign.center), // Convert to String
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text((item["om_refqty"] ?? "N/A").toString(), textAlign: TextAlign.center), // Convert to String
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text((item["om_pendingqty"] ?? "N/A").toString(), textAlign: TextAlign.center), // Convert to String
                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                
                
                                        ],
                                      ),
                                    ),
                                    
                                    
                                    
                                    if (_isFieldVisible('Bill Amount'))
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.currency_rupee, color: Colors.red, size: 15),
                                            Text(
                                              (double.tryParse(item["om_billamt"] ?? '0.00') ?? 0.0) % 1 == 0
                                                  ? '${item["om_billamt"]?.split('.')[0]}'
                                                  : '₹ ${item["om_billamt"]}',
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                        // if (_isFieldVisible('Assignment'))
                                        // IconButton(
                                        //   onPressed: () async {
                                        //     final result = await Navigator.push(
                                        //       context,
                                        //       MaterialPageRoute(
                                        //         builder: (context) => ChallanNew(
                                        //           omid: item["om_id"]?.toString() ?? 'N/A',
                                        //           omdate: item["om_date"]?.toString() ?? 'N/A',
                                        //           custname: item["CustName"] ?? 'Unknown Customer',
                                        //           agent: item["AgentName"] ?? 'Unknown Agent',
                                        //           transport: item["om_transport"] ?? 'Unknown Transport',
                                        //           username: widget.username,
                                        //           clientcode: widget.clientcode,
                                        //           clientname: widget.clientname,
                                        //           clientMap: widget.clientMap,
                                        //           orders: (widget.orders ?? []).cast<Map<String, dynamic>>(),
                                        //           IdController: TextEditingController(text: item["om_id"]?.toString() ?? ''),
                                        //           ChallanIdController: TextEditingController(),
                                        //           DateController: TextEditingController(),
                                        //         ),
                                        //       ),
                                        //     );
                
                                        //     if (result == true) {
                                        //       setState(() {
                                        //         getRecord(); // Refresh data after returning
                                        //       });
                                        //     }
                                        //   },
                                        //   icon: const Icon(Icons.assignment, color: Colors.blue),
                                        //   tooltip: "Assignment",
                                        // ),
                                        Text(
                                                item["om_verify"] ??
                                                    'No name',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Colors.blue
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                        if (_isFieldVisible('Share'))
                                        IconButton(
                                          onPressed: () {
                                            final omId = item["om_id"];
                                            _generatePDF(omId);
                                          },
                                          icon: const Icon(Icons.share, color: Colors.deepPurple),
                                          tooltip: "Share",
                                        ),
                                      IconButton(
  onPressed: () {
    print("Item data: $item"); // Debug full item

    final omId = int.tryParse(item["om_id"].toString());
    final refQty = double.tryParse(item["om_refqty"].toString()) ?? 0.0;
    final pendingQty = double.tryParse(item["om_pendingqty"].toString()) ?? 0.0;
    final omVerify = int.tryParse(item["om_verify"].toString()) ?? 0.0;

    print("Order ID: $omId");
    print("Reference Quantity: $refQty"); // Debugging
    print("Pending Quantity: $pendingQty");

    if (omId != null) {
      if (refQty == 0.0 && omVerify==0) {
        print("Deleting order: $omId");
        deleteOrderData(omId).then((_) {
          setState(() {
            getRecord();
          });
        });
      } else {
        print("Cannot delete order");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cannot delete order")),
        );
      }
    } else {
      print('Error: Invalid Order ID');
    }
  },
  icon: const Icon(Icons.delete, color: Colors.red),
  tooltip: "Delete",
),




                                      ],
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
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
//        onPressed: () {
//   setState(() {
//     flag = 'new'; 
//   });
// // final omQty = item['om_qty'] ?? "0";
//                     final omVerify = ["om_verify"].toString();     
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => OrderNew(
//                 omid: ["om_id"].toString() ?? 'N/A',
//                 username: widget.username,
//                 clientcode: widget.clientcode,
//                 cmpcode:cmpcode,
//                 clientname: widget.clientname,
//                 clientMap: widget.clientMap,
//                 orders: widget.orders.cast<Map<String, dynamic>>(),
//                 IdController: TextEditingController(),
//                 DateController: TextEditingController(),

//                 flag: flag,
//                 omQty: (["om_qty"] ?? 0).toString(),
//                 omPendingQty: (["om_pendingqty"] ?? 0).toString(),
//                isApproveDisabled: (omVerify == '1' || omVerify.toLowerCase() == 'approved'), // Pass flag
//               ),
//             ),
            
//           );
          
//         },
onPressed: () async {
  //  _shouldRefresh = true;
  setState(() {
  flag = 'new'; 
 });
// // final omQty = item['om_qty'] ?? "0";
     final omVerify = ["om_verify"].toString();     
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OrderNew(
        omid: ["om_id"].toString() ?? 'N/A',
        username: widget.username,
        clientcode: widget.clientcode,
        cmpcode: cmpcode,
        
        clientname: widget.clientname,
        clientMap: widget.clientMap,
        orders: widget.orders.cast<Map<String, dynamic>>(),
        IdController: TextEditingController(),
        DateController: TextEditingController(),
        flag: 'new',
        omQty: (["om_qty"] ?? 0).toString(),
        omPendingQty: (["om_pendingqty"] ?? 0).toString(),
        isApproveDisabled: (omVerify == '1' || omVerify.toLowerCase() == 'approved'),
      ),
    ),
  );

  
      getRecord();
   
},
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
      
  );
}
}