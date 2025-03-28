import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'purchasechallan_transaction.dart';
import 'calendar_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PurchaseChallanMaster extends StatefulWidget {
  final String username; // Add username parameter
  final String clientcode;
  final String clientname;
  final String clientMap;
  const PurchaseChallanMaster(
      {super.key,
      required this.username,
      required this.clientcode,
      required this.clientname,
      required this.clientMap}); // Accept username in constructor

  @override
  State<PurchaseChallanMaster> createState() => PurchaseChallanMasterState();
}

class PurchaseChallanMasterState extends State<PurchaseChallanMaster> {
 List userData = [];
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
List<String> dropdownItems = ['--Select--', 'Challan List'];
String selectedItem = '--Select--';
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  @override
  void initState() {
    super.initState();
    getRecord();
    _fetchAgentNames();
    _fetchTransportNames();
    _fetchNames();
  }

  Future<void> getRecord() async {
    String uri =
        "${uriname}purchasechallan_master.php?clientcode=$clientcode&cmp=$cmpcode";

    try {
      var response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);

        // Ensure response data is not null
        setState(() {
          // Safely cast the response to a list of maps
          userData = jsonResponse.map((e) => e as Map<String, dynamic>).toList();

          // Ensure filteredData is also initialized properly
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
                              ListTile(
                              title: Row(
                                children: const [
                                  Text("Invoice"),
                                ],
                              ),
                              onTap: () {
                                setModalState(() => selectedFilter = "Invoice");
                              },
                            ),
                            const Divider(),
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
                            // ListTile(
                            //   title: Row(
                            //     children: const [
                            //       Text("City"),
                            //     ],
                            //   ),
                            //   onTap: () {
                            //     setModalState(() => selectedFilter = "City");
                            //   },
                            // ),
                            // const Divider(),
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
                              if (selectedFilter == "Invoice")
                              _buildInvoiceFilter(setModalState),
                              if (selectedFilter == "Agent")
                             _buildAgentFilter(setModalState),
                             if (selectedFilter == "Transport")
                             _buildTransportFilter(setModalState),
                            //  if (selectedFilter == "City")
                            // _buildCityFilter(setModalState),
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
        '${uriname}purchasechallan_master.php?clientcode=$clientcode&cmp=$cmpcode'));

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

  return SizedBox(
    height: 450, // Adjust height as needed
    child: SingleChildScrollView(
      child: Column(
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
                    DateTime? pickedStartDate =
                        await DatePicker.showSimpleDatePicker(
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
                    "Select Start Date: ${startDate != null ? startDate.toString().split(' ')[0] : 'Not Selected'}",
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedEndDate =
                        await DatePicker.showSimpleDatePicker(
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
                    "Select End Date: ${endDate != null ? endDate.toString().split(' ')[0] : 'Not Selected'}",
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
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
      final dateStr = item["IM_Date"];
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
Widget _buildInvoiceFilter(StateSetter setModalState) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: TextField(
      controller: invoiceController,
      decoration: const InputDecoration(
        labelText: "Enter Invoice Number",
        border: OutlineInputBorder(),
      ),
    ),
  );
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
        '${uriname}purchasechallan_master.php?clientcode=$clientcode&cmp=$cmpcode'));

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
        '${uriname}purchasechallan_master.php?clientcode=$clientcode&cmp=$cmpcode'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      if (data.isNotEmpty) {
        setState(() {
          // Extract 'AgentName', remove duplicates, and sort in ascending order
          transportNames = data
              .where((item) =>
                  item['IM_Transport'] != null && item['IM_Transport'].isNotEmpty)
              .map((item) => item['IM_Transport'] as String)
              .toSet()
              .toList();

          // Sort the agent names in ascending order
          transportNames.sort();

          // Ensure agentFilter is set to '--Select--' initially
          transportFilter = '--Select--'; 
          
          print('Fetched agent names: $transportNames');
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
        final dateStr = item["IM_Date"] ?? item["IM_LRDate"];
        DateTime? itemDate = parseDate(dateStr);
        if (itemDate != null) {
          return (itemDate.isAtSameMomentAs(startDate!) || itemDate.isAfter(startDate!)) &&
                 (itemDate.isAtSameMomentAs(endDate!) || itemDate.isBefore(endDate!));
        }
        return false;
      }).toList();
    }

    // Apply Invoice Filter if selectedFilter is "Invoice" and invoiceController.text is not empty
    if (selectedFilter == "Invoice" && invoiceController.text.isNotEmpty) {
      String gstValue = invoiceController.text.trim();
      filteredData = filteredData.where((item) {
        return item["IM_InvoiceNo"].toLowerCase().contains(gstValue.toLowerCase());
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
        return item["IM_Transport"] == transportFilter;
      }).toList();
    }

    // Log the results
    print("Filtered Data after applying filters: $filteredData");
  });
}

