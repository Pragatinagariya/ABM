import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'AddItem.dart';
import 'globals.dart' as globals;
import 'package:intl/intl.dart';

class ChallanEdit extends StatefulWidget {
  final String omid;
  final String omdate;
  final String custname;
  final String agent;
  final String transport;
  final String clientcode;
  final String username;
  final String clientname;
  final String clientMap;
  final TextEditingController IdController;
  
  final TextEditingController DateController;
  final TextEditingController ChallanIdController;
  //  final TextEditingController TotalQtyController = TextEditingController();
  // final TextEditingController ItemsController = TextEditingController();
  // final TextEditingController AmtController = TextEditingController();
  final List<Map<String, dynamic>> orders;
 const ChallanEdit({
    required this.omid,
    required this.omdate,
    required this.custname,
    required this.agent,
    required this.transport,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
    required this.username,
    required this.orders,
    required this.IdController,
    required this.DateController,
    required this.ChallanIdController,
   
    super.key,
  });

  @override
  _ChallanEditState createState() => _ChallanEditState();
}

class _ChallanEditState extends State<ChallanEdit> {
  late String uri;
  List<dynamic> customers = [];
  List<dynamic> filteredCustomers = [];
  String? selectedCustomer;
  List<Map<String, dynamic>> orders = [];
  bool isDropdownOpen = false;

  List<dynamic> agents = [];
  List<dynamic> filteredAgents = [];
  String? selectedAgent;

  List<dynamic> transports = [];
  List<dynamic> filteredTransports = [];
  String? selectedTransport;
  List<dynamic> fetchedData = [];
  bool isLoading = true; // For showing loader
  String? errorMessage; // For showing error
  double totalAmount = 0.0; // Total amount
  int totalQuantity = 0; // Total quantity
  int totalItems = 0; // Total items

  void calculateTotals() {
    double amount = 0.0;
    int items = 0;
    int quantity = 0;

    for (var order in orders) {
      // Check and parse quantity
      int qty = int.tryParse(order['quantity']?.toString() ?? '0') ?? 0;
      double rate = double.tryParse(order['rate']?.toString() ?? '0') ?? 0;

      // Add to totals
      amount += rate * qty;
      quantity += qty;
      items++;
    }

    setState(() {
      totalAmount = amount;
      totalQuantity = quantity;
      totalItems = items;
    });
  }

  // Deduplicate agents based on the 'd_agentid' field
  List<Map<String, dynamic>> uniqueAgents = [];
  Set<String> seenIds = {};

  @override
  void initState() {
    super.initState();
    fetchCustomers();
    fetchAgents();
    fetchTransports();
    // _fetchOrderId();
    fetchOrderDetails();
    widget.DateController.text =
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    orders = widget.orders;
  }

  @override
  void dispose() {
    // Dispose controllers when widget is disposed
    widget.IdController.dispose();
    widget.DateController.dispose();
    super.dispose();
  }

