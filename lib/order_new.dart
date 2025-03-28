// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'AddItem.dart';
import 'globals.dart' as globals;
import 'package:intl/intl.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'customerdetails.dart';
import 'customerdetails_edit.dart';
class OrderNew extends StatefulWidget {
   final String omid;
   final String cmpcode;
  final String clientcode;
  final String username;
  final String clientname;
  final String clientMap;
  final bool isApproveDisabled; 
  final TextEditingController IdController;
  final TextEditingController DateController;
  // final TextEditingController CustRefController;
  final List<Map<String, dynamic>> orders;
  final String flag;
  final String omQty;
  final String omPendingQty;
  
  const OrderNew({
    required this.omid,
    required this.clientcode,
    required this.username,
    required this.clientname,
    required this.clientMap,
    required this.orders,
    required this.cmpcode,
    required this.IdController,
    required this.DateController,
    required this.flag,
    required this.omQty,
    required this.omPendingQty,
    required this.isApproveDisabled,
    // required this.CustRefController,
    super.key,
  });

  @override
  _OrderNewState createState() => _OrderNewState();
  
}


class _OrderNewState extends State<OrderNew> {
  late String uri;
  
  List<dynamic> customers = [];
  List<dynamic> filteredCustomers = [];
  String? selectedCustomer;
  List<Map<String, dynamic>> orders = [];
  bool isDropdownOpen = false;
  double itemTotalAmount = 0.0;
  List<dynamic> agents = [];
  List<dynamic> filteredAgents = [];
  String? selectedAgent;
  List<dynamic> transports = [];
  List<dynamic> filteredTransports = [];
  String? selectedTransport;

  bool isLoading = true; // For showing loader
  String? errorMessage; // For showing error
  double totalAmount = 0.0; // Total amount
  int totalQuantity = 0; // Total quantity
  int totalItems = 0; // Total items
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController custrefController = TextEditingController();
  final TextEditingController custTypeController = TextEditingController();
  Map<String, String>? customerDetails;
  

   // ignore: non_constant_identifier_names

   String getrate2(var item) {
//  var item;
    String  x1='';
    if ( custTypeController.text == 'W' ) 
    {
        if (item["rate"] == null || item["rate"]== 0)
        x1 = '';
        else
        x1 = (double.tryParse(item["rate"].toString())?.toStringAsFixed(0) ?? '');
      
    }
    else if ( custTypeController.text == 'R' ) 
    {
        if (item["rate2"] == null || item["rate2"]== 0)
        x1 = '';
        else
        x1 = (double.tryParse(item["rate2"].toString())?.toStringAsFixed(0) ?? '');
      
    }
    return (x1);
   }

    int getrate3(var item) {
//  var item;
    int  x1=0;
    if ( custTypeController.text == 'W' ) 
    {
        x1=(double.tryParse(item["rate"].toString())?.toStringAsFixed(0).length ?? 0);
    }
    else if ( custTypeController.text == 'R' ) 
    {
        x1=(double.tryParse(item["rate2"].toString())?.toStringAsFixed(0).length ?? 0);
    }
    return (x1);
   }
void calculateTotals() {
  double amount = 0.0; // Initialize total amount
  int items = 0; // Initialize total items count
  int quantity = 0; // Initialize total quantity count

  // Loop through the orders and calculate the totals
  for (var order in orders) {
    // Safely parse quantity as double and rate as double
    double qty = double.tryParse(order['quantity']?.toString() ?? '0') ?? 0;
    double rate = double.tryParse(order['rate']?.toString() ?? '0') ?? 0;

    // Print the values for debugging
    print("Processing Order: $order");
    print("Quantity: $qty, Rate: $rate");

    // Calculate total amount and quantity
    amount += rate * qty;
    quantity += qty.toInt();  // Convert quantity to int if needed for total quantity calculation

    // Increment items count only if the quantity is non-zero
    if (qty > 0) {
      items++;
    }

    // Debugging print for the totals after processing each order
    print("Interim Amount: $amount, Interim Quantity: $quantity, Interim Items: $items");
  }

  // Update state with the calculated totals
  setState(() {
    totalAmount = amount;
    totalQuantity = quantity;
    totalItems = items;
  });

  // Debugging print for the final totals
  print("Final Totals -> Amount: $totalAmount, Quantity: $totalQuantity, Items: $totalItems");
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
   
    widget.DateController.text =
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    orders = widget.orders;
    if (widget.flag == 'Edit') {
      fetchOrderDetails().then((_) {
        setState(() {
          isLoading = false;
        });
      });
    } else {
      isLoading = false; // Directly show form for 'new' flag
       _fetchOrderId();
    }
     
  }

