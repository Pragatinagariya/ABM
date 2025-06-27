import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'clientmaster.dart';

class ClientListPage extends StatefulWidget {
  const ClientListPage({super.key});

  @override
  _ClientListPageState createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  List<dynamic> clients = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  Future<void> fetchClients() async {
    final url =
        Uri.parse("https://abm99.amisys.in/android/PHP/v2/clientmaster.php");
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({"method": "read"});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            clients = jsonData['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            error = jsonData['message'];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = "Server error: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error: $e";
        isLoading = false;
      });
    }
  }

  Future<void> deleteClient(String clientId, int index) async {
    final url =
        Uri.parse("https://abm99.amisys.in/android/PHP/v2/clientmaster.php");
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "method": "delete",
      "cm_id": clientId, // Use cm_id for deletion
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final jsonData = jsonDecode(response.body);

      if (jsonData['status'] == 'success') {
        setState(() {
          clients.removeAt(index); // ✅ remove from local list
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Client deleted successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete: ${jsonData['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _confirmDelete(String clientId, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to delete this client?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteClient(clientId, index); // ✅ pass clientId (cm_id)
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Client Master List"),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    final cmName = (client['cm_name'] ?? '').toString().trim();
                    final cmCode = (client['cm_code'] ?? '').toString().trim();
                    final cmMaxUsers =
                        (client['cm_maxusers'] ?? '').toString().trim();

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      child: ListTile(
                        title: Text(
                          cmName.isNotEmpty ? cmName : 'No Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Code: ${cmCode.isNotEmpty ? cmCode : 'N/A'}"),
                            Text(
                                "Max Users: ${cmMaxUsers.isNotEmpty ? cmMaxUsers : 'N/A'}"),
                          ],
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Text(
                            cmName.isNotEmpty ? cmName[0] : '?',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(
                              client['cm_id'].toString(),
                              index), // Pass cm_id here
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ClientMaster(clientData: client),
                            ),
                          );
                          if (result == true) {
                            fetchClients();
                          }
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ClientMaster()),
          );
          if (result == true) {
            fetchClients();
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        tooltip: 'Add New Client',
        child: Icon(Icons.add),
      ),
    );
  }
}
