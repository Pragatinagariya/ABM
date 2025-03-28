import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'dart:convert';
import 'globals.dart';

class JobWork extends StatefulWidget {
  

  const JobWork({super.key});

  @override
  State<JobWork> createState() => _JobWorkState();
}
String formatDate(String dateTimeStr) {
  try {
    DateTime dateTime = DateTime.parse(dateTimeStr).toLocal(); // Convert to local time
    return DateFormat('yyyy-MM-dd').format(dateTime); // Output: 2024-04-29
  } catch (e) {
    return "Invalid Date";
  }
}


String getJobNumber(Map<String, dynamic> item) {
  String prefix = item["IM_Prefix"] ?? "";
  String invoiceNo = item["IM_InvoiceNo"] ?? "N/A";
   return "$prefix" "_" "$invoiceNo";   // Jo_132839
}


class _JobWorkState extends State<JobWork> {
  List jobData = [];

  @override
  void initState() {
    super.initState();
    getJobWorkData();
  }
Widget buildCalendarWidget(String? date) {
  DateTime? parsedDate;
  if (date != null && date.isNotEmpty) {
    try {
      parsedDate = DateTime.parse(date).toLocal(); // Convert to local time
    } catch (e) {
      parsedDate = null;
    }
  }

  if (parsedDate == null) {
    return Text(
      "N/A",
      style: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  String month = DateFormat.MMM().format(parsedDate); // Month (Apr)
  String day = parsedDate.day.toString(); // Day (29)
  String year = parsedDate.year.toString(); // Year (2024)

  return Container(
    width: 55,
    height: 98, // Reduced width for compact look
    padding: const EdgeInsets.all(5), // Reduced padding
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.grey.shade400, width: 0.8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 3,
          spreadRadius: 1,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Month Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Text(
            month,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 1),

        // Day Section
        Container(
          width: 45,
          height: 29,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 226, 60, 60),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            day,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 1),

        // Year Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
          ),
          child: Text(
            year,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

  Future<void> getJobWorkData() async {
    String uri = "http://intern.amisys.in:3000/jobwork";

    if (token.isEmpty) {
      print('Token is empty. Cannot proceed with request.');
      return;
    }

    try {
      var response = await http.get(
        Uri.parse(uri),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        var jsonResponse;
        try {
          jsonResponse = jsonDecode(response.body);
        } catch (e) {
          print('JSON decoding error: $e');
          return;
        }

        if (jsonResponse is List) {
          setState(() {
            jobData = jsonResponse;
          });
        } else {
          print('Unexpected response format: ${jsonResponse.runtimeType}');
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Request error: $e');
    }
  }

  // Function to extract only the date part from DateTime string
  // String formatDate(String? dateTime) {
  //   if (dateTime == null || dateTime.isEmpty) return "N/A";
  //   return dateTime.split(' ')[0]; // Extracts only the date part
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('Job Work Details'),
      ),
    body: jobData.isEmpty
    ? const Center(child: CircularProgressIndicator())
    : ListView.builder(
        itemCount: jobData.length,
        itemBuilder: (context, index) {
          final item = jobData[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row( // Use Row to align the calendar widget and details
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calendar widget on the left
                  buildCalendarWidget(item["IM_date"]),

                  const SizedBox(width: 10), // Space between calendar and details

                  // Job Work Details
                  Expanded( // Ensure details take up remaining space
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First line: Invoice No & Date
                        RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context)
                                .style
                                .copyWith(fontSize: 16, color: Colors.black),
                            children: [
                              const TextSpan(
                                  text: "Job No. ",
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: getJobNumber(item)), // Jo_132839
                             
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),

                        // Customer ID
     Tooltip(
  message: item["JobWorkerName"] ?? "N/A",
  child: Text(
    "${item["JobWorkerName"] ?? "N/A"}",
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold, // Makes the text bold
    ),
    overflow: TextOverflow.ellipsis, // Ensures text remains in a single line
  ),
),


                        const SizedBox(height: 5),

                        // Additional details
                         Text("Job Qty: ${item["JobQty"] ?? "N/A"}"),
                        Text("Remarks: ${item["im_remarks1"] ?? "N/A"}"),
                       
                      ],
                    ),
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