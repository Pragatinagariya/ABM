import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InsertItemPage extends StatefulWidget {
  const InsertItemPage({super.key});

  @override
  State<InsertItemPage> createState() => _InsertItemPageState();
}

class _InsertItemPageState extends State<InsertItemPage> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController rateController = TextEditingController();

  Future<void> insertItem() async {
    final response = await http.post(
      Uri.parse(
          "https://abm99.amisys.in/android/PHP/v2/insert_items.php?clientcode=6d099&cmp=hnf"),
      body: {
        'z_itemcode': codeController.text,
        'z_itemname': nameController.text,
        'z_remarks': remarksController.text,
        'z_rate': rateController.text,
      },
    );

    if (response.statusCode == 200) {
      Navigator.pop(context); // Go back to list page
    } else {
      print("Insert failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Item"), backgroundColor: Theme.of(context).primaryColor),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: codeController,
              decoration: InputDecoration(labelText: "Item Code"),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Item Name"),
            ),
            TextField(
              controller: remarksController,
              decoration: InputDecoration(labelText: "Remarks"),
            ),
            TextField(
              controller: rateController,
              decoration: InputDecoration(labelText: "Rate"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: insertItem,
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              child: Text("Submit"),
            )
          ],
        ),
      ),
    );
  }
}
