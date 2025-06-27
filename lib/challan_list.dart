// import 'package:flutter/material.dart';
// import 'globals.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
// import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
// import 'order_new.dart';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:share_plus/share_plus.dart';
// import 'package:pdf/pdf.dart';
// import 'challan_Edit.dart';
// import 'challan_new.dart';

// class ChallanList extends StatefulWidget {
//   final String username; // Add username parameter
//   final String clientcode;
//   final String clientname;
//   final String clientMap;
//   final List<Map<String, dynamic>> orders;
//   const ChallanList(
//       {super.key,
//       required this.username,
//       required this.clientcode,
//       required this.clientname,
//       required this.clientMap,
//       required this.orders}); // Accept username in constructor

//   @override
//   State<ChallanList> createState() => ChallanListState();
// }

// class ChallanListState extends State<ChallanList> {
//   List Data = [];
//   String flag = '';
//   Map<String, String> appliedFilters = {};
//   DateTime? startDate;
//   DateTime? endDate;
//   String? selectedCity;
//   String? _selectedFilter;
//   String? _selectedDateRange;
//   final TextEditingController _cityController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     getRecord();
//   }

//   Future<void> getRecord(
//       {DateTime? startDate, DateTime? endDate, String? selectedCity}) async {
//     String uri =
//         "${uriname}challan_list.php?clientcode=$clientcode&cmp=$cmpcode";
//     if (startDate != null && endDate != null) {
//       String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
//       String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);
//       uri += "&fromdate=$formattedStartDate&todate=$formattedEndDate";
//     }
//     if (selectedCity != null && selectedCity.isNotEmpty) {
//       uri += "&city=${Uri.encodeComponent(selectedCity)}";
//     }
//     print("Request URI: $uri");
//     try {
//       var response = await http.get(Uri.parse(uri));
//       if (response.statusCode == 200) {
//         var jsonResponse = jsonDecode(response.body);
//         if (jsonResponse is List) {
//           setState(() {
//             Data = jsonResponse;
//           });
//         } else {
//           print('Unexpected response format');
//         }
//       } else {
//         print('Request failed with status: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Request error: $e');
//     }
//   }

