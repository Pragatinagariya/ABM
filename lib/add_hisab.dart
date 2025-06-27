import 'dart:convert';
import 'package:ABM2/globals.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddHisab extends StatefulWidget {
  const AddHisab({super.key});

  @override
  State<AddHisab> createState() => _AddHisabState();
}

class _AddHisabState extends State<AddHisab> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController dateController = TextEditingController();
  TextEditingController purposeController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController typeController = TextEditingController();
  TextEditingController remarksController = TextEditingController();

  Future<void> createHisabEntry() async {
    final url = Uri.parse(
        'https://abm99.amisys.in/android/PHP/v2/hisab.php?clientcode=$clientcode&cmp=$cmpcode');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "method": "create",
        "data": [
          {
            "entry_date": dateController.text,
            "purpose": purposeController.text,
            "amount": amountController.text,
            "type": typeController.text, // "Expense" or "Received"
            "remarks": remarksController.text,
          }
        ]
      }),
    );

    final result = jsonDecode(response.body);
    if (result["status"] == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Entry added successfully")),
      );
      Navigator.pop(context); // Go back after success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${result["message"]}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hisab List"),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: dateController,
                decoration:
                    InputDecoration(labelText: 'Entry Date (YYYY-MM-DD)'),
              ),
              TextFormField(
                controller: purposeController,
                decoration: InputDecoration(labelText: 'Purpose'),
              ),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                value:
                    typeController.text.isNotEmpty ? typeController.text : null,
                decoration: InputDecoration(labelText: 'Type'),
                items: ['Received', 'Expense'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    typeController.text = newValue!;
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select a type'
                    : null,
              ),
              TextFormField(
                controller: remarksController,
                decoration: InputDecoration(labelText: 'Remarks'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: createHisabEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: Text('Submit'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
