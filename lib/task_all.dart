import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';

class TaskAll extends StatefulWidget {
  // final String username;
  // final String clientcode;
  // final String clientname;
  // final String clientMap;
  const TaskAll({
    super.key,
    // required this.username,
    // required this.clientcode,
    // required this.clientname,
    // required this.clientMap
  });

  @override
  State<TaskAll> createState() => TaskAllState();
}

class TaskAllState extends State<TaskAll> {
  List userData = [];
  List<dynamic> filteredData = [];
  String selectedFilter = '';
  DateTime? startDate;
  DateTime? endDate;
  String selectedDateFilter = '';
  String selectedStatus = "";

  @override
  void initState() {
    super.initState();
    getRecord();
  }

  Future<void> getRecord() async {
    String uri =
        "${uriname}task_all.php?clientcode=$clientcode&cmp=$cmpcode";

    try {
      var response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);

        // Ensure response data is not null
        setState(() {
          // Safely cast the response to a list of maps
          userData =
              jsonResponse.map((e) => e as Map<String, dynamic>).toList();
          filteredData = List.from(userData); // Initially show all data

          // ✅ Apply today's date filter by default
          DateTime today = DateTime.now();
          startDate = DateTime(today.year, today.month, today.day);
          endDate = DateTime(today.year, today.month, today.day);
        });

        print('Data is : ${response.body}');

        // ✅ Apply filters after setting the date
        _applyFilters();
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Request error: $e');
    }
  }

  Color getStatusColor(String statusFlag) {
    switch (statusFlag) {
      case '3':
        return Colors.blue.shade100; // Blue for status 3
      case '5':
        return Colors.red.shade100; // Red for status 5
      case '6':
        return Colors.green.shade100; // Green for status 6
      default:
        return Colors.white; // Default White for status 1 or others
    }
  }

  String getStatusText(String statusFlag) {
    switch (statusFlag) {
      case '3':
        return 'Approved';
      case '5':
        return 'Rejected';
      case '6':
        return 'Completed';
      default:
        return ''; // No text for status 1 or others
    }
  }

  Future<void> updateTaskStatus(int taskId, String statusFlag, var ud) async {
    // Define the API URL to call
    String uri =
        "${uriname}update_task.php?clientcode=$clientcode&cmp=$cmpcode"; // Replace with your actual API URL

    // Prepare the data to be sent to the server
    var data = {
      'task_id': taskId.toString(),
      'status_flag': statusFlag,
      't_from': ud['t_from'] ?? 'No remarks',
      't_to': ud['t_to'] ?? 'No remarks',
      'remarks': ud['t_remarks'] ?? 'No remarks',
      'priority': ud['t_priority'] ?? 'No remarks',
    };
    // Perform the POST request to the server
    try {
      var response = await http.post(Uri.parse(uri), body: data);

      // Debugging: Print the response body
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Successfully updated task status
        print("Task status updated to $statusFlag!");
        // You could also parse the response if you want to display a message or process the response further
      } else {
        print("Request failed with status: ${response.statusCode}");
      }
    } catch (e) {
      // Handle any errors that occur during the HTTP request
      print('Error: $e');
    }
  }

  void _showFilterOptions(BuildContext context) {
    selectedFilter = "Date"; // Default to 'Name' filter

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
                                    Text("Task"),
                                  ],
                                ),
                                onTap: () {
                                  setModalState(() => selectedFilter = "Task");
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
                              if (selectedFilter == "Date")
                                _buildDateFilter(setModalState),
                              if (selectedFilter == "Task")
                                _buildTaskFilter(setModalState),
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
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
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
                    dateFormat: "dd-MM-yyyy",
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
          startDateFilter =
              now.subtract(Duration(days: now.weekday - 1)); // Monday
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
        final dateStr = item["t_date"];
        DateTime? itemDate = parseDate(dateStr);
        if (itemDate != null) {
          return (itemDate.isAtSameMomentAs(startDateFilter!) ||
                  itemDate.isAfter(startDateFilter)) &&
              (itemDate.isAtSameMomentAs(endDateFilter!) ||
                  itemDate.isBefore(endDateFilter));
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
        startDate = now
            .subtract(Duration(days: now.weekday - 1)); // Monday of this week
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

  Widget _buildTaskFilter(StateSetter setModalState) {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text("All"),
          value: "All",
          groupValue: selectedStatus,
          onChanged: (value) {
            setModalState(() {
              selectedStatus = value!;
              _applyFilters(); // Apply filter
            });
          },
        ),
        RadioListTile<String>(
          title: const Text("Request"),
          value: "Request",
          groupValue: selectedStatus,
          onChanged: (value) {
            setModalState(() {
              selectedStatus = value!;
              _applyFilters(); // Apply filter
            });
          },
        ),
        RadioListTile<String>(
          title: const Text("Accept"),
          value: "Accept",
          groupValue: selectedStatus,
          onChanged: (value) {
            setModalState(() {
              selectedStatus = value!;
              _applyFilters(); // Apply filter
            });
          },
        ),
        RadioListTile<String>(
          title: const Text("Completed"),
          value: "Completed",
          groupValue: selectedStatus,
          onChanged: (value) {
            setModalState(() {
              selectedStatus = value!;
              _applyFilters(); // Apply filter
            });
          },
        ),
        RadioListTile<String>(
          title: const Text("Reject"),
          value: "Reject",
          groupValue: selectedStatus,
          onChanged: (value) {
            setModalState(() {
              selectedStatus = value!;
              _applyFilters(); // Apply filter
            });
          },
        ),
      ],
    );
  }

  void _applyFilters() {
    setState(() {
      // 🔹 Start with all data
      filteredData = List.from(userData);
      print("Original Data: ${filteredData.length} items");

      // 🔹 Step 1: Apply Date Range Filter (if selected)
      if (startDate != null && endDate != null) {
        print("Applying date filter from $startDate to $endDate");

        filteredData = filteredData.where((item) {
          final dateStr = item["t_date"];
          DateTime? itemDate = parseDate(dateStr);

          if (itemDate == null) {
            print("Skipping invalid date: $dateStr");
            return false;
          }

          return (itemDate.isAtSameMomentAs(startDate!) || itemDate.isAfter(startDate!)) &&
              (itemDate.isAtSameMomentAs(endDate!) || itemDate.isBefore(endDate!));
        }).toList();

        print("After Date Filter: ${filteredData.length} items");
      }

      // 🔹 Step 2: Apply Status Filter (only if selected)
      if (selectedStatus.isNotEmpty && selectedStatus != "All") {
        print("Applying status filter: $selectedStatus");

        filteredData = filteredData.where((item) => item["status"] == selectedStatus).toList();

        print("After Status Filter: ${filteredData.length} items");
      } else if (selectedStatus == "All") {
        print("Showing Completed & Reject tasks");

        filteredData = filteredData.where((item) => item["status"] == "Request" || item["status"] == "Accept"|| item["status"] == "Completed"|| item["status"] == "Reject").toList();
      }

      print("Final Filtered Data Count: ${filteredData.length}");
    });
  }

  // void _applyStatusFilters(String status) {
  //   setState(() {
  //     // Apply filtering based on the button clicked
  //     filteredData =
  //         userData.where((item) => item["status"] == status).toList();
  //     print("Filtered Data: $filteredData");
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:Theme.of(context).primaryColor,
        title: const Text('All Tasks'),
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
          Expanded(
            child: filteredData.isEmpty
                ? const Center(
                    child: Text('No Data Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  )
                : ListView.builder(
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final item = filteredData[index];
                      String statusFlag = item["t_status"] ?? "1";
                      String toName = item["t_toname"];
                      String taskName = item["t_name"] ?? "No name";

                      String date = item["t_date"] ?? "N/A";
                      List<String> dateParts = date.split('-');
                      String day = dateParts[0];
                      String month = dateParts[1];
                      String year = dateParts[2];

                      Map<String, String> monthNames = {
                        "01": "Jan","02": "Feb","03": "Mar","04": "Apr",
                        "05": "May","06": "Jun","07": "Jul","08": "Aug",
                        "09": "Sep","10": "Oct","11": "Nov","12": "Dec"
                      };
                      String monthName = monthNames[month] ?? "N/A";

                      return InkWell(
                        onTap: () {
                          // Add actions if needed
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Column(
                                      mainAxisAlignment:  MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Text(day, style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 18)),
                                                Text(monthName, style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16)),
                                                Text(year, style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: (item["t_fromname"] == username)
                                                      ? Colors.blue.withOpacity(0.2) // Different color for "Me"
                                                      : themeColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color:
                                                        (item["t_fromname"] == username) ? Colors.blue : themeColor,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                    item["t_fromname"] == username ? "Me" 
                                                  : item["t_fromname"] ?? "No name",
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.arrow_forward_outlined, size: 16),
                                              const SizedBox(width: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric( horizontal: 12, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: (toName == username)
                                                      ? Colors.blue.withOpacity(0.2) 
                                                      : Theme.of(context).primaryColor .withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: (toName == username) ? Colors.blue : Theme.of(context).primaryColor,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                    toName == username ? "Me" : toName,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Text('Task: ',
                                                  style: TextStyle(fontSize: 14,  color: Colors.grey)),
                                              Expanded(
                                                  child: Text(taskName,
                                                      style: const TextStyle(fontSize: 14),
                                                      overflow: TextOverflow.ellipsis)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Text('Remarks: ',
                                                  style: TextStyle(fontSize: 14, color: Colors.grey)),
                                              Expanded(
                                                  child: Text(
                                                      item["t_remarks"] ?? 'No remarks',
                                                      style: const TextStyle( fontSize: 14),
                                                      overflow: TextOverflow.ellipsis)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: getStatusColor(statusFlag),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Theme.of(context).primaryColor, width: 1),
                                          ),
                                          child: Text(item["status"] ?? "No",
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (toName == username) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (item["status"] == "Request") ...[
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blueGrey.shade100,
                                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                              ),
                                              onPressed: () async {
                                                int? taskId = int.tryParse(item['t_id'].toString());
                                                if (taskId != null) {
                                                  await updateTaskStatus(taskId, '3', item);
                                                  await getRecord();
                                                  setState(() {
                                                    // taskApprovalStatus[taskId] = true;
                                                  });
                                                }
                                              },
                                              child: const Text('👍 Accept',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:Theme.of(context).primaryColor,
                                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                              ),
                                              onPressed: () async {
                                                int? taskId = int.tryParse(item['t_id'].toString());
                                                if (taskId != null) {
                                                  await updateTaskStatus(taskId, '5', item);
                                                  await getRecord();
                                                  setState(() {
                                                    // taskApprovalStatus[taskId] = false;
                                                  });
                                                }
                                              },
                                              child: const Text('❌ Reject',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (item["status"] == "Accept") ...[
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green.shade100,
                                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                              ),
                                              onPressed: () async {
                                                int? taskId = int.tryParse(item['t_id'].toString());
                                                if (taskId != null) {
                                                  await updateTaskStatus(taskId, '6', item);
                                                  await getRecord();
                                                  setState(() {
                                                    // taskApprovalStatus[taskId] = false;
                                                  });
                                                }
                                              },
                                              child: const Text('✅ Complete', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
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