  // String generateOrderNumber() {
  //   return 'ORD${DateTime.now().millisecondsSinceEpoch}';
  // }
Future<void> fetchOrderDetails() async {
  final url =
      '${globals.uriname}challan_view.php?om_id=${widget.omid}&clientcode=${globals.clientcode}&cmp=${globals.cmpcode}';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('Full response data: $data');

      if (data.isEmpty) {
        print('No data found.');
        return;
      }

      setState(() {
        customers = data.map((order) => {
              'AM_AccId': order['om_custid']?.toString() ?? '',
              'AM_AccName': order['CustName'] ?? 'Unknown',
            }).toList();
        selectedCustomer = customers.isNotEmpty ? customers[0]['AM_AccId'] : '';

        agents = data.map((order) => {
              'ID': order['om_agentid']?.toString() ?? '',
              'AgentName': order['AgentName'] ?? 'Unknown',
            }).toList();
        selectedAgent = agents.isNotEmpty ? agents[0]['ID'] : '';

        transports = data.map((order) => {
              'TransportID': order['om_transportid']?.toString() ?? '',
              'TransportName': order['om_transport'] ?? 'Unknown',
            }).toList();
        selectedTransport = transports.isNotEmpty
            ? transports[0]['TransportID']
            : '';

        widget.IdController.text = data[0]['om_orderno']?.toString() ?? '';
        widget.ChallanIdController.text = data[0]['om_invno']?.toString() ?? '';

        widget.DateController.text = data[0]['om_date']?.toString() ?? '';

        orders = data.map((order) => {
              'itemId': order['ot_itemid']?.toString() ?? '',
              'quantity': order['ot_invqty']?.toString() ?? '0',
              'rate': order['ot_rate']?.toString() ?? '0.0',
              'totalAmount': order['ot_subtotal']?.toString() ?? '0.00',
              'itemName': order['IM_ItemName'] ?? 'Unnamed Item',
            }).toList();

        int omQty = int.tryParse(data[0]['om_qty']?.toString() ?? '0') ?? 0;
        int otTotalQty = orders.isNotEmpty
            ? orders.fold(0, (sum, order) =>
                sum + (double.tryParse(order['quantity'].toString())?.toInt() ?? 0))
            : 0;

        totalQuantity += (omQty + otTotalQty);

        totalAmount += data.fold(
          0.0,
          (sum, order) =>
              sum + (double.tryParse(order['ot_subtotal'] ?? '0.00') ?? 0.0),
        );

        totalItems = orders.length;

        print('Updated Total Quantity: $totalQuantity');
        print('Updated Total Amount: $totalAmount');
        print('Total items: $totalItems');
      });
    } else {
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching data: $e');
  }
}

