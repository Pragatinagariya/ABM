import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ABM2/companymaster.dart';

class CompanyMasterList extends StatefulWidget {
  const CompanyMasterList({super.key});

  @override
  _CompanyMasterListState createState() => _CompanyMasterListState();
}

class _CompanyMasterListState extends State<CompanyMasterList> {
  List<dynamic> company = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchCompany();
  }

  Future<void> fetchCompany() async {
    final url =
        Uri.parse("https://abm99.amisys.in/android/PHP/v2/company_master.php");
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({"method": "read"});

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            company = jsonData['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            error = "Server error: ${response.statusCode}";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = "Error: ${response.statusCode}";
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
        Uri.parse("https://abm99.amisys.in/android/PHP/v2/company_master.php");
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "method": "delete",
      "cmp_id": clientId, // Use cm_id for deletion
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final jsonData = jsonDecode(response.body);

      if (jsonData['status'] == 'success') {
        setState(() {
          company.removeAt(index); // ✅ remove from local list
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
        title: Text("Company list"),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: company.length,
                  itemBuilder: (context, index) {
                    final companys = company[index];
                    final cmName = (companys['cmp_name'] ?? '').toString();
                    final cmCode = (companys['cmp_code'] ?? '').toString();
                    final cmpDb = (companys['cmp_db'] ?? '').toString();
                    return Card(
                        margin: EdgeInsets.symmetric(),
                        elevation: 4,
                        child: ListTile(
                          title: Text(
                            cmName.isNotEmpty ? cmName : 'No Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "code: ${cmCode.isNotEmpty ? cmCode : 'N/A'}"),
                              Text(
                                  "dbname: ${cmpDb.isNotEmpty ? cmpDb : 'N/A'}"),
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
                                companys['cmp_id'].toString(),
                                index), // Pass cm_id here
                          ),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CompanyMaster(companyData: companys),
                              ),
                            );
                            if (result == true) {
                              fetchCompany();
                            }
                          },
                        ));
                  }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CompanyMaster()),
          );
          if (result == true) {
            fetchCompany();
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        tooltip: 'ADD COMPANY',
        child: Icon(Icons.add),
      ),
    );
  }
}
