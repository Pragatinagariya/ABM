import 'package:flutter/material.dart';
import 'globals.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import for date formatting

class TopSell extends StatefulWidget {
  const TopSell({super.key});

  @override
  State<TopSell> createState() => _TopSellState();
}

class _TopSellState extends State<TopSell> {
  List<dynamic> topsellingitems = [];
  String? expandedItemId; // Track which item is expanded
  String selectedFilter = "All"; // Default filter
  DateTime? startDate;
  DateTime? endDate;
  @override
  void initState() {
    super.initState();
    fetchtopsellingitems();
  }

 /// Fetch top-selling items based on the selected filter.
/// Fetch top-selling items based on the selected filter.
Future<void> fetchtopsellingitems() async {
  String apiUrl = "${uriname}topsellling.php?clientcode=$clientcode&cmp=$cmpcode";
  DateTime now = DateTime.now();

  if (selectedFilter != "All") {
    switch (selectedFilter) {
      case "Today":
        String today = DateFormat("yyyy-MM-dd").format(now);
        apiUrl += "&filter=today";
        break;
      case "Yesterday":
        DateTime yesterday = now.subtract(Duration(days: 1));
        String yesterdayStr = DateFormat("yyyy-MM-dd").format(yesterday);
        apiUrl += "&filter=yesterday";
        break;
      case "Weekly":
        apiUrl += "&filter=weekly";
        break;
      case "Monthly":
        apiUrl += "&filter=monthly";
        break;
      case "Yearly":
        apiUrl += "&filter=yearly";
        break;
      case "Custom":
        if (startDate != null && endDate != null) {
          String start = DateFormat("yyyy-MM-dd").format(startDate!);
          String end = DateFormat("yyyy-MM-dd").format(endDate!);
          apiUrl += "&filter=custom&start_date=$start&end_date=$end";
        }
        break;
    }
  }

  print('Fetching top-selling items from: $apiUrl');

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final dynamic jsonResponse = json.decode(response.body);

      if (jsonResponse is List) {
        setState(() {
          topsellingitems = jsonResponse;
        });
      } else if (jsonResponse is Map && jsonResponse.containsKey("data")) {
        setState(() {
          topsellingitems = jsonResponse["data"];
        });
      } else {
        setState(() {
          topsellingitems = [];
        });
      }
    } else {
      print("Failed to load data: ${response.statusCode}");
      setState(() {
        topsellingitems = [];
      });
    }
  } catch (error) {
    print("Error: $error");
    setState(() {
      topsellingitems = [];
    });
  }
}

 Future<List<Map<String, dynamic>>> fetchOrderDetails(
  String itemId,
  String selectedFilter, {
  DateTime? startDate,
  DateTime? endDate,
}) async {
  String apiUrl =
      "${uriname}item_wise_detail.php?clientcode=$clientcode&cmp=$cmpcode&item_id=$itemId";

  // Apply filters based on selectedFilter
  if (selectedFilter == "Today") {
    apiUrl += "&filter=today";
  } else if (selectedFilter == "Yesterday") {
    apiUrl += "&filter=yesterday";
  } else if (selectedFilter == "Weekly") {
    apiUrl += "&filter=weekly";
  } else if (selectedFilter == "Monthly") {
    apiUrl += "&filter=monthly";
  } else if (selectedFilter == "Yearly") {
    apiUrl += "&filter=yearly";
  } else if (selectedFilter == "Custom" && startDate != null && endDate != null) {
    String start = DateFormat("yyyy-MM-dd").format(startDate);
    String end = DateFormat("yyyy-MM-dd").format(endDate);
    apiUrl += "&filter=custom&start_date=$start&end_date=$end";
  }

  print('Fetching order details from: $apiUrl');

  try {
    final response = await http.get(Uri.parse(apiUrl)).timeout(Duration(seconds: 10));
    
    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        try {
          final dynamic jsonResponse = json.decode(response.body);
          
          // Handle "No records found" scenario
          if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey("message")) {
            print('No records found for the given filters.');
            return [];
          }

          if (jsonResponse is List) {
            print('Parsed Order Details: $jsonResponse');
            return List<Map<String, dynamic>>.from(jsonResponse);
          } else {
            print('Unexpected JSON format for order details.');
            return [];
          }
        } catch (e) {
          print('JSON Parsing Error for order details: $e');
          return [];
        }
      } else {
        print('Empty response body for order details.');
        return [];
      }
    } else {
      print("Failed to load order details. Status Code: ${response.statusCode}");
      return [];
    }
  } catch (e) {
    print("Error fetching order details: $e");
    return [];
  }
}


  String formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat("dd-MM-yy").format(parsedDate);
    } catch (e) {
      return "Invalid Date";
    }
  }
void showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterOption("Today", setModalState),
                  _buildFilterOption("Yesterday", setModalState),
                  _buildFilterOption("Weekly", setModalState),
                  _buildFilterOption("Monthly", setModalState),
                  _buildFilterOption("Yearly", setModalState),
                  _buildFilterOption("Custom", setModalState),
                  if (selectedFilter == "Custom") ...[
                    _buildDateSelector("Start Date", startDate, (picked) {
                      setModalState(() => startDate = picked);
                    }),
                    _buildDateSelector("End Date", endDate, (picked) {
                      setModalState(() => endDate = picked);
                    }),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      // fetchtopSellingItems();
                      fetchtopsellingitems();
                      Navigator.pop(context);
                    },
                    child: Text("Apply Filter"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
Widget _buildFilterOption(String title, Function setModalState) {
    return ListTile(
      title: Text(title),
      leading: Radio<String>(
        value: title,
        groupValue: selectedFilter,
        onChanged: (value) {
          setModalState(() => selectedFilter = value!);
        },
      ),
      onTap: () => setModalState(() => selectedFilter = title),
    );
  }

Widget _buildDateSelector(String label, DateTime? date, Function(DateTime) onDatePicked) {
    return ListTile(
      title: Text("$label: ${date != null ? DateFormat("dd-MM-yyyy").format(date) : 'Select'}"),
      trailing: Icon(Icons.calendar_today),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onDatePicked(picked);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: themeColor,
       title: const Text("Top Selling Items"),
         actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: showFilterModal,
          ),
        ],
       ),
      body: topsellingitems.isEmpty
          ? const Center(child: Text("No data found"))
          : ListView.builder(
              itemCount: topsellingitems.length,
              itemBuilder: (context, index) {
                final item = topsellingitems[index];
                final String itemId = item["itemID"].toString(); // Ensure itemID is a string
                final bool isExpanded = (expandedItemId == itemId); // Check if this item is expanded

                print("ItemID: $itemId, isExpanded: $isExpanded"); // Debugging print

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
          width: 150, // Adjust width if needed
          child: Text(
            item["ItemName"],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isExpanded) {
                                      expandedItemId = null; // Collapse if already expanded
                                    } else {
                                      expandedItemId = itemId; // Expand the new item
                                    }
                                    print("Toggled ItemID: $expandedItemId"); // Debugging print
                                  });
                                },
                              ),
                            Text(
                              "${item["TotalQuantity"]}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                       

                        // Show the table when expanded
                        if (isExpanded)
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: fetchOrderDetails(itemId,selectedFilter ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return const Center(child: Text("Error fetching data"));
                              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(child: Text("No order details available"));
                              }

                              return SingleChildScrollView(
                                // scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 10,
                                  dataRowHeight: 35,
                                  headingRowHeight: 40,
                                  columns: const [
                                    DataColumn(label: Text("No", style: TextStyle(fontSize: 10))),
                                    DataColumn(label: Text("Date", style: TextStyle(fontSize: 10))),
                                    DataColumn(label: Text("Customer", style: TextStyle(fontSize: 10))),
                                    DataColumn(label: Text("Qty", style: TextStyle(fontSize: 10))),
                                    DataColumn(label: Text("Rate", style: TextStyle(fontSize: 10))),
                                  ],
                                  rows: snapshot.data!.map((order) {
                                    return DataRow(cells: [
                                      DataCell(SizedBox(
                                        width: 30,
                                        child: Text(order["OrderNo"].toString(), style: TextStyle(fontSize: 11)),
                                      )),
                                      DataCell(Text(formatDate(order["OrderDate"].toString()), style: TextStyle(fontSize: 11))),
                                      DataCell(SizedBox(
                                        width: 150,
                                        child: Text(order["CustomerName"] ?? "N/A",
                                            overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 11)),
                                      )),
                                      DataCell(Text(double.parse(order["Quantity"].toString()).toInt().toString(), style: TextStyle(fontSize: 11))),
                                      DataCell(Text(order["Rate"].toString(), style: TextStyle(fontSize: 11))),
                                    ]);
                                  }).toList(),
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

