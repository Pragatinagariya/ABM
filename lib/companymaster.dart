import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CompanyMaster extends StatefulWidget {
  final Map<String, dynamic>? companyData;
  const CompanyMaster({super.key, this.companyData});

  @override
  _CompanyMasterState createState() => _CompanyMasterState();
}

class _CompanyMasterState extends State<CompanyMaster> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController codeController = TextEditingController();
  final TextEditingController dbController = TextEditingController();
  final TextEditingController cmpcontroller = TextEditingController();

  List<Map<String, String>> clientList = [];
  String? selectedClientName;
  String? selectedClientId;

  String responseMessage = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchClients();
    codeController.addListener(updateCmpDb);
    if (widget.companyData != null) {
      codeController.text = widget.companyData!['cmp_code']?.toString() ?? '';
      cmpcontroller.text = widget.companyData!['cmp_name']?.toString() ?? '';
      dbController.text = widget.companyData!['cmp_db'].toString() ?? '';
      selectedClientName = widget.companyData!['cmp_name']?.toString();
      selectedClientId = widget.companyData!['cmp_clientid']?.toString();
    }
  }

 void updateCmpDb() {
  if (selectedClientId != null && codeController.text.trim().isNotEmpty) {
    final paddedId = selectedClientId!.padLeft(2, '0');
    final code = codeController.text.trim().toLowerCase();
    dbController.text = "6d0${paddedId}_$code";
  }
}

  Future<void> fetchClients() async {
    final url =
        Uri.parse('https://abm99.amisys.in/android/PHP/v2/fetchclientid.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'];

        setState(() {
          clientList = data
              .where((item) => item['cm_id'] != '0')
              .map<Map<String, String>>((item) => {
                    'id': item['cm_id'],
                    'code': item['cm_code'],
                    'name': item['cm_name'],
                  })
              .toList();

          // 👇 Match and update selectedClientName if it's available in the list
          if (widget.companyData != null) {
            final matchedClient = clientList.firstWhere(
              (client) =>
                  client['id'] ==
                  widget.companyData!['cmp_clientid']?.toString(),
              orElse: () => {},
            );

            if (matchedClient.isNotEmpty) {
              selectedClientName = matchedClient['name'];
              selectedClientId = matchedClient['id'];
            }
          }
        });
      }
    } catch (e) {
      print("Error fetching clients: $e");
    }
  }

  Future<void> submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final url =
        Uri.parse('https://abm99.amisys.in/android/PHP/v2/company_master.php');
    final String method = widget.companyData == null ? 'create' : 'update';
    final Map<String, dynamic> payload = {
      "method": method,
      "data": [
        {
          "cmp_id": widget.companyData?['cmp_id'],
          "cmp_code": codeController.text.trim(),
          "cmp_name": cmpcontroller.text.trim(),
          "cmp_clientid": selectedClientId ?? '',
          "cmp_db": dbController.text.trim()
        }
      ]
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );

      final jsonResponse = json.decode(response.body);
      print(jsonResponse);
      setState(() {
        responseMessage = jsonResponse['message'] ?? 'No message';
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseMessage)),
      );
    } catch (e) {
      setState(() {
        responseMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Widget buildInputField(
      String label, IconData icon, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget buildClientIdDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: selectedClientId,
        icon: Icon(Icons.arrow_drop_down),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.vpn_key),
          labelText: 'Select Client ID',
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: clientList
            .map((client) => DropdownMenuItem<String>(
                  value: client['id'],
                  child: Text(client['id'] ?? ''), // 👈 shows cm_id in dropdown
                ))
            .toList(),
        onChanged: (val) {
          setState(() {
            selectedClientId = val;
            updateCmpDb();
          });
        },
        validator: (val) =>
            val == null || val.isEmpty ? 'Please select client ID' : null,
      ),
    );
  }

  Widget buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: selectedClientName,
        icon: Icon(Icons.arrow_drop_down),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.business),
          labelText: 'Select Client',
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: clientList
            .map((client) => DropdownMenuItem<String>(
                  value: client['name'],
                  child: Text(client['name'] ?? ''),
                  onTap: () {
                    selectedClientId = client['id']; // store ID on selection
                    updateCmpDb();
                  },
                ))
            .toList(),
        onChanged: (val) {
          setState(() {
            selectedClientName = val;
          });
        },
        validator: (val) =>
            val == null || val.isEmpty ? 'Please select a client' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: Text('Company Master'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 10,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      'Insert Company Details',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800]),
                    ),
                    SizedBox(height: 20),
                    buildInputField(
                        "Cmp code", Icons.confirmation_number, codeController),
                    buildInputField(
                        "Cmp name", Icons.confirmation_number, cmpcontroller),
                    buildDropdownField(),
                    buildClientIdDropdown(),
                    SizedBox(height: 10),
                    buildInputField("Cmp db", Icons.storage, dbController),
                    SizedBox(height: 20),
                    isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: submitData,
                            icon: Icon(Icons.send),
                            label: Text('Submit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 30),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                    SizedBox(height: 15),
                    if (responseMessage.isNotEmpty)
                      Text(
                        responseMessage,
                        style:
                            TextStyle(fontSize: 14, color: Colors.blueAccent),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
