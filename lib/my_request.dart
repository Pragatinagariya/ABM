import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyRequest extends StatefulWidget {
  // final String username;
  // final String clientcode;
  // final String clientname;
  // final String clientMap;
  const MyRequest({
    super.key,
    // required this.username,
    // required this.clientcode,
    // required this.clientname,
    // required this.clientMap
  });

  @override
  State<MyRequest> createState() => MyRequestState();
}

class MyRequestState extends State<MyRequest> {
  List userData = [];

  @override
  void initState() {
    super.initState();
    getRecord();
  }

  Future<void> getRecord() async {
    String uri = "${uriname}my_request.php?clientcode=$clientcode&cmp=$cmpcode&t_to=$userid";

    try {
      var response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);

        // Ensure response data is not null
        setState(() {
          // Safely cast the response to a list of maps
          userData =
              jsonResponse.map((e) => e as Map<String, dynamic>).toList();
        });
        print('Data is : ${response.body}');
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Request error: $e');
    }
  }

  Future<void> updateTaskStatus(int taskId, String statusFlag, var ud) async {
    // Define the API URL to call
    String uri =
        "${uriname}update_task.php?clientcode=$clientcode&cmp=$cmpcode"; // Replace with your actual API URL

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
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('My Request'),
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
                          margin:
                              const EdgeInsets.only(top: 2, left: 10, right: 5),
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
                                              // Text(
                                              //   userData[index]["t_id"] ??
                                              //       "N/A", // Direct access without index
                                              //   style: const TextStyle(
                                              //       fontWeight: FontWeight.bold),
                                              // ),
                                              // const SizedBox(width: 5),
                                              // const Text('|',
                                              //     style: TextStyle(
                                              //         color: Colors.black)),
                                              Text(
                                                userData[index]["t_name"] ??
                                                    "N/A", // Direct access without index
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
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
                                                  userData[index]
                                                          ["t_remarks"] ??
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
                                              Text(userData[index]
                                                      ["priority"] ??
                                                  "N/A"),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.check_circle,
                                              color: Colors.blue),
                                          onPressed: () async {
                                            // Safely convert t_id to an integer
                                            int? taskId = int.tryParse(
                                                userData[index]['t_id']
                                                    .toString());

                                            // Check if taskId is valid
                                            if (taskId != null) {
                                              // Perform update task status
                                              await updateTaskStatus(
                                                  taskId, '3', userData[index]);

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
                                        IconButton(
                                          icon: const Icon(Icons.cancel,
                                              color: Colors.red),
                                          onPressed: () async {
                                            // Safely convert t_id to an integer
                                            int? taskId = int.tryParse(
                                                userData[index]['t_id']
                                                    .toString());

                                            // Check if taskId is valid
                                            if (taskId != null) {
                                              // Perform update task status
                                              await updateTaskStatus(
                                                  taskId, '5', userData[index]);

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

                                        // IconButton(
                                        //   icon: const Icon(
                                        //     Icons.help_outline,
                                        //     color: Colors.purpleAccent,
                                        //   ),
                                        //   onPressed: () {
                                        //     Navigator.push(
                                        //       context,
                                        //       MaterialPageRoute(
                                        //           builder: (context) =>
                                        //               ChatApp()),
                                        //     );
                                        //   },
                                        // ),
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
    );
  }
}