//   void _showFilterOptions(BuildContext context) {
//     // Set defaults when the modal is opened
//     _selectedFilter = "Date";
//     _selectedDateRange =
//         _selectedDateRange ?? 'This Year'; // Default to 'This Year'
//     _setDateRange(_selectedDateRange!); // Apply default date range on opening

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setModalState) {
//             return SizedBox(
//               height: MediaQuery.of(context).size.height * 0.8,
//               child: Row(
//                 children: [
//                   Container(
//                     color: Colors.grey[300],
//                     width: MediaQuery.of(context).size.width * 0.3,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         ListTile(
//                           title: Row(
//                             children: [
//                               const Text("Date"),
//                               if (appliedFilters["Date"] != null)
//                                 const Padding(
//                                   padding: EdgeInsets.only(left: 8.0),
//                                   child: CircleAvatar(
//                                     radius: 4,
//                                     backgroundColor: Colors.orange,
//                                   ),
//                                 ),
//                             ],
//                           ),
//                           onTap: () {
//                             setModalState(() => _selectedFilter = "Date");
//                           },
//                         ),
//                         const Divider(),
//                         ListTile(
//                           title: Row(
//                             children: [
//                               const Text("City"),
//                               if (appliedFilters["City"] != null)
//                                 const Padding(
//                                   padding: EdgeInsets.only(left: 8.0),
//                                   child: CircleAvatar(
//                                     radius: 4,
//                                     backgroundColor: Colors.orange,
//                                   ),
//                                 ),
//                             ],
//                           ),
//                           onTap: () {
//                             setModalState(() => _selectedFilter = "City");
//                           },
//                         ),
//                         const Divider(),
//                       ],
//                     ),
//                   ),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Text(
//                             _selectedFilter ?? "Select Filter",
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         if (_selectedFilter == "Date")
//                           _buildDateFilter(setModalState),
//                         if (_selectedFilter == "City")
//                           _buildCityFilter(setModalState),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     ).then((_) {
//       _showAppliedFiltersMessage(context);
//       getRecord(
//         startDate: startDate,
//         endDate: endDate,
//         selectedCity: selectedCity,
//       ); // Fetch data after filters are applied
//     });
//   }

//   Widget _buildDateFilter(StateSetter setModalState) {
//     final dateOptions = [
//       'This Year',
//       'This Month',
//       'Last Month',
//       'This Week',
//       'Yesterday',
//       'Today',
//       'Custom Date Range',
//     ];

//     return Column(
//       children: [
//         for (var option in dateOptions)
//           RadioListTile<String>(
//             title: Text(option),
//             value: option,
//             groupValue: _selectedDateRange,
//             onChanged: (value) {
//               setModalState(() {
//                 _selectedDateRange = value;
//                 _setDateRange(value!); // Apply the selected date range
//                 appliedFilters["Date"] = value; // Mark filter as applied
//               });
//             },
//           ),
//         if (_selectedDateRange == 'Custom Date Range')
//           Column(
//             children: [
//               ElevatedButton(
//                 onPressed: () async {
//                   DateTime? pickedStartDate =
//                       await DatePicker.showSimpleDatePicker(
//                     context,
//                     initialDate: DateTime.now(),
//                     firstDate: DateTime(2000),
//                     lastDate: DateTime.now(),
//                     dateFormat: "yyyy-MM-dd",
//                     titleText: "Select Start Date",
//                     locale: DateTimePickerLocale.en_us,
//                   );
//                   if (pickedStartDate != null) {
//                     setModalState(() {
//                       startDate = pickedStartDate;
//                     });
//                   }
//                 },
//                 child: Text(
//                     "Select Start Date: ${startDate != null ? startDate.toString().split(' ')[0] : 'Not Selected'}"),
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   DateTime? pickedEndDate =
//                       await DatePicker.showSimpleDatePicker(
//                     context,
//                     initialDate: DateTime.now(),
//                     firstDate: startDate ?? DateTime(2000),
//                     lastDate: DateTime.now(),
//                     dateFormat: "yyyy-MM-dd",
//                     titleText: "Select End Date",
//                     locale: DateTimePickerLocale.en_us,
//                   );
//                   if (pickedEndDate != null) {
//                     setModalState(() {
//                       endDate = pickedEndDate;
//                     });
//                   }
//                 },
//                 child: Text(
//                     "Select End Date: ${endDate != null ? endDate.toString().split(' ')[0] : 'Not Selected'}"),
//               ),
//             ],
//           ),
//         ElevatedButton(
//           onPressed: () {
//             Navigator.pop(context);
//             getRecord(
//                 startDate: startDate,
//                 endDate: endDate,
//                 selectedCity: selectedCity); // Apply the selected date filter
//           },
//           child: const Text("Apply"),
//         ),
//       ],
//     );
//   }

//   void _setDateRange(String option) {
//     DateTime now = DateTime.now();
//     switch (option) {
//       case 'This Year':
//         startDate = DateTime(now.year, 1, 1);
//         endDate = DateTime(now.year, 12, 31);
//         break;
//       case 'This Month':
//         startDate = DateTime(now.year, now.month, 1);
//         endDate = DateTime(now.year, now.month + 1, 0);
//         break;
//       case 'Last Month':
//         startDate = DateTime(now.year, now.month - 1, 1);
//         endDate = DateTime(now.year, now.month, 0);
//         break;
//       case 'This Week':
//         startDate = now.subtract(Duration(days: now.weekday - 1));
//         endDate = startDate!.add(const Duration(days: 6));
//         break;
//       case 'Yesterday':
//         startDate = now.subtract(const Duration(days: 1));
//         endDate = startDate;
//         break;
//       case 'Today':
//         startDate = now;
//         endDate = now;
//         break;
//     }
//   }

//   Widget _buildCityFilter(StateSetter setModalState) {
//     return Column(
//       children: [
//         TextField(
//           controller: _cityController,
//           decoration: const InputDecoration(labelText: "Enter City"),
//           onChanged: (value) {
//             // Optionally update the state within the modal as the user types
//             setModalState(() {
//               selectedCity = value;
//             });
//           },
//         ),
//         ElevatedButton(
//           onPressed: () {
//             setModalState(() {
//               selectedCity = _cityController.text;
//               appliedFilters["City"] = selectedCity ?? '';
//             });
//             Navigator.pop(context);
//             getRecord(
//                 startDate: startDate,
//                 endDate: endDate,
//                 selectedCity: selectedCity); // Apply the city filter
//           },
//           child: const Text("Apply"),
//         ),
//       ],
//     );
//   }

//   void _showAppliedFiltersMessage(BuildContext context) {
//     String appliedFiltersText = appliedFilters.entries
//         .map((entry) {
//           if (entry.key == "Date" && _selectedDateRange != null) {
//             if (startDate != null && endDate != null) {
//               return "${entry.key}: ${_formatDate(startDate!)} to ${_formatDate(endDate!)}";
//             } else {
//               return "${entry.key}: $_selectedDateRange";
//             }
//           } else if (entry.key == "City") {
//             return "${entry.key}: ${entry.value}";
//           }
//           return "";
//         })
//         .where((text) => text.isNotEmpty)
//         .join(", ");

//     if (appliedFiltersText.isEmpty) {
//       appliedFiltersText = "No filters applied";
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("Filters Applied: $appliedFiltersText"),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return DateFormat('yyyy-MM-dd').format(date);
//   }

//   Future<void> _generatePDF(String omId) async {
//     final apiUrl =
//         '${uriname}order_formate_pdf.php?clientcode=$clientcode&cmp=$cmpcode&om_id=$omId';

//     try {
//       // Fetching data from the API based on om_id
//       final response = await http.get(Uri.parse(apiUrl));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);

//         // Debugging the response
//         print("Response Data: $data");

//         if (data is List) {
//           // Initialize PDF document
//           final pdf = pw.Document();

//           pdf.addPage(
//             pw.Page(
//               pageFormat: PdfPageFormat.a4.copyWith(
//                 marginTop: 20, // Adjust top margin
//                 marginLeft: 20, // Adjust left margin
//                 marginRight: 20, // Adjust right margin
//                 marginBottom: 20, // Adjust bottom margin
//               ),
//               build: (pw.Context context) {
//                 final int totalqty =
//                     int.tryParse(data[0]['om_total_quantity'].toString()) ?? 0;
//                 final double totalrate =
//                     double.tryParse(data[0]['om_amt'].toString()) ?? 0.0;

//                 return pw.Center(
//                   child: pw.Container(
//                     padding: const pw.EdgeInsets.all(10),
//                     decoration: pw.BoxDecoration(
//                       border: pw.Border.all(
//                         color: PdfColors.black,
//                         width: 3,
//                       ),
//                       borderRadius: pw.BorderRadius.all(pw.Radius.circular(20)),
//                     ),
//                     child: pw.Column(
//                       crossAxisAlignment: pw.CrossAxisAlignment.center,
//                       children: [
//                         pw.Text(
//                           widget.clientname,
//                           style: pw.TextStyle(
//                             fontSize: 18,
//                             fontWeight: pw.FontWeight.bold,
//                           ),
//                         ),
//                         pw.Text('Exclusive Dress Materials',
//                             style: pw.TextStyle(fontSize: 10)),
//                         pw.SizedBox(height: 10),
//                         pw.Text(
//                             'E-25, Ground Floor, Sumel Business Park-1 (Safal),',
//                             style: pw.TextStyle(fontSize: 10)),
//                         pw.Text(
//                             'B/h. New Cloth Market, Sarangpur, Ahmedabad-1.',
//                             style: pw.TextStyle(fontSize: 10)),
//                         pw.Text(
//                             'Ph. No.: 079 22191185 Mo: 09998260490, 08980072422, 9913910663',
//                             style: pw.TextStyle(fontSize: 10)),
//                         pw.SizedBox(height: 10),
//                         pw.Text(
//                             'GSTIN: 24ADGPP7174D1ZJ        MSME No: UDYAM-GJ-01-00000',
//                             style: pw.TextStyle(fontSize: 10)),
//                         pw.Divider(),
//                         pw.Text(
//                           'ORDER FORM',
//                           style: pw.TextStyle(
//                             fontWeight: pw.FontWeight.bold,
//                           ),
//                         ),
//                         pw.Divider(),

//                         // Row with two columns (expanded for equal space)
//                         pw.Row(
//                           mainAxisAlignment: pw.MainAxisAlignment.start,
//                           children: [
//                             pw.Expanded(
//                               child: pw.Column(
//                                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                                 children: [
//                                   pw.Text('Customer: ${data[0]['CustName']}',
//                                       style: pw.TextStyle(fontSize: 10)),
//                                   pw.Text(
//                                       'Address: 4158, NAI SARAK, DELHI, 110006, Delhi',
//                                       style: pw.TextStyle(fontSize: 10)),
//                                 ],
//                               ),
//                             ),
//                             pw.VerticalDivider(),
//                             pw.Expanded(
//                               child: pw.Column(
//                                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                                 children: [
//                                   pw.Text('Order No: ${data[0]['om_no']}',
//                                       style: pw.TextStyle(fontSize: 10)),
//                                   pw.Text('Order Date: ${data[0]['om_date']}',
//                                       style: pw.TextStyle(fontSize: 10)),
//                                   pw.Text(
//                                       'Customer Ref No: ${data[0]['custrefno']}',
//                                       style: pw.TextStyle(fontSize: 10)),
//                                   pw.Text('Agent Name: ${data[0]['AgentName']}',
//                                       style: pw.TextStyle(fontSize: 10)),
//                                   pw.Text(
//                                       'Transport: ${data[0]['om_transport']}',
//                                       style: pw.TextStyle(fontSize: 10)),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),

//                         pw.Divider(color: PdfColors.black),
//                         // Item Details Header
//                         pw.Row(
//                           children: [
//                             pw.Expanded(
//                               flex: 1,
//                               child: pw.Text(
//                                 'Sr No',
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold),
//                               ),
//                             ),
//                             pw.Expanded(
//                               flex: 3,
//                               child: pw.Text(
//                                 'Item Name',
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold),
//                               ),
//                             ),
//                             pw.Expanded(
//                               flex: 1,
//                               child: pw.Text(
//                                 'Qty',
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold),
//                                 textAlign: pw.TextAlign.center,
//                               ),
//                             ),
//                             pw.Expanded(
//                               flex: 1,
//                               child: pw.Text(
//                                 'Unit',
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold),
//                                 textAlign: pw.TextAlign.center,
//                               ),
//                             ),
//                             pw.Expanded(
//                               flex: 1,
//                               child: pw.Text(
//                                 'Rate',
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold),
//                                 textAlign: pw.TextAlign.center,
//                               ),
//                             ),
//                             pw.Expanded(
//                               flex: 1,
//                               child: pw.Text(
//                                 'Total',
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold),
//                                 textAlign: pw.TextAlign.center,
//                               ),
//                             ),
//                           ],
//                         ),
//                         pw.Divider(color: PdfColors.black),

