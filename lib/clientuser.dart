import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ClientUser extends StatefulWidget {
  final Map<String, dynamic>? companyData;
  const ClientUser({super.key, this.companyData});

  @override
  _ClientUserState createState() => _ClientUserState();
}

class _ClientUserState extends State<ClientUser> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController pwdController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  List<Map<String, String>> clientList = [];
  String? selectedUserType;
  String? selectedClientId;
  String responseMessage = '';
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    fetchClients(); // 👈 this is necessary to load the dropdown data
    if (widget.companyData != null) {
      nameController.text = widget.companyData!['cu_name']?.toString() ?? '';
      usernameController.text =
          widget.companyData!['cu_username']?.toString() ?? '';
      pwdController.text = widget.companyData!['cu_pwd'].toString() ?? '';
      mobileController.text = widget.companyData!['cu_mobile'];
      emailController.text = widget.companyData!['cu_email'];
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
              .where((item) => item['cm_id'] != '0') // Ignore default record
              .map<Map<String, String>>((item) => {
                    'id': item['cm_id'],
                    'code': item['cm_code'],
                    'name': item['cm_name'],
                  })
              .toList();
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
        Uri.parse('https://abm99.amisys.in/android/PHP/v2/clientuser.php');
    final String method = widget.companyData == null ? 'create' : 'update';

    final Map<String, dynamic> payload = {
      "method":
          method, // ✅ Make sure backend expects lowercase, or change to uppercase if needed
      "data": [
        {
          "cu_id": widget.companyData?['cu_id'],
          "cu_name": nameController.text.trim(),
          "cu_username": usernameController.text.trim(),
          "cu_pwd": pwdController.text.trim(),
          "cu_mobile": mobileController.text.trim(),
          "cu_email": emailController.text.trim(),
          "cu_usertype": selectedUserType ?? '',
          "cu_clientid": selectedClientId ?? '',
        }
      ]
    };

    try {
      // Debug log to check what’s being sent
      print("Submitting payload: ${json.encode(payload)}");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );

      // Debug log to check response
      print("Server response: ${response.body}");

      final jsonResponse = json.decode(response.body);

      setState(() {
        responseMessage = jsonResponse['message'] ?? 'No message received';
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
      print("Error submitting data: $e");
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
                  child:
                      Text(client['name'] ?? ''), // 👈 shows cm_id in dropdown
                ))
            .toList(),
        onChanged: (val) {
          setState(() {
            selectedClientId = val;
          });
        },
        validator: (val) =>
            val == null || val.isEmpty ? 'Please select client ID' : null,
      ),
    );
  }

  Widget buildUserTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: selectedUserType,
        icon: Icon(Icons.arrow_drop_down),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.person),
          labelText: 'Select User Type',
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: ['User', 'Admin']
            .map((type) => DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                ))
            .toList(),
        onChanged: (val) {
          setState(() {
            selectedUserType = val;
          });
        },
        validator: (val) =>
            val == null || val.isEmpty ? 'Please select user type' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: Text('Client Master'),
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
                      'Insert Client Details',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800]),
                    ),
                    SizedBox(height: 20),
                    buildInputField("ClientName", Icons.confirmation_number,
                        nameController),
                    buildInputField("Username", Icons.code, usernameController),
                    buildInputField("Password", Icons.person, pwdController),
                    buildInputField("Mobile", Icons.group, mobileController,
                        type: TextInputType.number),
                    buildInputField(
                      "Email",
                      Icons.group,
                      emailController,
                    ),
                    buildUserTypeDropdown(),
                    buildClientIdDropdown(),
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
