import 'package:ABM2/globals.dart';
import 'package:flutter/material.dart';
import 'orderItem.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
class Itemwiseorder extends StatefulWidget {
  final String clientcode;
  final String username;
  final String clientname;
  final String clientMap;
  final List<Map<String, dynamic>> orders;

  const Itemwiseorder({
    required this.clientcode,
    required this.username,
    required this.clientname,
    required this.clientMap,
    required this.orders,
    super.key,
  });

  @override
  _ItemwiseorderState createState() => _ItemwiseorderState();
}

class _ItemwiseorderState extends State<Itemwiseorder> {
  List<Map<String, dynamic>> selectedItems = []; // Store selected items
  
Future<List<Map<String, dynamic>>> fetchOrderDetails(String itemId) async {
  final url = "${uriname}item_wise_detail.php?clientcode=$clientcode&cmp=$cmpcode&item_id=$itemId";
  print('Fetching data from: $url');  // Debugging log
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    print('API Response: $data'); // Print the response for debugging
    return List<Map<String, dynamic>>.from(data);
  } else {
    throw Exception("Failed to load order details");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Item List"),
        backgroundColor: themeColor,
      ),
      body: Column(
        children: [
          // Horizontal Scroll View for selected items
          if (selectedItems.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: selectedItems.map((item) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            height: 90,
            width: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                     
                                         ),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['imageUrl'] ?? 'https://via.placeholder.com/60',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/icons/00000000.jpg', // Default image
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['itemName'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        Positioned(
                          top: -20,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                            padding: const EdgeInsets.all(0),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                selectedItems.removeWhere((savedItem) => savedItem['itemId'] == item['itemId']);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // List of selected items
          Expanded(
  child: selectedItems.isEmpty
      ? const Center(child: Text("No items selected"))
      : ListView.builder(
          itemCount: selectedItems.length,
          itemBuilder: (context, index) {
            final item = selectedItems[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left side: Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '$uriname${widget.username}/${widget.clientcode}/Images/Items/${item["IM_ItemId"]}_1.jpg',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/icons/00000000.jpg', // Default image
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10), // Spacing

                        // Right side: Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['itemName'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10), // Spacing

                    // Table for item-wise order details
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchOrderDetails(item["itemId"]), 
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return const Center(child: Text("Error fetching data"));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text("No order details available"));
                        }
String formatDate(String date) {
  try {
    DateTime parsedDate = DateTime.parse(date); // Parse input date
    return DateFormat("dd-MM-yy").format(parsedDate); // Format to "25-03-03"
  } catch (e) {
    return "Invalid Date"; // Handle parsing errors
  }
}
                       return DataTable(
  columnSpacing: 5, // Reduce spacing between columns for a compact look
  dataRowHeight: 35, // Row height
  headingRowHeight: 40, // Header height
  columns: const [
    DataColumn(label: Text("No", style: TextStyle(fontSize: 10))),
    DataColumn(label: Text("Date", style: TextStyle(fontSize: 10))),
    DataColumn(label: Text("Customer", style: TextStyle(fontSize: 10))),
    DataColumn(label: Text("Qty", style: TextStyle(fontSize: 10))),
    DataColumn(label: Text("Rate", style: TextStyle(fontSize: 10))),
  ],
  rows: snapshot.data!.map((order) {
    return DataRow(cells: [
      DataCell(
        SizedBox(
          width: 20, // Set a fixed width for compact layout
          child: Text(
            order["OrderNo"].toString(),
            style: TextStyle(fontSize: 11),
            textAlign: TextAlign.left, // Align text to left
            overflow: TextOverflow.ellipsis, // Handle long numbers
          ),
        ),
      ), // Column 1

      DataCell(Text(
        formatDate(order["OrderDate"].toString()), // Format date
        style: TextStyle(fontSize: 11),
      )), // Column 2

      DataCell(
        SizedBox(
          width: 150, // Set a width constraint
          child: Text(
            order["CustomerName"] ?? "N/A",
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(fontSize: 11),
          ),
        ),
      ), // Column 3

      DataCell(Text(
        double.parse(order["Quantity"].toString()).toInt().toString(), // Remove decimal
        style: TextStyle(fontSize: 11),
      )), // Column 4

      DataCell(Text(
        order["Rate"].toString(),
        style: TextStyle(fontSize: 11),
        textAlign: TextAlign.center, // Align text to left
      )), // Column 5
    ]);
  }).toList(),
);

                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
),

        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderListPage(
                username: widget.username,
                clientcode: widget.clientcode,
                clientname: widget.clientname,
                clientMap: widget.clientMap,
                orders: List.from(widget.orders),
                savedItems: selectedItems, // Pass selected items
              ),
            ),
          );

          if (result != null && result is List<Map<String, dynamic>>) {
            setState(() {
              selectedItems = result; // Update with selected items
            });
          }
        },
        backgroundColor:themeColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