//                         // Item Rows
//                         ...data.map((order) {
//                           final int srNo =
//                               int.tryParse(order['ot_srno'].toString()) ?? 0;
//                           final String itemName = order['IM_ItemName'] ?? '';
//                           final int qty =
//                               int.tryParse(order['ot_qty'].toString()) ?? 0;
//                           final double rate =
//                               double.tryParse(order['ot_rate'].toString()) ??
//                                   0.0;
//                           final double total = qty * rate;

//                           return pw.Row(
//                             children: [
//                               pw.Expanded(
//                                 flex: 1,
//                                 child: pw.Text(srNo.toString(),
//                                     style: pw.TextStyle(fontSize: 10)),
//                               ),
//                               pw.Expanded(
//                                 flex: 3,
//                                 child: pw.Text(itemName,
//                                     style: pw.TextStyle(fontSize: 10)),
//                               ),
//                               pw.Expanded(
//                                 flex: 1,
//                                 child: pw.Text(
//                                   qty.toString(),
//                                   textAlign: pw.TextAlign.center,
//                                   style: pw.TextStyle(fontSize: 10),
//                                 ),
//                               ),
//                               pw.Expanded(
//                                 flex: 1,
//                                 child: pw.Text(
//                                   'pcs', // Default unit
//                                   textAlign: pw.TextAlign.center,
//                                   style: pw.TextStyle(fontSize: 10),
//                                 ),
//                               ),
//                               pw.Expanded(
//                                 flex: 1,
//                                 child: pw.Text(
//                                   rate.toStringAsFixed(2),
//                                   textAlign: pw.TextAlign.center,
//                                   style: pw.TextStyle(fontSize: 10),
//                                 ),
//                               ),
//                               pw.Expanded(
//                                 flex: 1,
//                                 child: pw.Text(
//                                   total.toStringAsFixed(2),
//                                   textAlign: pw.TextAlign.center,
//                                   style: pw.TextStyle(fontSize: 10),
//                                 ),
//                               ),
//                             ],
//                           );
//                         }),

