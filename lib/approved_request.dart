import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'shared_pref_helper.dart';
class ApprovedRequest extends StatefulWidget {
  // final String username;
  final String clientcode;
  final String clientname;
  final String clientMap;
  const ApprovedRequest(
      {super.key,
      // required this.username,
      required this.clientcode,
      required this.clientname,
      required this.clientMap
      });

  @override
  State<ApprovedRequest> createState() => ApprovedRequestState();
}

class ApprovedRequestState extends State<ApprovedRequest> {
  List userData = [];

  @override
  void initState() {
    super.initState();
    print("clientcode: $clientcode, cmpcode: $cmpcode, userid: $userid"); // Debugging
  if (cmpcode != null) {
    getRecord();
  } else {
    print("User data is missing!");
  }
    getRecord();
  }

  Future<void> getRecord() async {
   

  // String? clientcode = await SharedPrefHelper.getclientcode();
  // String? cmpcode = await SharedPrefHelper.getCmpCode();
  // String? userid = await SharedPrefHelper.getUserid();

  print("Fetched from SharedPreferences:");
  print("Client Code: $clientcode");
  print("Company Code: $cmpcode");
  print("User ID: $userid");

  String url = "https://abm99.amisys.in/android/PHP/v2/approved_task.php?clientcode=$clientcode&cmp=$cmpcode&t_to=$userid";
  print("Fetching Data from: $url");

  try {
    var response = await http.get(Uri.parse(url));
    print("API Response: ${response.body}");

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      print("Parsed Data: $jsonResponse");

      if (mounted) {
        setState(() {
          userData = jsonResponse.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } else {
      print("Request failed with status: ${response.statusCode}");
    }
  } catch (e) {
    print("Error fetching data: $e");
  }
}

Future<void> updateTaskStatus(int taskId, String statusFlag, var ud) async {
    // Define the API URL to call
    String uri =
        "${uriname}update_task.php?clientcode=$clientcode&cmp=$cmpcode";

    // Debugging: Print variables for inspection
    print("Inside updateTaskStatus....");
    print('taskid: $taskId');
    print('ud[t_id]: ${ud['t_id']}');
    print('ud[t_name]: ${ud['t_name']}');
    print('ud[t_date]: ${ud['t_date']}');
    print('ud[t_from]: ${ud['t_from']}');
    print('ud[t_to]: ${ud['t_to']}');
    print('ud[t_remarks]: ${ud['t_remarks']}');

    // Prepare the data to be sent to the server
    var data = {
      'task_id': taskId.toString(),
      'status_flag': statusFlag,
      't_from': ud['t_from'] ?? 'No remarks',
      't_to': ud['t_to'] ?? 'No remarks',
      'remarks': ud['t_remarks'] ?? 'No remarks',
      'priority': ud['t_priority'] ?? 'No remarks',
    };

    // Debugging: Print the data being sent
    print('New data: $data');
    print('taskid: $taskId');
    print('status_flag: $statusFlag');
    print('t_from: ${data['t_from']}');
    print('t_to: ${data['t_to']}');
    print('remarks: ${data['remarks']}');
    print('priority: ${data['priority']}');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('Approved Request'),
      ),
      body: Column(
        children: [
          Expanded(
            child: userData.isEmpty
                ? const Center(
                    child: Text('No Data Found',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  )
                : ListView.builder(
                    itemCount: userData.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          // Add actions if needed
                        },
                        child: Card(
                          margin: const EdgeInsets.only(top: 2, left: 10, right: 5),
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
                                                userData[index]["t_name"] ??
                                                    "N/A", // Direct access without index
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 5),
                                              const Text('|',
                                                  style: TextStyle(
                                                      color: Colors.black)),
                                              const SizedBox(width: 5),
                                              Text(userData[index]["t_date"] ??
                                                  "N/A"),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Text(
                                                'From: ',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey),
                                              ),
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: Text(
                                                    userData[index]
                                                            ["t_fromname"] ??
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
                                                'To: ',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  userData[index]["t_toname"] ??
                                                      'No name',
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Text(
                                                'Remarks: ',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  userData[index]["t_remarks"] ??
                                                      'No name',
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                userData[index]["status"] ??
                                                    "N/A", // Direct access without index
                                                // style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 5),
                                              const Text('|',
                                                  style: TextStyle(
                                                      color: Colors.black)),
                                              const SizedBox(width: 5),
                                              Text(
                                                  userData[index]["priority"] ??
                                                      "N/A"),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                          icon: const Icon(Icons.check_box,
                                              color: Colors.green),
                                          onPressed: () async {
                                            // Safely convert t_id to an integer
                                            int? taskId = int.tryParse(
                                                userData[index]['t_id']
                                                    .toString());

                                            // Check if taskId is valid
                                            if (taskId != null) {
                                              // Perform update task status
                                              await updateTaskStatus(
                                                  taskId, '6', userData[index]);

                                              await getRecord(); // Fetch the latest data from the server

                                              setState(() {
                                                // This will reflect the changes from getRecord automatically
                                              });
                                            } else {
                                              print(
                                                  "Error: task_id is null or invalid");
                                            }
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
