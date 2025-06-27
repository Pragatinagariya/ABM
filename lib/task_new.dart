import 'globals.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TaskNew extends StatefulWidget {
  const TaskNew({super.key});

  @override
  State<TaskNew> createState() => _TaskNewState();
}

class _TaskNewState extends State<TaskNew> {
  TextEditingController taskName = TextEditingController();
  TextEditingController desc = TextEditingController();
  TextEditingController set_date = TextEditingController();
  TextEditingController time = TextEditingController();

  // Data lists from API
  List<Map<String, String>> users = [];
  List<Map<String, String>> status = [];
  List<Map<String, String>> priority = [];

  // Selected dropdown values
  String? selectedFrom;
  String? selectedTo;
  String? selectedStatus;
  String? selectedPriority;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> insertData() async {
    String apiUrl = "${uriname}task_new.php";

    Map<String, dynamic> requestData = {
      "cmp": cmpcode,
      "clientcode": clientcode,
      "orders_data": [
        {
          "t_name": taskName.text,
          "t_from": userid,
          "t_to": selectedTo ?? "",
          "t_remarks": desc.text,
          "t_status": "1",
          "t_priority": "1",
          "order_details": [
            {
              "tt_from": userid,
              "tt_to": selectedTo ?? "",
              "tt_remarks": desc.text,
              "tt_status": "1",
              "tt_priority": "1",
            }
          ]
        }
      ]
    };
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        print("Response: ${response.body}");

        // Send notification after inserting data
      sendNotification(selectedTo ?? "", taskName.text);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task Inserted Successfully")),
        );
      } else {
        print("Failed to insert data. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }
  Future<void> sendNotification(String userId, String taskName) async {
  String apiUrl = "${uriname}send_notification.php";

  await http.post(Uri.parse(apiUrl), body: {
    "um_id": userId, // Sending um_id instead of um_username
    "message": "New Task Assigned: $taskName",
  });
}

  Future<void> fetchUsers() async {
    final url =
        Uri.parse("${uriname}task_select.php?clientcode=$clientcode&cmp=$cmpcode&flag=user");
    try {
      final response = await http.get(url);
      print("API Response: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);

        // Remove duplicates and null values
        Set<String> uniqueUserIds = {};
        List<Map<String, String>> fetchedUsers = jsonData
            .map((user) {
              String userId = user["um_id"]?.toString() ?? "";
              String userName = user["um_username"]?.toString() ?? "";
              if (userId.isNotEmpty && uniqueUserIds.add(userId)) {
                return {"um_id": userId, "um_username": userName};
              }
              return null;
            })
            .where((user) => user != null)
            .cast<Map<String, String>>()
            .toList();

        print("Fetched Users: $fetchedUsers");

        setState(() {
          users = fetchedUsers;
        });
      } else {
        throw Exception("Failed to load data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text("Insert Your Task"),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(10),
                child: DropdownButtonFormField<String>(
                  value: users.any((e) => e["um_id"] == selectedTo) ? selectedTo : null,
                  hint: const Text("Select To"),
                  items: users.map((user) {
                    return DropdownMenuItem<String>(
                      value: user["um_id"] ?? "",
                      child: Text(user["um_username"] ?? "Unknown"),
                    );
                  }).toList(),
                  onChanged: users.isNotEmpty
                      ? (value) {
                          setState(() {
                            selectedTo = value;
                          });
                        }
                      : null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Select To',
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(10),
                child: TextFormField(
                  controller: taskName,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter Your Task',
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(10),
                child: TextFormField(
                  controller: desc,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter Description',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Visibility(
                visible: true,
                child: Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      onPressed: () {
                        insertData();
                        setState(() {
                          taskName.clear();
                          desc.clear();
                          set_date.clear();
                          time.clear();
                          selectedFrom = null;
                          selectedTo = null;
                          selectedStatus = null;
                          selectedPriority = null;
                        });
                      },
                      child: const Text('Save'),
                       
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: () {
                    Navigator.of(context)
                        .pop(); // Navigate back to the previous screen
                  },
                    child: const Text('Cancel'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
