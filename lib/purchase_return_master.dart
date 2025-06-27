import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'purchase_return-transaction.dart';
import 'package:intl/intl.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';

class PurchaseReturnMaster extends StatefulWidget {
  final String username; // Add username parameter
  final String clientcode;
  final String clientname;
  final String clientMap;
  const PurchaseReturnMaster(
      {super.key,
      required this.username,
      required this.clientcode,
      required this.clientname,
      required this.clientMap}); // Accept username in constructor

  @override
  State<PurchaseReturnMaster> createState() => PurchaseReturnMasterState();
}

class PurchaseReturnMasterState extends State<PurchaseReturnMaster> {
  List Data = [];
  Map<String, String> appliedFilters = {};
  DateTime? startDate;
  DateTime? endDate;
  String? selectedCity;
  String? _selectedFilter;
  String? _selectedDateRange;
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getRecord();
  }

  Future<void> getRecord(
      {DateTime? startDate, DateTime? endDate, String? selectedCity}) async {
    // Build the URI with applied filters
    String uri =
        "${uriname}purchase_return_master.php?clientcode=$clientcode&cmp=$cmpcode";

    if (startDate != null && endDate != null) {
      String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);
      uri += "&fromdate=$formattedStartDate&todate=$formattedEndDate";
    }

    if (selectedCity != null && selectedCity.isNotEmpty) {
      uri += "&city=${Uri.encodeComponent(selectedCity)}";
    }

    // Debugging the URI to make sure the filters are being added correctly
    print("Request URI: $uri");

    try {
      var response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse is List) {
          setState(() {
            Data = jsonResponse;
          });
        } else {
          print('Unexpected response format');
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Request error: $e');
    }
  }

 void _showFilterOptions(BuildContext context) {
    // Set defaults when the modal is opened
    _selectedFilter = "Date";
    _selectedDateRange =
        _selectedDateRange ?? 'This Year'; // Default to 'This Year'
    _setDateRange(_selectedDateRange!); // Apply default date range on opening

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
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
                            children: [
                              const Text("Date"),
                              if (appliedFilters["Date"] != null)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: CircleAvatar(
                                    radius: 4,
                                    backgroundColor: Colors.orange,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            setModalState(() => _selectedFilter = "Date");
                          },
                        ),
                        const Divider(),
                        ListTile(
                          title: Row(
                            children: [
                              const Text("City"),
                              if (appliedFilters["City"] != null)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: CircleAvatar(
                                    radius: 4,
                                    backgroundColor: Colors.orange,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            setModalState(() => _selectedFilter = "City");
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
                            _selectedFilter ?? "Select Filter",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_selectedFilter == "Date")
                          _buildDateFilter(setModalState),
                        if (_selectedFilter == "City")
                          _buildCityFilter(setModalState),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      _showAppliedFiltersMessage(context);
      getRecord(
        startDate: startDate,
        endDate: endDate,
        selectedCity: selectedCity,
      ); // Fetch data after filters are applied
    });
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
            groupValue: _selectedDateRange,
            onChanged: (value) {
              setModalState(() {
                _selectedDateRange = value;
                _setDateRange(value!); // Apply the selected date range
                appliedFilters["Date"] = value; // Mark filter as applied
              });
            },
          ),
        if (_selectedDateRange == 'Custom Date Range')
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
                    dateFormat: "yyyy-MM-dd",
                    titleText: "Select Start Date",
                    locale: DateTimePickerLocale.en_us,
                  );
                  setModalState(() {
                    startDate = pickedStartDate;
                  });
                                },
                child: Text(
                    "Select Start Date: ${startDate != null ? startDate.toString().split(' ')[0] : 'Not Selected'}"),
              ),
              ElevatedButton(
                onPressed: () async {
                  DateTime? pickedEndDate =
                      await DatePicker.showSimpleDatePicker(
                    context,
                    initialDate: DateTime.now(),
                    firstDate: startDate ?? DateTime(2000),
                    lastDate: DateTime.now(),
                    dateFormat: "yyyy-MM-dd",
                    titleText: "Select End Date",
                    locale: DateTimePickerLocale.en_us,
                  );
                  setModalState(() {
                    endDate = pickedEndDate;
                  });
                                },
                child: Text(
                    "Select End Date: ${endDate != null ? endDate.toString().split(' ')[0] : 'Not Selected'}"),
              ),
            ],
          ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            getRecord(
                startDate: startDate,
                endDate: endDate,
                selectedCity: selectedCity); // Apply the selected date filter
          },
          child: const Text("Apply"),
        ),
      ],
    );
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
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate!.add(const Duration(days: 6));
        break;
      case 'Yesterday':
        startDate = now.subtract(const Duration(days: 1));
        endDate = startDate;
        break;
      case 'Today':
        startDate = now;
        endDate = now;
        break;
    }
  }

  Widget _buildCityFilter(StateSetter setModalState) {
    return Column(
      children: [
        TextField(
          controller: _cityController,
          decoration: const InputDecoration(labelText: "Enter City"),
          onChanged: (value) {
            // Optionally update the state within the modal as the user types
            setModalState(() {
              selectedCity = value;
            });
          },
        ),
        ElevatedButton(
          onPressed: () {
            setModalState(() {
              selectedCity = _cityController.text;
              appliedFilters["City"] = selectedCity ?? '';
            });
            Navigator.pop(context);
            getRecord(
                startDate: startDate,
                endDate: endDate,
                selectedCity: selectedCity); // Apply the city filter
          },
          child: const Text("Apply"),
        ),
      ],
    );
  }

  void _showAppliedFiltersMessage(BuildContext context) {
    String appliedFiltersText = appliedFilters.entries
        .map((entry) {
          if (entry.key == "Date" && _selectedDateRange != null) {
            if (startDate != null && endDate != null) {
              return "${entry.key}: ${_formatDate(startDate!)} to ${_formatDate(endDate!)}";
            } else {
              return "${entry.key}: $_selectedDateRange";
            }
          } else if (entry.key == "City") {
            return "${entry.key}: ${entry.value}";
          }
          return "";
        })
        .where((text) => text.isNotEmpty)
        .join(", ");

    if (appliedFiltersText.isEmpty) {
      appliedFiltersText = "No filters applied";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Filters Applied: $appliedFiltersText"),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('Purchase Return'),
      ),
      body: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Column(
                    children: [
                      Icon(Icons.person, color: Colors.orange),
                      Text("A",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const Column(
                    children: [
                      Icon(Icons.account_balance, color: Colors.orange),
                      Text("B",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const Column(
                    children: [
                      Icon(Icons.location_city, color: Colors.orange),
                      Text("C",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      _showFilterOptions(context);
                    },
                    child: const Column(
                      children: [
                        Icon(Icons.filter_list, color: Colors.orange),
                        Text("Filters",
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Data.isEmpty
                ? const Center(
                      child: Text('No Data Found',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    )
                : Expanded(
                    child: ListView.builder(
                      itemCount: Data.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PurchaseReturnTransaction(
                                  itid: Data[index]["IM_Id"],
                                  invoice: Data[index]["IM_InvoiceNo"],
                                  username: widget.username,
                                  clientcode: widget.clientcode,
                                  clientname: widget.clientname,
                                  clientMap: widget.clientMap,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.only(
                                top: 2, left: 10, right: 5),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  Data[index]["IM_InvoiceNo"] ??
                                                      "N/A",
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                const SizedBox(width: 5),
                                                const Text('|',
                                                    style: TextStyle(
                                                        color: Colors.black)),
                                                const SizedBox(width: 5),
                                                Text(Data[index]["IM_Date"] ??
                                                    "N/A"),
                                              ],
                                            ),
                                            Text(
                                              Data[index]["CustName"] ??
                                                  'No name',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if ((Data[index]["IM_LRNo"] !=
                                                        null &&
                                                    Data[index]["IM_LRNo"]
                                                        .isNotEmpty) ||
                                                (Data[index]["IM_LRDate"] !=
                                                        null &&
                                                    Data[index]["IM_LRDate"]
                                                        .isNotEmpty))
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start, // Align children to the start (left)
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Text(
                                                        "LR No: ",
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey, // Gray color for the label
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        Data[index]
                                                                ["IM_LRNo"] ??
                                                            "N/A",
                                                        style: const TextStyle(
                                                          color: Colors
                                                              .black, // Data color can remain black
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                        "LR Date: ",
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey, // Gray color for the label
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        Data[index]
                                                                ["IM_LRDate"] ??
                                                            "N/A",
                                                        style: const TextStyle(
                                                          color: Colors
                                                              .black, // Data color can remain black
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            Row(
                                              children: [
                                                const Text(
                                                  'Transport: ',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey),
                                                ),
                                                Expanded(
                                                  child: SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: Text(
                                                      Data[index]
                                                              ["IM_Transport"] ??
                                                          'No name',
                                                      style: const TextStyle(
                                                          fontSize: 14),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                const Text(
                                                  'Agent: ',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    Data[index]["AgentName"] ??
                                                        'No name',
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Center-aligned Bill Amount
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.currency_rupee,
                                                  color: Colors.red, size: 15),
                                             Text(
                                                (double.tryParse(Data[index][
                                                                        "IM_BillAmt"] ??
                                                                    '0.00') ??
                                                                0.0) %
                                                            1 ==
                                                        0
                                                    ? ' ${Data[index]["IM_BillAmt"]?.split('.')[0]}' // Show only whole number if no decimal part
                                                    : '₹ ${Data[index]["IM_BillAmt"]}', // Show with decimal if there's any
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
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
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
