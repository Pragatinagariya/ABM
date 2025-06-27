import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ClientMaster extends StatefulWidget {
  final Map<String, dynamic>? clientData;

  const ClientMaster({super.key, this.clientData});

  @override
  _ClientMasterState createState() => _ClientMasterState();
}

class _ClientMasterState extends State<ClientMaster> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController idController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController maxUsersController = TextEditingController();

  String responseMessage = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.clientData != null) {
      idController.text = widget.clientData!['cm_id']?.toString() ?? '';
      codeController.text = widget.clientData!['cm_code'] ?? '';
      nameController.text = widget.clientData!['cm_name'] ?? '';
      maxUsersController.text =
          widget.clientData!['cm_maxusers']?.toString() ?? '';
    }
  }

  Future<void> submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final url =
        Uri.parse('https://abm99.amisys.in/android/PHP/v2/clientmaster.php');

    // Determine whether we're creating or updating based on the presence of clientData
    final String method = widget.clientData == null ? 'create' : 'update';

    final Map<String, dynamic> payload = {
      "method": method,
      "data": [
        {
          "cm_id": idController.text.trim(),
          "cm_code": codeController.text.trim(),
          "cm_name": nameController.text.trim(),
          "cm_maxusers": maxUsersController.text.trim()
        }
      ]
    };

    // Debugging: Print the payload to check if 'method' is present
    print(json.encode(payload)); // Log the payload for debugging

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );

      final jsonResponse = json.decode(response.body);

      // Debugging: Print the response to see if there's any issue from the backend
      print('Response from server: $jsonResponse');

      setState(() {
        responseMessage = jsonResponse['message'] ?? 'No message';
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseMessage)),
      );

      if (jsonResponse['status'] == 'success') {
        Navigator.pop(context, true); // Return true on success
      }
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.clientData != null;

    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Client' : 'New Client'),
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
                      isEditing
                          ? 'Edit Client Details'
                          : 'Insert Client Details',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800]),
                    ),
                    SizedBox(height: 20),
                    buildInputField(
                        "Client ID", Icons.confirmation_number, idController,
                        type: TextInputType.number),
                    buildInputField("Client Code", Icons.code, codeController),
                    buildInputField(
                        "Client Name", Icons.person, nameController),
                    buildInputField(
                        "Max Users", Icons.group, maxUsersController,
                        type: TextInputType.number),
                    SizedBox(height: 20),
                    isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: submitData,
                            icon: Icon(Icons.save),
                            label: Text(isEditing ? 'Update' : 'Submit'),
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