//                         // Divider before totals
//                         pw.Divider(color: PdfColors.black),

//                         // Row for displaying totals
//                         pw.Row(
//                           children: [
//                             pw.Expanded(
//                                 flex: 1, child: pw.Text('')), // Empty space
//                             pw.Expanded(
//                                 flex: 3,
//                                 child: pw.Text('Total',
//                                     style: pw.TextStyle(
//                                         fontSize: 12,
//                                         fontWeight: pw
//                                             .FontWeight.bold))), // 'Total' text
//                             pw.Expanded(
//                                 flex: 1,
//                                 child: pw.Text(totalqty.toString(),
//                                     textAlign: pw.TextAlign.center,
//                                     style: pw.TextStyle(
//                                         fontSize: 10))), // Total quantity
//                             pw.Expanded(
//                                 flex: 1, child: pw.Text('')), // Empty space
//                             pw.Expanded(
//                                 flex: 1, child: pw.Text('')), // Empty space
//                             pw.Expanded(
//                                 flex: 1,
//                                 child: pw.Text(totalrate.toStringAsFixed(2),
//                                     textAlign: pw.TextAlign.center,
//                                     style: pw.TextStyle(
//                                         fontSize:
//                                             10))), // Total amount (same as rate)
//                           ],
//                         ),