  Future<void> _sharePDF(String imid) async {
    final apiUrl =
        '${uriname}purchase_challan_pdf.php?clientcode=$clientcode&cmp=$cmpcode&IM_Id=$imid';

    try {
      // Fetching data from the API based on om_id
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Debugging the response
        print("Response Data: $data");

        if (data is List) {
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
                // final int totalqty = int.tryParse(data[0]['om_total_quantity'].toString()) ?? 0;
                final double billamt =
                    double.tryParse(data[0]['IM_BillAmt'].toString()) ?? 0.0;

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
                          'ORDER FORM',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
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
                          pw.VerticalDivider(),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text('Challan No: ${userData[0]['IM_InvoiceNo']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                          pw.Text('Date: ${userData[0]['IM_LRDate']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                      pw.Row(
                                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text('Cust Ref No: ${userData[0]['IM_CustRefNo']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                          pw.Text('Date: ${userData[0]['IM_CustRefDate']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                pw.Text('Agent Name: ${data[0]['AgentName']}', style: pw.TextStyle(fontSize: 10)),
                                pw.Text('Transport: ${data[0]['IM_Transport']}', style: pw.TextStyle(fontSize: 10)),
                                pw.Row(
                                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text('Payment Days: ${userData[0]['IM_PymtDays']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                          pw.Text('Delivery Days: ${userData[0]['']}',
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
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                'Item Name',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                'Pcs',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                'Mtrs',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                'Rate',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                'Total',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        pw.Divider(color: PdfColors.black),

                        // Item Rows
                        ...data.map((order) {
                          final int srNo =
                              int.tryParse(order['IT_SrNo'].toString()) ?? 0;
                          final String itemName = order['IM_ItemName'] ?? '';
                          final int pcs =
                              int.tryParse(order['IT_Pcs'].toString()) ?? 0;
                          final double mtrs =
                              double.tryParse(order['IT_Mtrs'].toString()) ??
                                  0.0;
                          final double rate =
                              double.tryParse(order['IT_Rate'].toString()) ??
                                  0.0;
                          final double subtotal = double.tryParse(
                                  order['IT_SubTotal'].toString()) ??
                              0.0;

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
                                  pcs.toString(),
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Text(
                                  mtrs.toStringAsFixed(2),
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
                                  subtotal.toStringAsFixed(2),
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
                            pw.Expanded(
                                flex: 1, child: pw.Text('')), // Empty space
                            pw.Expanded(
                                flex: 3,
                                child: pw.Text('Total',
                                    style: pw.TextStyle(
                                        fontSize: 12,
                                        fontWeight: pw
                                            .FontWeight.bold))), // 'Total' text
                            pw.Expanded(
                                flex: 1, child: pw.Text('')), // Total quantity
                            pw.Expanded(
                                flex: 1, child: pw.Text('')), // Empty space
                            pw.Expanded(
                                flex: 1, child: pw.Text('')), // Empty space
                            pw.Expanded(
                                flex: 1,
                                child: pw.Text(billamt.toStringAsFixed(2),
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                        fontSize:
                                            10))), // Total amount (same as rate)
                          ],
                        ),

                        pw.Divider(color: PdfColors.black),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                    'Payment Terms: Payment within 30 days.'),
                                pw.Text(
                                    'Delivery Terms: Delivery within 0 days.'),
                                pw.Text(
                                    'No guarantee for color, zari & material.'),
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
          final file = File('${directory.path}/Purchase Challan.pdf');
          await file.writeAsBytes(await pdf.save());

          // Share the PDF file
          await Share.shareFiles([file.path], text: 'Purchase Challan PDF');
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

Future<void> _generatePDF(String imid) async {
  final apiUrl =
      '${uriname}purchase_challan_pdf.php?clientcode=$clientcode&cmp=$cmpcode&IM_Id=$imid';

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Response Data: $data");

      if (data is List) {
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
              final double billamt = double.tryParse(data[0]['IM_BillAmt'].toString()) ?? 0.0;

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
                      pw.Text('Exclusive Dress Materials', style: pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 10),
                      pw.Text('E-25, Ground Floor, Sumel Business Park-1 (Safal),', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('B/h. New Cloth Market, Sarangpur, Ahmedabad-1.', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('Ph. No.: 079 22191185 Mo: 09998260490, 08980072422, 9913910663', style: pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 10),
                      pw.Text('GSTIN: 24ADGPP7174D1ZJ        MSME No: UDYAM-GJ-01-00000', style: pw.TextStyle(fontSize: 10)),
                      pw.Divider(),
                      pw.Text(
                        'ORDER FORM',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                        ),
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
                          pw.VerticalDivider(),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text('Challan No: ${userData[0]['IM_InvoiceNo']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                          pw.Text('Date: ${userData[0]['IM_LRDate']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                      pw.Row(
                                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text('Cust Ref No: ${userData[0]['IM_CustRefNo']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                          pw.Text('Date: ${userData[0]['IM_CustRefDate']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                pw.Text('Agent Name: ${data[0]['AgentName']}', style: pw.TextStyle(fontSize: 10)),
                                pw.Text('Transport: ${data[0]['IM_Transport']}', style: pw.TextStyle(fontSize: 10)),
                                pw.Row(
                                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text('Payment Days: ${userData[0]['IM_PymtDays']}',
                                              style: pw.TextStyle(fontSize: 10)),
                                          pw.Text('Delivery Days: ${userData[0]['']}',
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
                          pw.Expanded(flex: 1, child: pw.Text('Sr No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Expanded(flex: 3, child: pw.Text('Item Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Expanded(flex: 1, child: pw.Text('Pcs', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Expanded(flex: 1, child: pw.Text('Mtrs', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Expanded(flex: 1, child: pw.Text('Rate', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Expanded(flex: 1, child: pw.Text('Total', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                      pw.Divider(color: PdfColors.black),

                      // Item Rows
                      ...data.map((order) {
                        final int srNo = int.tryParse(order['IT_SrNo'].toString()) ?? 0;
                        final String itemName = order['IM_ItemName'] ?? '';
                        final int pcs = int.tryParse(order['IT_Pcs'].toString()) ?? 0;
                        final double mtrs = double.tryParse(order['IT_Mtrs'].toString()) ?? 0.0;
                        final double rate = double.tryParse(order['IT_Rate'].toString()) ?? 0.0;
                        final double subtotal = double.tryParse(order['IT_SubTotal'].toString()) ?? 0.0;

                        return pw.Row(
                          children: [
                            pw.Expanded(flex: 1, child: pw.Text(srNo.toString(), style: pw.TextStyle(fontSize: 10))),
                            pw.Expanded(flex: 3, child: pw.Text(itemName, style: pw.TextStyle(fontSize: 10))),
                            pw.Expanded(flex: 1, child: pw.Text(pcs.toString(), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10))),
                            pw.Expanded(flex: 1, child: pw.Text(mtrs.toStringAsFixed(2), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10))),
                            pw.Expanded(flex: 1, child: pw.Text(rate.toStringAsFixed(2), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10))),
                            pw.Expanded(flex: 1, child: pw.Text(subtotal.toStringAsFixed(2), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10))),
                          ],
                        );
                      }),

                      pw.Divider(color: PdfColors.black),

                      // Row for displaying totals
                      pw.Row(
                        children: [
                          pw.Expanded(flex: 1, child: pw.Text('')), // Empty space
                          pw.Expanded(flex: 3, child: pw.Text('Total', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
                          pw.Expanded(flex: 1, child: pw.Text('')), // Empty space
                          pw.Expanded(flex: 1, child: pw.Text('')), // Empty space
                          pw.Expanded(flex: 1, child: pw.Text(billamt.toStringAsFixed(2), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10))),
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

String _extractDay(String? date) {
  if (date == null || date.isEmpty) return "N/A";
  try {
    DateTime parsedDate = DateFormat("dd-MM-yyyy").parse(date);
    return parsedDate.day.toString().padLeft(2, '0'); // Ensures 2-digit format
  } catch (e) {
    return "N/A";
  }
}

String _extractMonth(String? date) {
  if (date == null || date.isEmpty) return "N/A";
  try {
    DateTime parsedDate = DateFormat("dd-MM-yyyy").parse(date);
    return DateFormat.MMM().format(parsedDate); // Converts month to short name (e.g., "Apr")
  } catch (e) {
    return "N/A";
  }
}

String _extractYear(String? date) {
  if (date == null || date.isEmpty) return "N/A";
  try {
    DateTime parsedDate = DateFormat("dd-MM-yyyy").parse(date);
    return parsedDate.year.toString();
  } catch (e) {
    return "N/A";
  }
}


Future<void> challanList() async {
  final apiUrl =
      '${uriname}purchasechallan_master.php?clientcode=$clientcode&cmp=$cmpcode';

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Response Data: $data");

      if (data is List) {
        final pdf = pw.Document();
        const int itemsPerPage = 20; // Items per page
        final totalPages = (data.length / itemsPerPage).ceil(); // Total pages
        final totalBillAmount = data.fold<double>(
          0.0,
          (sum, item) => sum + (double.tryParse(item["IM_BillAmt"] ?? '0') ?? 0.0),
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
                            pw.Text('Supplier', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
                              pw.Text(pageData[i]["IM_InvoiceNo"] ?? "N/A"),
                              pw.Text(pageData[i]["IM_Date"] ?? "N/A"),
                              pw.Text(pageData[i]["CustName"] ?? "N/A"),
                              pw.Text(pageData[i]["CustCity"] ?? "N/A"),
                              pw.Text(pageData[i]["AgentName"] ?? "N/A"),
                              pw.Text(
                                '${pageData[i]["IM_BillAmt"] ?? "0.0"}',
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
Widget buildCalendarWidget(String? date) {
  DateTime? parsedDate;
  if (date != null && date.isNotEmpty) {
    try {
      parsedDate = DateFormat("dd-MM-yyyy").parse(date);
    } catch (e) {
      parsedDate = null;
    }
  }

  if (parsedDate == null) {
    return Text(
      "N/A",
      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
    );
  }

  String month = DateFormat.MMM().format(parsedDate); // Month (Apr)
  String day = parsedDate.day.toString(); // Day (01)
  String year = parsedDate.year.toString(); // Year (2024)

  return Container(
    width: 55,
    height: 98, // Reduced width for compact look
    padding: EdgeInsets.all(5), // Reduced padding
    decoration: BoxDecoration(
      color: Colors.white, // Background color
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.grey.shade400, width: 0.8), // Thinner border
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05), // Lighter shadow
          blurRadius: 3,
          spreadRadius: 1,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 📌 Mini Header with Month
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: Colors.blue, // Header background
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Text(
            month, // Display Month (e.g., Apr)
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12, // Smaller font
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        SizedBox(height: 1),

        // 📌 Mini Circular Date
        Container(
          width: 45, // Rectangle width
          height: 29, // Rectangle height
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 226, 60, 60), // Highlight color
            // borderRadius: BorderRadius.circular(4), // Slightly rounded corners
          ),
          child: Text(
            day, // Display Day (01)
            style: TextStyle(
              color: Colors.white,
              fontSize: 18, // Readable font size
              fontWeight: FontWeight.bold,
            ),
          ),
        ),


        SizedBox(height: 1),

        // 📌 Year
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: Colors.blue, // Header background
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
          ),
          child: Text(
            year, // Display Month (e.g., Apr)
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12, // Smaller font
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('Purchase Challan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () {
              _showFilterOptions(context); // Trigger the filter dialog
            },
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
                  if (selectedItem == "Challan List") {
                    challanList();
                  } 
                },
              ),
            ],
          ),
          Expanded(
            child: filteredData.isEmpty
                ? Center(
                    child: Text(
                      'No Data found',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.builder(
                  
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final item =
                          filteredData[index]; // Access the map directly here
                          print("IM_Date: ${item["IM_Date"]}");

                          // Define colors based on index
                      // Color cardColor;
                      // if (index % 4 == 0) {
                      //   cardColor = Colors.red.shade100; // Light Red
                      // } else if (index % 4 == 1) {
                      //   cardColor = Colors.yellow.shade100; // Light Yellow
                      // } else if (index % 4 == 2) {
                      //   cardColor = Colors.blue.shade100; // Light Blue
                      // } else {
                      //   cardColor = Colors.orange.shade100; // Light Orange
                      // }
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PurchaseChallanTransaction(
                                itid: item["IM_Id"], // Access the keys directly
                                invoice: item["IM_InvoiceNo"],
                                username: widget.username,
                                clientcode: widget.clientcode,
                                clientname: widget.clientname,
                                clientMap: widget.clientMap,
                                item:item,
                              ),
                            ),
                          );
                        },
                        child: Card(
  margin: const EdgeInsets.only(top: 2, left: 10, right: 5),
  child: Padding(
    padding: const EdgeInsets.all(10.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First Column: Date
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCalendarWidget(item["IM_Date"]),
          ],
        ),
        const SizedBox(width: 10), // Space between columns

        // Second Column: Invoice No, Customer Name, Transport, Agent
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice No
              
            Text.rich(
  TextSpan(
    children: [
      TextSpan(
        text: 'Challan No: ',
        style: const TextStyle(fontSize: 14, color: Colors.grey), // Label style
      ),
      TextSpan(
        text: item["IM_InvoiceNo"] ?? "N/A",
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black), // Value style
      ),
    ],
  ),
),

              const SizedBox(height: 5),

              // Customer Name
              Tooltip(
                message:item['CustName'] ?? 'No name',
              child: Text(
                item["CustName"] ?? 'No name',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              ),
              const SizedBox(height: 5),

              // Transport
              Row(
                children: [
                  const Text(
                    'Transport: ',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Expanded(
                    child: Tooltip(
  message: item["IM_Transport"] ?? 'No name', // Full text on hover/tap
  child: Text(
    item["IM_Transport"] ?? 'No name',
    style: const TextStyle(fontSize: 14),
    overflow: TextOverflow.ellipsis,
  ),
),

                  ),
                ],
              ),

              // Agent
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
            ],
          ),
        ),

        // Third Column: Bill Amount, Share, Print
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bill Amount
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.currency_rupee, color: Colors.red, size: 15),
                Text(
                  (double.tryParse(item["IM_BillAmt"] ?? '0.00') ?? 0.0) % 1 == 0
                      ? '${item["IM_BillAmt"]?.split('.')[0]}'
                      : '₹ ${item["IM_BillAmt"]}',
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Share Icon
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                _sharePDF(item["IM_Id"]);
              },
            ),

            // Print Icon
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                _generatePDF(item["IM_Id"]);
              },
            ),
          ],
        ),
      ],
    ),
  ),
)

                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
