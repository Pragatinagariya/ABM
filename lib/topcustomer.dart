import 'package:flutter/material.dart';
import 'globals.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TopCust extends StatefulWidget {
  const TopCust({super.key});

  @override
  State<TopCust> createState() => _TopCustState();
}

class _TopCustState extends State<TopCust> {
  List<dynamic> topsellingitems = [];
  String? expandedItemId;
  String selectedFilter = "All"; // Default filter
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    fetchTopSellingItems();
  }

  /// Fetch order details for a given customer based on the same filter.
  Future<List<Map<String, dynamic>>> fetchOrderDetails(
    String customerId,
    String selectedFilter, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String apiUrl =
        "${uriname}customer_wise_item.php?clientcode=$clientcode&cmp=$cmpcode&customer_id=$customerId";

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
    } else if (selectedFilter == "Custom" &&
        startDate != null &&
        endDate != null) {
      String start = DateFormat("yyyy-MM-dd").format(startDate);
      String end = DateFormat("yyyy-MM-dd").format(endDate);
      apiUrl += "&filter=custom&start_date=$start&end_date=$end";
    }

    print('Fetching order details from: $apiUrl');

    try {
      final response = await http.get(Uri.parse(apiUrl));
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          try {
            final dynamic jsonResponse = json.decode(response.body);

            // Handle "No records found" message from PHP
            if (jsonResponse is Map<String, dynamic> &&
                jsonResponse.containsKey("message")) {
              print('No records found for order details.');
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
        print(
            "Failed to load order details. Status Code: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error fetching order details: $e");
      return [];
    }
  }

  /// Format date in dd-MM-yy format.
  String formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat("dd-MM-yy").format(parsedDate);
    } catch (e) {
      return "Invalid Date";
    }
  }

  /// Fetch top customers based on the selected filter.
  Future<void> fetchTopSellingItems() async {
    String apiUrl =
        "${uriname}topcustomer.php?clientcode=$clientcode&cmp=$cmpcode";
    DateTime now = DateTime.now();

    if (selectedFilter == "Today") {
      String today = DateFormat("yyyy-MM-dd").format(now);
      apiUrl += "&start_date=$today&end_date=$today";
    } else if (selectedFilter == "Yesterday") {
      DateTime yesterday = now.subtract(Duration(days: 1));
      String yesterdayStr = DateFormat("yyyy-MM-dd").format(yesterday);
      apiUrl += "&start_date=$yesterdayStr&end_date=$yesterdayStr";
    } else if (selectedFilter == "Weekly") {
      DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
      String start = DateFormat("yyyy-MM-dd").format(weekStart);
      String end = DateFormat("yyyy-MM-dd").format(now);
      apiUrl += "&start_date=$start&end_date=$end";
    } else if (selectedFilter == "Monthly") {
      DateTime monthStart = DateTime(now.year, now.month, 1);
      String start = DateFormat("yyyy-MM-dd").format(monthStart);
      String end = DateFormat("yyyy-MM-dd").format(now);
      apiUrl += "&start_date=$start&end_date=$end";
    } else if (selectedFilter == "Yearly") {
      DateTime yearStart = DateTime(now.year, 1, 1);
      String start = DateFormat("yyyy-MM-dd").format(yearStart);
      String end = DateFormat("yyyy-MM-dd").format(now);
      apiUrl += "&start_date=$start&end_date=$end";
    } else if (selectedFilter == "Custom" &&
        startDate != null &&
        endDate != null) {
      String start = DateFormat("yyyy-MM-dd").format(startDate!);
      String end = DateFormat("yyyy-MM-dd").format(endDate!);
      apiUrl += "&start_date=$start&end_date=$end";
    }
    print('Fetching top customer data from: $apiUrl');

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);
        List<dynamic> data =
            jsonResponse is List ? jsonResponse : jsonResponse["data"];
        setState(() {
          topsellingitems = data.isNotEmpty ? data : [];
        });
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

  /// Display filter options in a bottom sheet.
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
                      fetchTopSellingItems();
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

  /// Builds a filter option list tile.
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

  /// Builds a date selector list tile.
  Widget _buildDateSelector(
      String label, DateTime? date, Function(DateTime) onDatePicked) {
    return ListTile(
      title: Text(
          "$label: ${date != null ? DateFormat("dd-MM-yyyy").format(date) : 'Select'}"),
      trailing: Icon(Icons.calendar_today),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        onDatePicked(picked!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text("Top Customer"),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: showFilterModal,
          ),
        ],
      ),
      body: topsellingitems.isEmpty
          ? Center(child: Text("No data found"))
          : ListView.builder(
              itemCount: topsellingitems.length,
              itemBuilder: (context, index) {
                final item = topsellingitems[index];
                final String customerId = item["CustomerID"].toString();
                final bool isExpanded = (expandedItemId == customerId);

                return Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: screenWidth * 0.5,
                                  child: Text(
                                    item["CustomerName"],
                                    style: TextStyle(
                                      fontSize: isTablet ? 18 : 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      expandedItemId =
                                          isExpanded ? null : customerId;
                                    });
                                  },
                                ),
                              ],
                            ),
                            Text(
                              "${item["TotalRevenue"]}",
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        // Show the table when expanded, filtered with the same parameters
                        if (isExpanded)
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: fetchOrderDetails(
                              customerId,
                              selectedFilter,
                              startDate: startDate,
                              endDate: endDate,
                            ),
                            builder: (context, snapshot) {
                              final screenWidth =
                                  MediaQuery.of(context).size.width;
                              final fontSize = screenWidth *
                                  0.025; // adjusts based on screen width
                              final dataFontSize = screenWidth * 0.028;
                              final columnSpacing = screenWidth * 0.08;
                              final dataRowHeight = screenWidth * 0.09;
                              final headingRowHeight = screenWidth * 0.1;

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return const Center(
                                    child: Text("Error fetching data"));
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Center(
                                    child: Text("No order details available"));
                              }

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: columnSpacing,
                                  dataRowHeight: dataRowHeight,
                                  headingRowHeight: headingRowHeight,
                                  columns: [
                                    DataColumn(
                                        label: Text("No",
                                            style:
                                                TextStyle(fontSize: fontSize))),
                                    DataColumn(
                                        label: Text("Date",
                                            style:
                                                TextStyle(fontSize: fontSize))),
                                    DataColumn(
                                        label: Text("Qty",
                                            style:
                                                TextStyle(fontSize: fontSize))),
                                    DataColumn(
                                      label: SizedBox(
                                        width: screenWidth * 0.15,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text("Rate",
                                              style: TextStyle(
                                                  fontSize: fontSize)),
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: snapshot.data!.map((order) {
                                    return DataRow(cells: [
                                      DataCell(SizedBox(
                                        width: screenWidth * 0.08,
                                        child: Text(order["OrderNo"].toString(),
                                            style: TextStyle(
                                                fontSize: dataFontSize)),
                                      )),
                                      DataCell(Text(
                                        formatDate(
                                            order["OrderDate"].toString()),
                                        style:
                                            TextStyle(fontSize: dataFontSize),
                                      )),
                                      DataCell(Text(
                                        double.parse(
                                                order["Quantity"].toString())
                                            .toInt()
                                            .toString(),
                                        style:
                                            TextStyle(fontSize: dataFontSize),
                                      )),
                                      DataCell(SizedBox(
                                        width: screenWidth * 0.15,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(order["Rate"].toString(),
                                              style: TextStyle(
                                                  fontSize: dataFontSize)),
                                        ),
                                      )),
                                    ]);
                                  }).toList(),
                                ),
                              );
                            },
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