//                         pw.Divider(color: PdfColors.black),
//                         pw.Row(
//                           mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                           children: [
//                             pw.Column(
//                               crossAxisAlignment: pw.CrossAxisAlignment.start,
//                               children: [
//                                 pw.Text(
//                                     'Payment Terms: Payment within 30 days.'),
//                                 pw.Text(
//                                     'Delivery Terms: Delivery within 0 days.'),
//                                 pw.Text(
//                                     'No guarantee for color, zari & material.'),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           );

//           // Save PDF to a file
//           final directory = await getApplicationDocumentsDirectory();
//           final file = File('${directory.path}/order_formate.pdf');
//           await file.writeAsBytes(await pdf.save());

//           // Share the PDF file
//           await Share.shareFiles([file.path], text: 'Order Formate PDF');
//         } else {
//           throw Exception('Unexpected data format');
//         }
//       } else {
//         throw Exception('Failed to load data');
//       }
//     } catch (e) {
//       print('Error fetching or generating PDF: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.orange,
//         title: const Text('Challan'),
//       ),
//       body: Container(
//         color: Colors.grey[200], // Background color for the body
//         padding: const EdgeInsets.symmetric(vertical: 8.0),
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(vertical: 8.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   const Column(
//                     children: [
//                       Icon(Icons.person, color: Colors.orange),
//                       Text(
//                         "A",
//                         style: TextStyle(
//                             fontSize: 12, fontWeight: FontWeight.w500),
//                       ),
//                     ],
//                   ),
//                   const Column(
//                     children: [
//                       Icon(Icons.account_balance, color: Colors.orange),
//                       Text(
//                         "B",
//                         style: TextStyle(
//                             fontSize: 12, fontWeight: FontWeight.w500),
//                       ),
//                     ],
//                   ),
//                   const Column(
//                     children: [
//                       Icon(Icons.location_city, color: Colors.orange),
//                       Text(
//                         "C",
//                         style: TextStyle(
//                             fontSize: 12, fontWeight: FontWeight.w500),
//                       ),
//                     ],
//                   ),
//                   InkWell(
//                     onTap: () {
//                       _showFilterOptions(context);
//                     },
//                     child: const Column(
//                       children: [
//                         Icon(Icons.filter_list, color: Colors.orange),
//                         Text("Filters",
//                             style: TextStyle(
//                                 fontSize: 12, fontWeight: FontWeight.w500)),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Data.isEmpty
//                   ? const Center(
//                       child: Text('No Data Found',
//                           style: TextStyle(
//                               fontSize: 20, fontWeight: FontWeight.bold)),
//                     )
//                   : ListView.builder(
//                       itemCount: Data.length,
//                       itemBuilder: (context, index) {
//                         return InkWell(
//   onTap: () async {
//     final result = await Navigator.push(
//       context,
//      MaterialPageRoute(
//     builder: (context) => ChallanEdit(
//       omid: Data[index]["om_id"]?.toString() ?? 'N/A', // Default if null
//       omdate: Data[index]["om_date"]?.toString() ?? 'N/A',
//       custname: Data[index]["CustName"] ?? 'Unknown Customer',
//       agent: Data[index]["AgentName"] ?? 'Unknown Agent',
//       transport: Data[index]["om_transport"] ?? 'Unknown Transport',
//       username: widget.username,
//       clientcode: widget.clientcode,
//       clientname: widget.clientname,
//       clientMap: widget.clientMap,
//       orders: (widget.orders ?? []).cast<Map<String, dynamic>>(),
//       IdController: TextEditingController(
//           text: Data[index]["om_invno"]?.toString() ?? ''),
//       DateController: TextEditingController(
//           text: Data[index]["om_date"]?.toString() ?? ''),
//            ChallanIdController:TextEditingController(),
                                                
//                                 ),
//                               ),
//                             );

//                             if (result == true) {
//                               setState(() {
//                                 getRecord(); // Refresh data after returning
//                               });
//                             }
//                           },
//                           child: Card(
//                             margin: const EdgeInsets.only(
//                                 top: 2, left: 10, right: 5),
//                             child: Padding(
//                               padding: const EdgeInsets.all(10.0),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Row(
//                                               children: [
//                                                 Text(
//                                                   Data[index]["om_invno"] ??
//                                                       "N/A",
//                                                   style: const TextStyle(
//                                                       fontWeight:
//                                                           FontWeight.bold),
//                                                 ),
//                                                 const SizedBox(width: 5),
//                                                 const Text('|',
//                                                     style: TextStyle(
//                                                         color: Colors.black)),
//                                                 const SizedBox(width: 5),
//                                                 Text(Data[index]["om_date"] ??
//                                                     "N/A"),
//                                               ],
//                                             ),
//                                             Text(
//                                               Data[index]["CustName"] ??
//                                                   'No name',
//                                               style: const TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                                 fontSize: 16,
//                                               ),
//                                               overflow: TextOverflow.ellipsis,
//                                             ),
//                                             Row(
//                                               children: [
//                                                 const Text(
//                                                   'Transport: ',
//                                                   style: TextStyle(
//                                                       fontSize: 14,
//                                                       color: Colors.grey),
//                                                 ),
//                                                 Expanded(
//                                                   child: SingleChildScrollView(
//                                                     scrollDirection:
//                                                         Axis.horizontal,
//                                                     child: Text(
//                                                       Data[index][
//                                                               "om_transport"] ??
//                                                           'No name',
//                                                       style: const TextStyle(
//                                                           fontSize: 14),
//                                                       overflow:
//                                                           TextOverflow.ellipsis,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             Row(
//                                               children: [
//                                                 const Text(
//                                                   'Agent: ',
//                                                   style: TextStyle(
//                                                       fontSize: 14,
//                                                       color: Colors.grey),
//                                                 ),
//                                                 Expanded(
//                                                   child: Text(
//                                                     Data[index]["AgentName"] ??
//                                                         'No name',
//                                                     style: const TextStyle(
//                                                         fontSize: 14),
//                                                     overflow:
//                                                         TextOverflow.ellipsis,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             Row(
//                                               children: [
//                                                 Row(
//                                                   children: [
//                                                     const Text("Qty: ",
//                                                         style: TextStyle(
//                                                             color:
//                                                                 Colors.grey)),
//                                                     Text(
//                                                       Data[index]["om_qty"] ??
//                                                           "N/A",
//                                                       style: const TextStyle(
//                                                         color: Colors.black,
//                                                         fontWeight:
//                                                             FontWeight.bold,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                                 const SizedBox(width: 5),
//                                                 const Text('|',
//                                                     style: TextStyle(
//                                                         color: Colors.black)),
//                                                 const SizedBox(width: 5),
//                                                 Row(
//                                                   children: [
//                                                     const Text("Item: ",
//                                                         style: TextStyle(
//                                                             color:
//                                                                 Colors.grey)),
//                                                     Text(
//                                                       Data[index][
//                                                               "om_noofitems"] ??
//                                                           "N/A",
//                                                       style: const TextStyle(
//                                                         color: Colors.black,
//                                                         fontWeight:
//                                                             FontWeight.bold,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ],
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       Column(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           Row(
//                                             mainAxisSize: MainAxisSize.min,
//                                             children: [
//                                               const Icon(Icons.currency_rupee,
//                                                   color: Colors.red, size: 15),
//                                               Text(
//                                                 (double.tryParse(Data[index][
//                                                                         "om_billamt"] ??
//                                                                     '0.00') ??
//                                                                 0.0) %
//                                                             1 ==
//                                                         0
//                                                     ? '${Data[index]["om_billamt"]?.split('.')[0]}'
//                                                     : '₹ ${Data[index]["om_billamt"]}',
//                                                 style: const TextStyle(
//                                                   color: Colors.red,
//                                                   fontSize: 14,
//                                                 ),
//                                                 overflow: TextOverflow.ellipsis,
//                                               ),
//                                             ],
//                                           ),
//                                           // Share IconButton
//                                           IconButton(
//                                             onPressed: () async {
//                                               final result =
//                                                   await Navigator.push(
//                                                 context,
//                                                 MaterialPageRoute(
//                                                   builder: (context) =>
//                                                       ChallanNew(
//                                                      omid: Data[index]["om_id"]?.toString() ?? 'N/A', // Default if null
//       omdate: Data[index]["om_date"]?.toString() ?? 'N/A',
//       custname: Data[index]["CustName"] ?? 'Unknown Customer',
//       agent: Data[index]["AgentName"] ?? 'Unknown Agent',
//       transport: Data[index]["om_transport"] ?? 'Unknown Transport',
//       username: widget.username,
//       clientcode: widget.clientcode,
//       clientname: widget.clientname,
//       clientMap: widget.clientMap,
//       orders: (widget.orders ?? []).cast<Map<String, dynamic>>(),
//       IdController: TextEditingController(
//           text: Data[index]["om_id"]?.toString() ?? ''),
    
//                                                     ChallanIdController:
//                                                         TextEditingController(),
//                                                     DateController:
//                                                         TextEditingController(),
//                                                   ),
//                                                 ),
//                                               );

//                                               if (result == true) {
//                                                 setState(() {
//                                                   getRecord(); // Refresh data after returning
//                                                 });
//                                               }
//                                             },
//                                             icon: const Icon(Icons.assignment,
//                                                 color: Colors.blue),
//                                             tooltip: "Share",
//                                           ),
//                                           IconButton(
//                                             onPressed: () {
//                                               final omId = Data[index][
//                                                   "om_id"]; // Get the dynamic om_id
//                                               _generatePDF(
//                                                   omId); // Pass om_id to generate PDF
//                                             },
//                                             icon: const Icon(Icons.share,
//                                                 color: Colors.deepPurple),
//                                             tooltip: "Share",
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//            MaterialPageRoute(
//               builder: (context) => OrderNew(
//                 omid: ["om_id"].toString() ?? 'N/A',
//                 username: widget.username,
//                 clientcode: widget.clientcode,
//                 clientname: widget.clientname,
//                 clientMap: widget.clientMap,
//                 cmpcode:cmpcode,
//                 orders: widget.orders.cast<Map<String, dynamic>>(),
//                 IdController: TextEditingController(),
//                 DateController: TextEditingController(),
//                 flag: flag,
//               ),
//             ),
//           );
//         },
//         backgroundColor: Colors.orange,
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