Future<void> updateOrderData() async {
  final url = Uri.parse('${globals.uriname}update_order_2.php');

  final payload = {
    "clientcode": globals.clientcode,
    "cmp": globals.cmpcode,
    "orders_data": [
      {
        "om_id":widget.omid,
        "om_invno": (int.tryParse(widget.ChallanIdController.text) ?? 0).toString(),
        "om_date": widget.DateController.text.isNotEmpty
            ? widget.DateController.text
            : DateTime.now().toIso8601String(),
        "om_custid": selectedCustomer?.toString() ?? '',
        "om_agentid": selectedAgent?.toString() ?? '',
        "om_transportid": selectedTransport?.toString() ?? '',
        "om_transport": transports.firstWhere(
          (transport) => transport['TransportID'] == selectedTransport,
          orElse: () => {'TransportName': 'Unknown'},
        )['TransportName'],
        "om_qty": totalQuantity.toString(),
        "om_billamt": totalAmount.toString(),
        "om_noofitems": totalItems.toString(),
        "order_details": orders.asMap().entries.map((entry) {
          int index = entry.key;
          var item = entry.value;
          return {
            "ot_srno": (index + 1).toString(),
            "ot_itemid": item['itemId']?.toString() ?? '',
            "ot_invqty": (int.tryParse(item['quantity']?.toString() ?? '0') ?? 0).toString(),
            "ot_rate": (double.tryParse(item['rate']?.toString() ?? '0.0') ?? 0.0).toString(),
            "ot_subtotal": (double.tryParse(item['totalAmount']?.toString() ?? '0.0') ?? 0.0).toString(),
          };
        }).toList(),
      }
    ]
  };

  print('Sending payload: ${json.encode(payload)}');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('Response Data: $responseData');
      if (responseData['status'] == 'success') {
        print('Order data successfully saved');
      } else {
        print('Server Error: ${responseData['message']}');
      }
    } else {
      print('HTTP Error: ${response.statusCode}');
    }
  } catch (error) {
    print('Network Error: $error');
  }
}

  Future<void> fetchCustomers() async {
    uri =
        "${globals.uriname}customer_list.php?clientcode=${globals.clientcode}&cmp=${globals.cmpcode}";
    try {
      final response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        setState(() {
          customers = json.decode(response.body);
          filteredCustomers = customers;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load customers. Please try again.';
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'An error occurred: $error';
        isLoading = false;
      });
    }
  }

  // fetchAgents with deduplication logic
  Future<void> fetchAgents() async {
    uri =
        "${globals.uriname}Agent_Name.php?clientcode=${globals.clientcode}&cmp=${globals.cmpcode}";
    try {
      final response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        setState(() {
          agents = json.decode(response.body);

          // Deduplicate agents based on 'd_agentid'
          uniqueAgents.clear();
          seenIds.clear();
          for (var agent in agents) {
            String agentId = agent['ID'].toString();
            if (!seenIds.contains(agentId)) {
              seenIds.add(agentId);
              uniqueAgents.add(agent);
            }
          }

          filteredAgents = uniqueAgents;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load agents. Please try again.';
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'An error occurred: $error';
        isLoading = false;
      });
    }
  }

  Future<void> fetchTransports() async {
    uri =
        "${globals.uriname}transport_list.php?clientcode=${globals.clientcode}&cmp=${globals.cmpcode}";
    try {
      final response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        final List<dynamic> rawTransports =
            json.decode(response.body); // Decode the JSON response

        setState(() {
          transports = rawTransports
              .where((transport) =>
                  transport['TransportID'] != null &&
                  transport['TransportName'] != null)
              .map((transport) {
            return {
              'TransportID': transport['TransportID'] ?? '',
              'TransportName':
                  transport['TransportName'] ?? 'Unknown Transport',
            };
          }).toList(); // Map the data to the appropriate fields

          filteredTransports =
              transports; // Set filtered list for search/filtering
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load transports. Please try again.';
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'An error occurred: $error';
        isLoading = false;
      });
    }
  }

  void openCustomerDropdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search Customer',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (query) {
                      // Update only modal state for better performance
                      setModalState(() {
                        filteredCustomers = customers
                            .where((customer) => customer['AM_AccName']
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        return ListTile(
                          title: Text(
                              customer['AM_AccName'] ?? 'Unknown Customer'),
                          onTap: () {
                            setState(() {
                              selectedCustomer =
                                  customer['AM_AccId']?.toString() ?? '';
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void openCustomerDropdownAgent(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search Agent',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (query) {
                      // Update only modal state for better performance
                      setModalState(() {
                        filteredAgents = agents
                            .where((agent) => agent['AgentName']
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredAgents.length,
                      itemBuilder: (context, index) {
                        final agent = filteredAgents[index];
                        return ListTile(
                          title: Text(agent['AgentName'] ?? 'agent'),
                          onTap: () {
                            setState(() {
                              selectedAgent = agent['ID']?.toString() ?? '';
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void openTransportDropdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search Transport',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (query) {
                      // Update only modal state for better performance
                      setModalState(() {
                        filteredTransports = transports
                            .where((transport) => transport['TransportName']
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredTransports.length,
                      itemBuilder: (context, index) {
                        final transport = filteredTransports[index];
                        return ListTile(
                          title:
                              Text(transport['TransportName'] ?? 'Transport'),
                          onTap: () {
                            setState(() {
                              selectedTransport =
                                  transport['TransportID']?.toString() ?? '';
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showEditDialog(int index) {
    final item = orders[index];
    final TextEditingController qtyController =
        TextEditingController(text: item['quantity']);
    final TextEditingController rateController =
        TextEditingController(text: item['rate']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateController,
                decoration: const InputDecoration(
                  labelText: 'Rate',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Update the item in the orders list
                setState(() {
                  orders[index]['quantity'] = qtyController.text;
                  orders[index]['rate'] = rateController.text;
                });

                // Recalculate totals
                calculateTotals();

                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void deleteItem(int index) {
    setState(() {
      orders.removeAt(index); // Remove the item from the list
    });

    // Recalculate totals after deletion
    calculateTotals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('Edit Challan'),
      ),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Date Fields
           Row(
  children: [
    // Order ID Field
    Expanded(
      flex: 1,
      child: TextField(
        controller: widget.ChallanIdController,
        decoration: const InputDecoration(
          labelText: 'Challan NO',
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
        ),
      ),
    ),
    const SizedBox(width: 16),
    // Order Date Field
    Expanded(
      flex: 2,
      child: TextField(
        controller: widget.DateController,
        decoration: const InputDecoration(
          labelText: 'Challan Date',
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
        ),
      ),
    ),
  ],
),
const SizedBox(height:10),
 Row(
  children: [
    // Order ID Field
    Expanded(
      flex: 1,
      child: TextField(
        controller: widget.IdController,
        decoration: const InputDecoration(
          labelText: 'Order NO',
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
        ),
      ),
    ),
    const SizedBox(width: 16),
    // Order Date Field
    Expanded(
      flex: 2,
      child: TextField(
        controller: widget.DateController,
        decoration: const InputDecoration(
          labelText: 'Order Date',
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
        ),
      ),
    ),
  ],
),


            const SizedBox(height: 17),
          GestureDetector(
  onTap: () => openCustomerDropdown(context),
  child: InputDecorator(
    decoration: InputDecoration(
      labelText: 'Select Customer',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: EdgeInsets.symmetric(
          horizontal: 12, vertical: 8), // Adjusts internal padding
    ),
    child: SizedBox(
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
    selectedCustomer != null
        ? customers.firstWhere(
            (customer) => customer['AM_AccId'] == selectedCustomer,
            orElse: () => {'AM_AccName': 'Select Customer'}
          )['AM_AccName'] ?? 'Select Customer'
        : 'Select Customer',
    style: const TextStyle(fontSize: 16),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    ),
  ),
),

            const SizedBox(height: 16),

            // Agent Dropdown

            GestureDetector(
              onTap: () => openCustomerDropdownAgent(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Select Agent',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8), // Adjusts internal padding
                ),
                child: SizedBox(
                  height: 18, // Adjust this value to your preferred height
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
    selectedAgent != null
        ? agents.firstWhere(
            (agent) => agent['ID'] == selectedAgent,
            orElse: () => {'AgentName': 'Select Agent'}
          )['AgentName'] ?? 'Select Agent'
        : 'Select Agent',
    style: const TextStyle(fontSize: 16),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
                height: 8), // Adjust this value for spacing between widgets

            // Agent Dropdown

            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => openTransportDropdown(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Select Transport',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: SizedBox(
                  height: 18,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child:Text(
    selectedTransport != null
        ? transports.firstWhere(
            (transport) => transport['TransportID'] == selectedTransport,
            orElse: () => {'TransportName': 'Select Transport'}
          )['TransportName'] ?? 'Select Transport'
        : 'Select Transport',
    style: const TextStyle(fontSize: 16),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  ),
                      ),
                      const Icon(
                          Icons.arrow_drop_down), // Keep Icon outside Flexible
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final updatedOrders = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemListPage(
                      username: widget.username,
                              clientcode: widget.clientcode,
                              clientname: widget.clientname,
                              clientMap: widget.clientMap,
                      orders: List.from(orders), // Pass a copy of the current orders
                      savedItems: List.from(orders),
                    
                    ),
                
                  ),
                );

               if (updatedOrders != null) {
                  setState(() {
                    orders = updatedOrders; // Update the orders list
                    calculateTotals();
                  });
                  calculateTotals();
                }
              },

              icon: const Icon(Icons.add), // Icon before the label
              label: const Text('Add Item'), // Button label
            ),

            const SizedBox(height: 8),
            orders.isEmpty
                ? const Text('No items added yet.')
                : Expanded(
                    child: ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final item = orders[index];
                        return Card(
                          margin: const EdgeInsets.all(3),
                          child: Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // First row: Image and Packaging
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Image
                                    GestureDetector(
                                      onTap: () {},
                                      child: SizedBox(
                                        width: 98,
                                        height: 110,
                                        child: Image.network(
                                          item["itemId"] != null &&
                                                  item["itemId"].isNotEmpty
                                              ? '${globals.uriname}${widget.username}/${widget.clientcode}/Images/Items/${item["itemId"]}_1.jpg'
                                              : 'assets/images/icons/00000000.jpg', // Fallback image
                                          fit: BoxFit
                                              .contain, // Adjust the image to fit the container
                                          errorBuilder: (BuildContext context,
                                              Object error,
                                              StackTrace? stackTrace) {
                                            return Image.asset(
                                              'assets/images/icons/00000000.jpg', // Your local fallback image
                                              fit: BoxFit.contain,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 1),

                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Packaging (Qty)
                                                // Quantity TextField
// Quantity TextField
// Quantity TextField
                                  TextField(
  controller: TextEditingController()
    ..text = (double.tryParse(item["quantity"]?.toString() ?? '0')?.toInt().toString() ?? '0'),
  decoration: const InputDecoration(
    hintText: 'Enter Quantity',
    border: UnderlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(vertical: 4),
  ),
  keyboardType: TextInputType.number,
  style: const TextStyle(fontSize: 13),
  onChanged: (value) {
    setState(() {
      final index = orders.indexOf(item);
      if (index != -1) {
        // Update the quantity
        int newQuantity = int.tryParse(value) ?? 0;
        orders[index]["quantity"] = newQuantity;

        // Ensure rate is valid and properly parsed as a double
        double rate = double.tryParse(orders[index]["rate"]?.toString() ?? '0.0') ?? 0.0;

        // Recalculate the totalAmount based on the new quantity and valid rate
        double newTotalAmount = newQuantity * rate;
        orders[index]["totalAmount"] = newTotalAmount;

        // Recalculate other totals (e.g., for the whole order)
        calculateTotals();
      }
    });
  },
),


                                                const SizedBox(height: 4),

                                               TextField(
  controller: TextEditingController.fromValue(
    TextEditingValue(
      text: item["rate"] != null ? item["rate"].toString() : '',
      selection: TextSelection.collapsed(


        offset: item["rate"] != null ? item["rate"].toString().length : 0,
      ),
    ),
  ),
  decoration: const InputDecoration(
    hintText: 'Enter Rate',
    border: UnderlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(vertical: 4),
  ),
  keyboardType: TextInputType.number,
  style: const TextStyle(fontSize: 13),
  onChanged: (value) {
    setState(() {
      // Update the item's quantity
      item["rate"] = int.tryParse(value) ?? 0;
 calculateTotals();
      // Recalculate the total amount for the item
      item["totalAmount"] = (item["quantity"] ?? 0) * (item["rate"] ?? 0);

      // Recalculate overall totals
      calculateTotals();
    });
  },
),

                                                const SizedBox(height: 2),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                              width:
                                                  9), // Space between columns
                                          // Second Column: Rate, Qty, Add to Cart button
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                // Calculated Price (Qty * Rate)
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    const Icon(
                                                      Icons.currency_rupee,
                                                      color: Colors.red,
                                                      size: 16,
                                                    ),
                                                    Text(
                                                      // Display totalAmount directly from the item map
                                                      '${item["totalAmount"] ?? "0.0"}', // Use "totalAmount" from the item map
                                                      style: const TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 14),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                // Update and Delete buttons
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    // Update button
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.edit,
                                                          color: Colors.black,
                                                          size: 18),
                                                      padding: const EdgeInsets
                                                          .only(
                                                          left:
                                                              40), // Smaller size
                                                      onPressed: () {
                                                        showEditDialog(
                                                            index); // Open the edit dialog
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                        size: 18,
                                                      ),
                                                      onPressed: () {
                                                        // Show confirmation dialog before deleting
                                                        showDialog(
                                                          context: context,
                                                          builder: (BuildContext
                                                              context) {
                                                            return AlertDialog(
                                                              title: const Text(
                                                                  'Confirm Delete'),
                                                              content: const Text(
                                                                  'Are you sure you want to delete this item?'),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.pop(
                                                                        context); // Close the dialog
                                                                  },
                                                                  child: const Text(
                                                                      'Cancel'),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed:
                                                                      () {
                                                                    deleteItem(
                                                                        index); // Delete the item
                                                                    Navigator.pop(
                                                                        context); // Close the dialog
                                                                  },
                                                                  child: const Text(
                                                                      'Delete'),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 0),
                                Text(
                                  item['itemName'] ?? 'Unnamed Item',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Qty: $totalQuantity', // Display total quantity
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Items: $totalItems', // Display total items
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    ' Amt: ${totalAmount.toStringAsFixed(2)}', // Display total amount
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
  child: ElevatedButton(
    onPressed: () async {
      // Show a loading indicator while saving the data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving order...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Call the saveOrderData function
      await updateOrderData();

      // Navigate back to the previous page with a result
      Navigator.pop(context, true); // true indicates data was updated

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order saved successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange, // Set the button background color to orange
      foregroundColor: Colors.black, // Set the text color to black
    ),
    child: const Text('Challan Order'),
  ),
),

              ],
            ),
          ],
        ),
      ),
    );
  }
}