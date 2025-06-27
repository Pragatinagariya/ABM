import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart';
import 'insertitem.dart';

class ItemRead extends StatefulWidget {
  const ItemRead({super.key});

  @override
  State<ItemRead> createState() => _ItemReadState();
}

class _ItemReadState extends State<ItemRead> {
  List items = [];

  Future<void> fetchItems() async {
    final response = await http.get(Uri.parse(
        "https://abm99.amisys.in/android/PHP/v2/read_items.php?clientcode=6d099&cmp=hnf"));
    if (response.statusCode == 200) {
      setState(() {
        items = json.decode(response.body);
      });
    } else {
      print("Error fetching data");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Item List'), backgroundColor: Theme.of(context).primaryColor),
      body: items.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(item['z_itemname']),
                    subtitle: Text(
                        "Code: ${item['z_itemcode']}\nRate: ${item['z_rate']}"),
                    isThreeLine: true,
                    // trailing: Text(item['z_remarks']),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => InsertItemPage()),
            ).then((value) => fetchItems());
          },
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(Icons.add)),
    );
  }
}