  @override
  void dispose() {
    // Dispose controllers when widget is disposed
    widget.IdController.dispose();
    _quantityController.dispose();
    widget.DateController.dispose();
     custrefController.dispose();
   
    super.dispose();
  }

  String generateOrderNumber() {
    return 'ORD${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _fetchOrderId() async {
    String uri =
        "${globals.uriname}orders_get_order_no.php?clientcode=${globals.clientcode}&cmp=${globals.cmpcode}";
print(uri);
    try {
      final response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          String orderNo = jsonResponse['orderno'].toString();
          widget.IdController.text = orderNo;
          setState(() {});
        } else {
          print('Error: ${jsonResponse['message']}');
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Request error: $e');
    }
  }

 Future<void> saveOrderData() async {
  if (selectedCustomer == null || selectedCustomer.toString().isEmpty) {
    print('Error: Please select a customer');
    return; // Stop execution if no customer is selected
  }

  // Validate Orders Data (Order Details)
  if (orders.isEmpty) {
    print('Error: Order details are empty');
    return; // Stop execution if no order details exist
  }
  final url = Uri.parse('${globals.uriname}order_save.php');

  final payload = {
    "clientcode": globals.clientcode,
    "cmp": globals.cmpcode,
    "orders_data": [
      {
        "om_invno": (int.tryParse(widget.IdController.text) ?? 0).toString(),
        "om_date": widget.DateController.text.isNotEmpty
            ? widget.DateController.text
            : DateTime.now().toIso8601String(),
        "om_custrefno": (int.tryParse(custrefController.text) ?? 0).toString(),  // Use custrefController here
        "om_custrefdate": widget.DateController.text.isNotEmpty
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
         "om_deliveryat": customerDetails?['deliveryAt'] ?? '',
         "om_remarks" :customerDetails?['remarks'] ?? '',
        "om_transportremarks": customerDetails?['transportRemarks'] ?? '',
        "om_paymentterms": customerDetails?['paymentTerms'] ?? '',
        "om_deliveryterms": customerDetails?['deliveryTerms'] ?? '',
        "order_details": orders.asMap().entries.map((entry) {
          int index = entry.key;
          var item = entry.value;
          return {
            "ot_srno": (index + 1).toString(),
            "ot_itemid": item['itemId']?.toString() ?? '',
            "ot_invqty": (int.tryParse(item['quantity']?.toString() ?? '0') ?? 0).toString(),
            "ot_rate": (double.tryParse(item['rate']?.toString() ?? '0.0') ?? 0.0).toString(),
            "ot_subtotal": (double.tryParse(item['subtotal']?.toString() ?? '0.0') ?? 0.0).toString(),
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
        print(uri);
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

  Future<void> fetchCustomerDetails(int custId, String clientCode, String username) async {
  final Uri url = Uri.parse(
    '${globals.uriname}customer_get_agent.php?clientcode=${globals.clientcode}&cmp=${globals.cmpcode}&custid=$custId',
  );

  print('Fetching details with URL: $url');

  try {
    final response = await http.get(url);

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('Decoded data: $data');

      if (data.isNotEmpty && data[0]['Status'] == 'True') {
        print('Customer Type: ${data[0]['CustType']}');

        setState(() {
          final String? custType = data[0]['CustType']?.toString();
          if (custType != null) {
            if (custType == 'WholeSale') {
              custTypeController.text = 'W';
            } else if (custType == 'Retailer') {
              custTypeController.text = 'R';
            }
          } else {
            print('CustType is null');
          }

          // Handle agent details
          final String? fetchedAgentId = data[0]['CustAgentId']?.toString();
          final String? fetchedAgentName = data[0]['CustAgent'];

          if (fetchedAgentId != null && fetchedAgentId != '0') {
            selectedAgent = fetchedAgentId;
            final fetchedAgent = {
              'ID': fetchedAgentId,
              'AgentName': fetchedAgentName ?? 'Unknown Agent'
            };
            if (!agents.any((agent) => agent['ID'] == fetchedAgentId)) {
              agents.add(fetchedAgent);
            }
          } else {
            selectedAgent = null;
          }

          // Handle transport details
          final String? fetchedTransportId = data[0]['CustTransportId']?.toString();
          final String? fetchedTransportName = data[0]['CustTransport'];

          if (fetchedTransportId != null && fetchedTransportId != '0') {
            selectedTransport = fetchedTransportId;
            final fetchedTransport = {
              'ID': fetchedTransportId,
              'TransportName': fetchedTransportName ?? 'Unknown Transport'
            };
            if (!transports.any((transport) => transport['ID'] == fetchedTransportId)) {
              transports.add(fetchedTransport);
            }
          } else {
            selectedTransport = null;
          }

          // Update filtered lists for UI
          filteredAgents = agents;
          filteredTransports = transports;

          print('Agents list after updating: $agents');
          print('Transports list after updating: $transports');
        });
      } else {
        print('Error message: ${data[0]['ErrorMsg']}');
        showError(data[0]['ErrorMsg'] ?? 'Customer not found.');
      }
    } else {
      showError('Failed to fetch data. Status code: ${response.statusCode}');
    }
  } catch (e) {
    showError('Error: $e');
    print('Exception: $e');
  }
}
  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void openCustomerDropdown(BuildContext context) {
    FocusNode searchFocusNode = FocusNode(); // Define FocusNode
                                        // Request focus after a small delay to ensure dialog renders first
                                         WidgetsBinding.instance.addPostFrameCallback((_) {
                                         searchFocusNode.requestFocus();
                                         });

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
                    focusNode: searchFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'Search Customer',
                      
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    
                    onChanged: (query) {
                      setModalState(() {
                        filteredCustomers = customers
                            .where((customer) => (customer['AM_AccName'] ?? '')
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        return ListTile(
                          title: Text(
                            customer['AM_AccName'] ?? 'Unknown Customer',
                          ),
                          onTap: () async {
                            setState(() {
                              selectedCustomer =
                                  customer['AM_AccId']?.toString() ?? '';
                            });

                            print('Selected Customer: $selectedCustomer');

                            // Fetch agent and transport details

                            await fetchCustomerDetails(
                                int.parse(
                                    selectedCustomer!), // Assuming AM_AccId is an integer
                                widget
                                    .clientcode, // Replace with the actual clientCode variable
                                widget
                                    .username // Replace with the actual username variable
                                );
                            await fetchAgents();
                            await fetchTransports();
                            // Close the modal after selection
                            Navigator.pop(context);
                            // fetchAgentAndTransport(widget.username,widget.clientcode,selectedCustomer!);
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
    FocusNode searchFocusNode = FocusNode(); // Define FocusNode
                                        // Request focus after a small delay to ensure dialog renders first
                                         WidgetsBinding.instance.addPostFrameCallback((_) {
                                         searchFocusNode.requestFocus();
                                         });
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
                    focusNode:searchFocusNode,
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
    FocusNode searchFocusNode = FocusNode(); // Define FocusNode
                                        // Request focus after a small delay to ensure dialog renders first
                                         WidgetsBinding.instance.addPostFrameCallback((_) {
                                         searchFocusNode.requestFocus();
                                         });
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
                    focusNode:searchFocusNode,
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

Future<void> fetchOrderDetails() async {
  print('Fetching details for Order ID: ${widget.omid}');
  final url =
      '${globals.uriname}order_by_id.php?om_id=${widget.omid}&clientcode=${globals.clientcode}&cmp=${globals.cmpcode}';

  try {
    print('Fetching URL: $url');

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print('Raw response body: ${response.body}');
      
      final List<dynamic> data = json.decode(response.body);
      print('Full response data: $data');

      if (data.isEmpty) {
        print('No data found.');
        return;
      }

      setState(() {
        print('Om Invoice No: ${data[0]['om_invno']}');
        print('Om Date: ${data[0]['om_date']}');

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

        // Assign values to controllers safely
        widget.IdController.text = data[0]['om_invno']?.toString() ?? '';
        custrefController.text = data[0]['om_custrefno']?.toString() ?? '';
        widget.DateController.text = data[0]['om_custrefdate']?.toString() ?? '';
        widget.DateController.text = data[0]['om_date']?.toString() ?? '';
        custTypeController.text = (data[0]['AM_CustType']?.toString() == "Retailer") 
        ? "R" 
        : (data[0]['AM_CustType']?.toString() == "WholeSale") 
        ? "W" 
        : data[0]['AM_CustType']?.toString() ?? '';



        orders = data.map((order) => {
              'itemId': order['ot_itemid']?.toString() ?? '',
              'quantity': order['ot_invqty']?.toString() ?? '0',
              'rate': order['ot_rate']?.toString() ?? '0.0',
              'rate2':order['ot_rate']?.toString()?? '0.0',
              'subtotal': order['ot_subtotal']?.toString() ?? '0.00',
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

Future<bool> approveOrderData() async {
  final url = Uri.parse('${globals.uriname}order_update_approval_status.php');
  
  try {
    // print("Client Code: $clientcode");
    // print("Username: $username");
    // print("Order ID: $orderId");

    print("API URL: $url");  // Debug: Ensure URL is correct

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      
      body: jsonEncode({
        "clientcode": globals.clientcode,  // Correct parameter usage
        "cmp": globals.cmpcode,
        "om_id": widget.omid,
        "om_verify": 1,
        "om_verifyby": globals.userid,
        "om_date": DateTime.now().toIso8601String(),
      }),
    );
    
    print("Response Status Code: ${response.statusCode}");  // Debug: Status code
    print("Response Body: ${response.body}");  // Debug: Response body

    final responseData = json.decode(response.body);

    if (response.statusCode == 200 && responseData["status"] == "success") {
      print("✅ Order Approved: ${responseData["message"]}");
      return true;  // Success
    } else {
      print("❌ Error Approving Order: ${responseData["message"]}");
      return false;  // Failure
    }
  } catch (e) {
    print("❌ Network Error: $e");
    return false;  // Failure
  }
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

  Future<void> fetchItemData(String barcode, BuildContext context) async {
    final String apiUrl = '${globals.uriname}barcode.php';

    Map<String, String> body = {
      "clientcode": globals.clientcode,
      "cmp":globals.cmpcode,
      "barcode": barcode,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );

      print("Raw API Response: ${response.body}");

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);

        if (result['status'] == 'success') {
          // Extract fields and handle missing fields gracefully
          String itemName = result['IM_name'] ?? "Unknown Item";
          String itemId = result['IM_id'] ?? "Unknown ID";
          double itemRate = double.tryParse(result['IM_SRate1'] ?? '1.0') ??
              1.0; // Extract rate
          int itemQuantity = 1; // Default quantity

          // Ensure itemTotalAmount is calculated correctly
          double itemTotalAmount = itemRate * itemQuantity;

          // Update the orders list
          setState(() {
            orders.add({
              "itemName": itemName,
              "quantity": "$itemQuantity", // Default quantity as string
              "rate": "$itemRate", // Item rate as string
              "itemId": itemId,
              "totalAmount": itemTotalAmount
                  .toString(), // Ensure totalAmount is calculated and stored correctly
            });
          });

          calculateTotals(); // Call function to recalculate totals

          // Show success message
          showSnackBar(context, 'Item added: $itemName');
        } else {
          // Handle error status
          showSnackBar(context,
              'Error: ${result['message'] ?? "Unexpected response from server."}');
        }
      } else {
        // Handle HTTP errors
        showSnackBar(context,
            'Failed to load data. HTTP Status: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any unexpected errors
      print("Error occurred: $e");
      showSnackBar(context, 'An error occurred: $e');
    }
  }

// Helper function to show a SnackBar
  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }
  Future<void> updateOrderData() async {
  if (selectedCustomer == null || selectedCustomer.toString().isEmpty) {
    print('Error: Please select a customer');
    return; // Stop execution if no customer is selected
  }

  // Validate Orders Data (Order Details)
  if (orders.isEmpty) {
    print('Error: Order details are empty');
    return; // Stop execution if no order details exist
  }
  final url = Uri.parse('${globals.uriname}order_update.php');
print(url);
  final payload = {
   "clientcode": globals.clientcode,  // Ensure correct client code
  "cmp": globals.cmpcode, 
  //  "${uriname}order_master_2.php?clientcode=${clientcode}&cmpcode=${cmpcode}";
    "orders_data": [
      {
         "om_id":widget.omid,
         
        "om_invno": (int.tryParse(widget.IdController.text) ?? 0).toString(),
        "om_date": widget.DateController.text.isNotEmpty
            ? widget.DateController.text
            : DateTime.now().toIso8601String(),
        "om_custrefno": (int.tryParse(custrefController.text) ?? 0).toString(),  // Use custrefController here
        "om_custrefdate": widget.DateController.text.isNotEmpty
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
         "om_deliveryat": customerDetails?['deliveryAt'] ?? '',
         "om_remarks" :customerDetails?['remarks'] ?? '',
        "om_transportremarks": customerDetails?['transportRemarks'] ?? '',
        "om_paymentterms": customerDetails?['paymentTerms'] ?? '',
        "om_deliveryterms": customerDetails?['deliveryTerms'] ?? '',
        "order_details": orders.asMap().entries.map((entry) {
          int index = entry.key;
          var item = entry.value;
          return {
            "ot_srno": (index + 1).toString(),
            "ot_itemid": item['itemId']?.toString() ?? '',
            "ot_invqty": (double.tryParse(item['quantity']?.toString() ?? '0') ?? 0).toString(),
            "ot_rate": (double.tryParse(item['rate']?.toString() ?? '0.0') ?? 0.0).toString(),
            "ot_subtotal": (double.tryParse(item['subtotal']?.toString() ?? '0.0') ?? 0.0).toString(),
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
Widget buildOrderForm(BuildContext context) {
  bool isUpdateEnabled = widget.omQty == widget.omPendingQty;
return Column(
    children: [
      // Expanded scrollable area for all form fields and order list.
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Order ID and Date Fields
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: widget.IdController,
                      decoration: const InputDecoration(
                        labelText: 'Order NO.',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: widget.DateController,
                      decoration: const InputDecoration(
                        labelText: 'Order Date',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
           Row(
  children: [
    // Cust RefNO Field (Larger)
    Expanded(
      flex: 1, // Keep it as is
      child: TextField(
        controller: custrefController,
        decoration: const InputDecoration(
          labelText: 'Cust RefNO.',
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        ),
      ),
    ),
    const SizedBox(width: 16),

    // Customer Refr Date (Decrease Width)
    SizedBox(
      width: 150, // Set a smaller width
      child: TextField(
        controller: widget.DateController,
        decoration: const InputDecoration(
          labelText: 'Customer Refr Date',
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        ),
      ),
    ),
    const SizedBox(width: 16),

    // Cust Type (One Letter Input)
    SizedBox(
      width: 40, // Very small width for single letter
      child: TextField(
       controller: custTypeController,
        readOnly:true,
        maxLength: 1, // Restrict input to one letter
        textAlign: TextAlign.center, // Center align the letter
        decoration: const InputDecoration(
          labelText: 'Type',
          border: OutlineInputBorder(),
          counterText: '', // Hide character count
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        ),
      ),
    ),
  ],
),

              const SizedBox(height: 12),
              // Customer Dropdown
              GestureDetector(
                onTap: () => openCustomerDropdown(context),
                child: SizedBox(
                  height: 36,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Select Customer',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            selectedCustomer != null
                                ? customers.firstWhere(
                                    (customer) => customer['AM_AccId'] == selectedCustomer,
                                  )['AM_AccName'] ??
                                    'Select Customer'
                                : 'Select Customer',
                            style: const TextStyle(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 11),
              // Agent Dropdown
              GestureDetector(
                onTap: () => openCustomerDropdownAgent(context),
                child: SizedBox(
                  height: 37,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Select Agent',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Builder(
                            builder: (context) {
                              try {
                                final agentName = agents.firstWhere(
                                      (agent) => agent['ID'].toString() == selectedAgent,
                                      orElse: () {
                                        print('No matching agent found for selectedAgent: $selectedAgent');
                                        return {'AgentName': 'Select Agent'};
                                      },
                                    )['AgentName'] ??
                                    'Select Agent';
                                return Text(
                                  agentName,
                                  style: const TextStyle(fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                );
                              } catch (e) {
                                print('Error in displaying agent: $e');
                                return const Text(
                                  'Error loading agent',
                                  style: TextStyle(color: Colors.red),
                                );
                              }
                            },
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 11),
              // Transport Dropdown
              GestureDetector(
                onTap: () => openTransportDropdown(context),
                child: SizedBox(
                  height: 36,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Select Transport',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                           selectedTransport != null
    ? transports.firstWhere(
        (transport) => transport['TransportID'] == selectedTransport,
        orElse: () => {'TransportName': 'Select Transport'},
      )['TransportName']
    : 'Select Transport',
                            style: const TextStyle(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              // Customer Details button
              Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 35),
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                       String flag = 'Edit';
                      final result = await Navigator.push(
                        context,
                         MaterialPageRoute(
      builder: (context) => flag == 'Edit'
          ? CustomerDetailsEditPage(omid: widget.omid,
      username: widget.username,
      clientcode: widget.clientcode,) // Navigate to edit page
          : CustomerDetailsPage(), // Navigate to new entry page
    ),
  );
                      
                      if (result != null && result is Map<String, String>) {
                        setState(() {
                          customerDetails = result;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 11),
              // List of Order Items
              orders.isEmpty
                  ? const Text('No items added yet.')
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final item = orders[index];
                        // double itemTotalAmount;
                        // if (item["quantity"] != null && item["rate"] != null) {
                        //   itemTotalAmount =
                        //       (int.tryParse(item["quantity"].toString()) ?? 0) *
                        //           (double.tryParse(item["rate"].toString()) ?? 0.0);
                        // } else {
                        //   itemTotalAmount = 0.0;
                        // }
                        // item["totalAmount"] = itemTotalAmount.toString();
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
                                    GestureDetector(
                                      onTap: () {},
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[200],
                                          child: Image.network(
                                            item["itemId"] != null && item["itemId"].isNotEmpty
                                                ? '${globals.uriname}${globals.clientcode}/${globals.xyz}/Images/Items/${item["itemId"]}_1.jpg'
                                                : 'assets/images/icons/00000000.jpg',
                                            fit: BoxFit.cover,
                                            errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                              return Image.asset(
                                                'assets/images/icons/00000000.jpg',
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Quantity TextField
                                                Transform.translate(
                                                  offset: const Offset(0, -12),
                                                  child: TextField(
                                                    controller: TextEditingController.fromValue(
                                                      TextEditingValue(
                                                        text: item["quantity"] != null ? item["quantity"].toString() : '',
                                                        selection: TextSelection.collapsed(
                                                          offset: item["quantity"] != null ? item["quantity"].toString().length : 0,
                                                        ),
                                                      ),
                                                    ),
                                                    decoration: const InputDecoration(
                                                      hintText: 'Enter Quantity',
                                                      border: UnderlineInputBorder(),
                                                      contentPadding: EdgeInsets.symmetric(vertical: 2),
                                                    ),
                                                    keyboardType: TextInputType.number,
                                                    style: const TextStyle(fontSize: 12),
                                                    onChanged: (value) {
                                                      final index = orders.indexOf(item);
                                                      if (index != -1) {
                                                        int? newQuantity = value.isEmpty ? null : int.tryParse(value);
                                                        orders[index]["quantity"] = newQuantity;
                                                        double rate = double.tryParse(orders[index]["rate"]?.toString() ?? '0.0') ?? 0.0;
                                                        orders[index]["subtotal"] = (newQuantity ?? 0) * rate;
                                                        calculateTotals();
                                                      }
                                                    },
                                                  ),
                                                ),
                                                // Overlapping Rate TextField
                                                Transform.translate(
                                                  offset: const Offset(0, -18),
                                                  child: TextField(
  controller: TextEditingController.fromValue(
    TextEditingValue(
      text:  getrate2 (item), // Ensure it's a double

      selection: TextSelection.collapsed(
        offset: getrate3 (item)
        // offset: (double.tryParse(item["rate"].toString())?.toStringAsFixed(0).length ?? 0)
                
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
      double? newRate = value.isEmpty ? null : double.tryParse(value);
      double quantity = double.tryParse(item["quantity"]?.toString() ?? '0') ?? 0.0;

      item["rate"] = newRate; // Store as double
       item["rate2"] = newRate;
      item["subtotal"] = (newRate ?? 0) * quantity; // Correct subtotal calculation

      calculateTotals();
    });
  },
),


                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 9),
                                          // Second Column: Calculated Price and Update/Delete buttons
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                // Calculated Price (Qty * Rate)
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    const Icon(Icons.currency_rupee, color: Colors.red, size: 16),
                                                    Text(
                                                      '${item["subtotal"] ?? "0.0"}',
                                                      style: const TextStyle(color: Colors.red, fontSize: 14),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                // Update and Delete buttons
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.edit, color: Colors.black, size: 18),
                                                      padding: const EdgeInsets.only(left: 40),
                                                      onPressed: () {
                                                        showEditDialog(index);
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (BuildContext context) {
                                                            return AlertDialog(
                                                              title: const Text('Confirm Delete'),
                                                              content: const Text('Are you sure you want to delete this item?'),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () {
                                                                    Navigator.pop(context);
                                                                  },
                                                                  child: const Text('Cancel'),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: () {
                                                                    deleteItem(index);
                                                                    Navigator.pop(context);
                                                                  },
                                                                  child: const Text('Delete'),
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
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      // Fixed Bottom Section (Totals Row and Save Order Button)
      Container(
        color: Colors.white, // Optional: color or elevation if needed
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Totals Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Qty: $totalQuantity',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Items: $totalItems',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Amt: ${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Save Order Button
  widget.flag == 'Edit'
  
          ? Row(
              children: [
                // Update Button
           Expanded(
                  child: ElevatedButton(
                    onPressed: (!widget.isApproveDisabled && isUpdateEnabled) ? () async {
                      try {
                        // Add your update logic here
                        if (selectedCustomer == null ||
                            selectedCustomer.toString().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a customer'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        if (orders.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please add at least one order'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Updating order...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        print("Calling updateOrderData...");
                        await updateOrderData();
                        print("updateOrderData completed.");
                        // Optionally, fetch new order ID if needed
                     
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order updated successfully!'),
                            duration: Duration(seconds: 2),
                           
                          ),
                        );
                         Navigator.pop(context,true); 
                      } catch (error, stackTrace) {
                        print("Error updating order: $error");
                        print("Stack Trace: $stackTrace");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to update order. Please try again.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Update'),
                   
                  ),
                ),
                const SizedBox(width: 10),
                // Approve Button
                
                Expanded(
                  
                  child: ElevatedButton(
                    onPressed: widget.isApproveDisabled ? null :() async {
                      try {
                        // Add your approve logic here
                        if (selectedCustomer == null ||
                            selectedCustomer.toString().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a customer'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                          }
                        if (orders.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please add at least one order'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Approving order...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        print("Calling approveOrderData...");
                       await updateOrderData();
                       await approveOrderData();
                        print("approveOrderData completed.");
                        // Optionally, fetch new order ID if needed
                       
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order approved successfully!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                         Navigator.pop(context,true); 
                      } catch (error, stackTrace) {
                        print("Error approving order: $error");
                        print("Stack Trace: $stackTrace");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to approve order. Please try again.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            )
          : // For new orders, show a Save Order button
          Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        if (selectedCustomer == null ||
                            selectedCustomer.toString().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a customer'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        if (orders.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please add at least one order'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saving order...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        // print("Calling saveOrderData...");
                        await saveOrderData();
                        // print("saveOrderData completed.");
                        // Optionally fetch a new order ID after saving
                        
                        await _fetchOrderId();
                        // Clear the input fields and state variables after saving the order
      setState(() {
        // Update the date to the current date
        widget.DateController.text =
            DateFormat('yyyy-MM-dd').format(DateTime.now());
        selectedCustomer = null; // Reset selected customer
        selectedAgent = null; // Reset selected agent
        selectedTransport = null; // Reset selected transport
        custrefController.text = '';
        orders.clear(); // Clear the order items if required
        totalQuantity = 0; // Reset total quantity
        totalItems = 0; // Reset total items
        totalAmount = 0.0; // Reset total amount
      });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order saved successfully!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        
                      } catch (error, stackTrace) {
                        print("Error saving order: $error");
                        print("Stack Trace: $stackTrace");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to save order. Please try again.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Save Order'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}


  @override
  Widget build(BuildContext context) {
    bool isUpdateEnabled = double.tryParse(widget.omQty.toString()) == double.tryParse(widget.omPendingQty.toString());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        
        title: widget.flag == "Edit" ? const Text('Edit Order') : const Text('New Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () async {
              var res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SimpleBarcodeScannerPage(),
                ),
              );

              if (res != null) {
                print("Scanned Result: $res");
                fetchItemData(res, context); // Fetch data and add to the list
              }
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body:isLoading
          ? Center(child: CircularProgressIndicator())
          : buildOrderForm(context),

       floatingActionButton: FloatingActionButton(
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
    }, // Icon inside the button
    tooltip: 'Add Item',
    child: const Icon(Icons.add), // Tooltip when hovering on the button
  ),
    );
  }
}