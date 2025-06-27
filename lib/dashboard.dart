import 'package:ABM2/custom_drawer.dart';
import 'package:ABM2/hisablist.dart';

import 'Itemwiseorder.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'outstanding_screen.dart';
import 'supp_screen.dart';
import 'dart:developer';
import 'globals.dart' as globals;
import 'item_list.dart';
import 'unit_list.dart';
import 'itemgroup_list.dart';
import 'account_list.dart';
import 'hsn_list.dart';
import 'group_list.dart';
import 'customer_list.dart';
import 'supplier_list.dart';
import 'agent_list.dart';
import 's_agent_list.dart';
import 'purchasechallan_master.dart';
import 'purchase_master.dart';
import 'invoice_master.dart';
import 'challan_master.dart';
import 'order_master.dart';
import 'item_list_2.dart';
import 'task_new.dart';
import 'my_tasks.dart';
import 'completed_task.dart';
import 'task_all.dart';
import 'topselling.dart';
import 'topcustomer.dart';
import 'jobwork.dart';
import 'clientmasterList.dart';
import '../screen/unit/unit_screen.dart';
import 'companymasterList.dart';
import 'clientuserList.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final String clientid;
  final List<Map<String, dynamic>> orders;
  const HomeScreen({
    super.key,
    required this.username,
    required this.clientid,
    required this.orders,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final int _selectedIndex = 0;
  Map<String, String> companyTokens = {}; // ✅ Initialize properly

  String dropdownValue = ''; // Initial value for dropdown
  Map<String, String> clientMap = {}; // Map to store client names and codes
  String flag = '';

  @override
  void initState() {
    super.initState();

    fetchDropdownData();
  }

  // Function to fetch data from API
  Future<void> fetchDropdownData() async {
    print('Fetching data for username: ${widget.username}');

    final String apiUrl =
        'https://abm99.amisys.in/android/PHP/v1/company.php?clientid=${widget.clientid}';

    try {
      print('API URL: $apiUrl');

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        log('API Response: ${response.body}');

        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          if (mounted) {
            setState(() {
              clientMap.clear();
              globals.companyTokens = {}; // ✅ Clear existing tokens

              for (var item in data) {
                final map = item as Map<String, dynamic>;

                // You can add token logic here if needed later

                if (map['cmpname'] != null && map['cmpcode'] != null) {
                  clientMap[map['cmpname']] = map['cmpcode'];
                }
              }

              if (clientMap.isNotEmpty) {
                dropdownValue = clientMap.keys.first;
                globals.cmpname = dropdownValue;
                globals.cmpcode = clientMap[dropdownValue] ?? '';
                log('Initial Client Name: ${globals.cmpname}');
                log('Initial Client Code: ${globals.cmpcode}');
              }
            });
          }
        } else {
          log('No data found');
          throw Exception('No records found');
        }
      } else {
        log('Failed to load data: ${response.statusCode}');
        throw Exception('Failed to load dropdown data');
      }
    } catch (e) {
      log('Error fetching data: $e');
    }
  }

  void _onItemTapped(int index) {
    // Check if dropdownValue is valid before proceeding
    if (dropdownValue.isNotEmpty && clientMap.containsKey(dropdownValue)) {
      if (index == 1) {
        log('Navigating to OutstandingScreen with client: $dropdownValue and code: ${clientMap[dropdownValue]}');

        // Navigate to the new "Outstanding" page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OutstandingScreen(
              username: widget.username,
              clientcode:
                  clientMap[dropdownValue]!, // Fetch client code from map
              clientname: dropdownValue.isNotEmpty ? dropdownValue : 'Unknown',
              clientMap: dropdownValue,
            ),
          ),
        );
      } else if (index == 2) {
        log('Navigating to OutstandingSupplier with client: $dropdownValue and code: ${clientMap[dropdownValue]}');

        // Navigate to the new "OutstandingSupplier" page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OutstandingSupplier(
              username: widget.username,
              clientcode:
                  clientMap[dropdownValue]!, // Fetch client code from map
              clientname: dropdownValue.isNotEmpty ? dropdownValue : 'Unknown',
              clientMap: dropdownValue,
            ),
          ),
        );
      }
    } else {
      // Show an error message if no client is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a valid client before proceeding.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.account_circle,
                size: 24, color: Colors.black), // Profile icon
            Text(
              globals.username ?? "Guest", // Display username from globals
              style: const TextStyle(fontSize: 12, color: Colors.black),
            ),
          ],
        ),
        actions: <Widget>[
          clientMap.isEmpty
              ? const CircularProgressIndicator()
              : DropdownButton<String>(
                  value: dropdownValue,
                  icon: const Icon(Icons.arrow_downward, color: Colors.black),
                  elevation: 16,
                  style: const TextStyle(color: Colors.black),
                  underline: Container(
                    height: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        dropdownValue = newValue;
                        log('Selected Client: $dropdownValue');
                        globals.cmpname = dropdownValue;
                      });

                      String? clientCode = clientMap[dropdownValue];
                      if (clientCode != null) {
                        log('Client Code for $dropdownValue: $clientCode');
                        globals.cmpcode = clientCode;
                        print('globals : ${globals.cmpcode}');

                        // ✅ Update token based on selected company
                        globals.token =
                            globals.companyTokens[dropdownValue] ?? '';
                        log('Token for $dropdownValue: ${globals.token}');
                      } else {
                        log('Client not found in map for: $dropdownValue');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Error: Client not found.')),
                        );
                      }
                    }
                  },
                  items: clientMap.keys
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
          const SizedBox(width: 20),
        ],
      ),
      drawer: CustomDrawer(
        username: widget.username,
        clientname: dropdownValue,
        clientMap: clientMap,
        clientcode: clientMap[dropdownValue] ?? '',
        dropdownValue: dropdownValue,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            // const SizedBox(height: 20),
            // _widgetOptions.elementAt(_selectedIndex),
            // Text(
            //   'Selected: $dropdownValue',
            //   style: const TextStyle(fontSize: 20),
            // ),
            Text(
              'Selected Client: $dropdownValue',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Client Code: ${clientMap[dropdownValue] ?? "N/A"}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 5),

            GridView.count(
              shrinkWrap: true, // Important: Prevents excessive space
              physics:
                  NeverScrollableScrollPhysics(), // Disable internal scrolling
              crossAxisCount: 4,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              padding: const EdgeInsets.all(10.0),
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemGroupList(
                          username: widget.username,
                          clientcode: clientMap[
                              dropdownValue]!, // Fetch client code from map
                          clientname: dropdownValue.isNotEmpty
                              ? dropdownValue
                              : 'Unknown',
                          clientMap: dropdownValue,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.white,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                            image:
                                AssetImage('assets/images/icons/itemgroup.png'),
                            height: 50,
                            width: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Item Group",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemListNew(
                          username: widget.username,
                          clientcode: clientMap[
                              dropdownValue]!, // Fetch client code from map
                              cmpcode: globals.cmpcode,
                          clientname: dropdownValue.isNotEmpty
                              ? dropdownValue
                              : 'Unknown',
                          clientMap: dropdownValue,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.white,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                            image: AssetImage('assets/images/icons/item.png'),
                            height: 50,
                            width: 50,
                          ),
                          SizedBox(height: 10),
                          Text("Item"),
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UnitList(
                          username: widget.username,
                          clientcode: clientMap[
                              dropdownValue]!, // Fetch client code from map
                          clientname: dropdownValue.isNotEmpty
                              ? dropdownValue
                              : 'Unknown',
                          clientMap: dropdownValue,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.white,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                            image: AssetImage('assets/images/icons/units.jpg'),
                            height: 50,
                            width: 50,
                          ),
                          SizedBox(height: 10),
                          Text("Unit"),
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UnitScreen(),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.white,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                            image: AssetImage('assets/images/icons/units.jpg'),
                            height: 50,
                            width: 50,
                          ),
                          SizedBox(height: 10),
                          Text("Unit_New"),
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HsnRead(
                          username: widget.username,
                          clientcode: clientMap[
                              dropdownValue]!, // Fetch client code from map
                          clientname: dropdownValue.isNotEmpty
                              ? dropdownValue
                              : 'Unknown',
                          clientMap: dropdownValue,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.white,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                            image: AssetImage('assets/images/icons/hsn.jpg'),
                            height: 50,
                            width: 50,
                          ),
                          SizedBox(height: 10),
                          Text("HSN"),
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupList(
                          username: widget.username,
                          clientcode: clientMap[
                              dropdownValue]!, // Fetch client code from map
                          clientname: dropdownValue.isNotEmpty
                              ? dropdownValue
                              : 'Unknown',
                          clientMap: dropdownValue,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.white,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                            image: AssetImage('assets/images/icons/group.jpg'),
                            height: 50,
                            width: 50,
                          ),
                          SizedBox(height: 10),
                          Text("Group"),
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountList(
                          username: widget.username,
                          clientcode: clientMap[
                              dropdownValue]!, // Fetch client code from map
                          clientname: dropdownValue.isNotEmpty
                              ? dropdownValue
                              : 'Unknown',
                          clientMap: dropdownValue,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.white,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                            image:
                                AssetImage('assets/images/icons/account.png'),
                            height: 50,
                            width: 50,
                          ),
                          SizedBox(height: 10),
                          Text("Account"),
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemList(
                          username: widget.username,
                          clientcode: clientMap[
                              dropdownValue]!, // Fetch client code from map
                          clientname: dropdownValue.isNotEmpty
                              ? dropdownValue
                              : 'Unknown',
                          clientMap: dropdownValue,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.white,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                            image: AssetImage('assets/images/icons/item.png'),
                            height: 50,
                            width: 50,
                          ),
                          SizedBox(height: 10),
                          Text("Item 2"),
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => ItemList(
                    //       username: widget.username,
                    //       clientcode: clientMap[
                    //           dropdownValue]!, // Fetch client code from map
                    //       clientname: dropdownValue.isNotEmpty
                    //           ? dropdownValue
                    //           : 'Unknown',
                    //       clientMap: dropdownValue,
                    //     ),
                    //   ),
                    // );
                  },
                  child: Container(
                    color: Colors.white,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Image(
                          //   image: AssetImage('assets/images/icons/itemgroup.png'),
                          //   height: 50,
                          //   width: 50,
                          // ),
                          SizedBox(height: 2),
                          Text(""),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Transform.translate(
              offset: Offset(0, -25), // Moves it up by 5 pixels
              child: GridView.count(
                shrinkWrap: true, // Prevents excessive space
                physics: NeverScrollableScrollPhysics(), // Disable scrolling
                crossAxisCount: 4,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                padding: const EdgeInsets.all(10.0),
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerList(
                            username: widget.username,
                            clientcode: clientMap[
                                dropdownValue]!, // Fetch client code from map
                            clientname: dropdownValue.isNotEmpty
                                ? dropdownValue
                                : 'Unknown',
                            clientMap: dropdownValue,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image(
                              image: AssetImage(
                                  'assets/images/icons/customer.png'),
                              height: 50,
                              width: 50,
                            ),
                            SizedBox(height: 10),
                            Text("Customer"),
                          ],
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SupplierList(
                            username: widget.username,
                            clientcode: clientMap[
                                dropdownValue]!, // Fetch client code from map
                            clientname: dropdownValue.isNotEmpty
                                ? dropdownValue
                                : 'Unknown',
                            clientMap: dropdownValue,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image(
                              image: AssetImage(
                                  'assets/images/icons/supplier.jpg'),
                              height: 50,
                              width: 50,
                            ),
                            SizedBox(height: 10),
                            Text("Supplier"),
                          ],
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AgentList(
                            username: widget.username,
                            clientcode: clientMap[
                                dropdownValue]!, // Fetch client code from map
                            clientname: dropdownValue.isNotEmpty
                                ? dropdownValue
                                : 'Unknown',
                            clientMap: dropdownValue,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image(
                              image:
                                  AssetImage('assets/images/icons/agent.png'),
                              height: 50,
                              width: 50,
                            ),
                            SizedBox(height: 10),
                            Text("Agent"),
                          ],
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SuppAgentList(
                            username: widget.username,
                            clientcode: clientMap[
                                dropdownValue]!, // Fetch client code from map
                            clientname: dropdownValue.isNotEmpty
                                ? dropdownValue
                                : 'Unknown',
                            clientMap: dropdownValue,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image(
                              image: AssetImage(
                                  'assets/images/icons/supplier.jpg'),
                              height: 35,
                              width: 40,
                            ),
                            Text("Supplier"),
                            Text("Agent"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Transform.translate(
              offset: Offset(0, -50), // Moves it up by 5 pixels
              child: GridView.count(
                shrinkWrap: true, // Important: Prevents excessive space
                physics:
                    NeverScrollableScrollPhysics(), // Disable internal scrolling
                crossAxisCount: 4,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                padding: const EdgeInsets.all(10.0),
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PurchaseChallanMaster(
                            username: widget.username,
                            clientcode: clientMap[
                                dropdownValue]!, // Fetch client code from map
                            clientname: dropdownValue.isNotEmpty
                                ? dropdownValue
                                : 'Unknown',
                            clientMap: dropdownValue,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image(
                              image: AssetImage(
                                  'assets/images/icons/purchase_challan.png'),
                              height: 35,
                              width: 40,
                            ),
                            SizedBox(height: 5),
                            Text("Purchase"),
                            Text(
                                "Challan"), // Add this line to print "Challan" below
                          ],
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PurchaseMaster(
                            username: widget.username,
                            clientcode: clientMap[
                                dropdownValue]!, // Fetch client code from map
                            clientname: dropdownValue.isNotEmpty
                                ? dropdownValue
                                : 'Unknown',
                            clientMap: dropdownValue,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image(
                              image: AssetImage(
                                  'assets/images/icons/purchase_invoice.jpg'),
                              height: 35,
                              width: 540,
                            ),
                            SizedBox(height: 5),
                            Text("Purchase"),
                            Text("Invoice"),
                          ],
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChallanMaster(
                            username: widget.username,
                            clientcode: clientMap[
                                dropdownValue]!, // Fetch client code from map
                            clientname: dropdownValue.isNotEmpty
                                ? dropdownValue
                                : 'Unknown',
                            clientMap: dropdownValue,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image(
                              image: AssetImage(
                                  'assets/images/icons/sale challan.jpg'),
                              height: 35,
                              width: 40,
                            ),
                            SizedBox(height: 5),
                            Text("Sales"),
                            Text("Challan"),
                          ],
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoiceMaster(
                            username: widget.username,
                            clientcode: clientMap[
                                dropdownValue]!, // Fetch client code from map
                            clientname: dropdownValue.isNotEmpty
                                ? dropdownValue
                                : 'Unknown',
                            clientMap: dropdownValue,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image(
                              image: AssetImage(
                                  'assets/images/icons/sales_invoice.jpg'),
                              height: 35,
                              width: 40,
                            ),
                            SizedBox(height: 5),
                            Text("Sales"),
                            Text("Invoice"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            // Transform.translate(
            //   offset: Offset(0, -25),
            //   child: GridView.count(
            //     shrinkWrap: true, // Important: Prevents excessive space
            //     physics:
            //         NeverScrollableScrollPhysics(), // Disable internal scrolling
            //     crossAxisCount: 4,
            //     crossAxisSpacing: 6,
            //     mainAxisSpacing: 6,
            //     padding: const EdgeInsets.all(10.0),
            //     children: [
            //       InkWell(
            //         onTap: () async {
            //           // Navigate and await any updates to the orders list
            //           final updatedOrders = await Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => OrderMaster(
            //                 username: globals.username,
            //                 cmpcode: globals.cmpcode,
            //                 clientcode: clientMap[dropdownValue]!,
            //                 orders: widget.orders.cast<Map<String, dynamic>>(),
            //                 clientname: dropdownValue.isNotEmpty
            //                     ? dropdownValue
            //                     : 'Unknown',
            //                 clientMap: dropdownValue,
            //               ),
            //             ),
            //           );

            //           // // If updated orders are returned, update the current list
            //           if (updatedOrders != null) {
            //             setState(() {
            //               // widget.orders.clear();
            //               widget.orders.addAll(updatedOrders);
            //             });
            //           }
            //         },
            //         child: Container(
            //           color: Colors.white,
            //           child: const Center(
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Image(
            //                   image: AssetImage(
            //                       'assets/images/icons/sales_invoice.jpg'),
            //                   height: 35,
            //                   width: 40,
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text("Order"),
            //                 Text("List"),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),
            //       InkWell(
            //         onTap: () async {
            //           // Navigate and await any updates to the orders list
            //           final updatedOrders = await Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => Itemwiseorder(
            //                 username: globals.username,
            //                 clientcode: clientMap[dropdownValue]!,
            //                 orders: widget.orders.cast<Map<String, dynamic>>(),
            //                 clientname: dropdownValue.isNotEmpty
            //                     ? dropdownValue
            //                     : 'Unknown',
            //                 clientMap: dropdownValue,
            //               ),
            //             ),
            //           );

            //           // // If updated orders are returned, update the current list
            //           if (updatedOrders != null) {
            //             setState(() {
            //               // widget.orders.clear();
            //               widget.orders.addAll(updatedOrders);
            //             });
            //           }
            //         },
            //         child: Container(
            //           color: Colors.white,
            //           child: const Center(
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Image(
            //                   image: AssetImage(
            //                       'assets/images/icons/sales_invoice.jpg'),
            //                   height: 35,
            //                   width: 40,
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text("Design"),
            //                 Text("Order"),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),

            //       InkWell(
            //         onTap: () async {
            //           // Navigate and await any updates to the orders list
            //           final updatedOrders = await Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => TopSell(),
            //             ),
            //           );

            //           // // If updated orders are returned, update the current list
            //           if (updatedOrders != null) {
            //             setState(() {
            //               // widget.orders.clear();
            //               widget.orders.addAll(updatedOrders);
            //             });
            //           }
            //         },
            //         child: Container(
            //           color: Colors.white,
            //           child: const Center(
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Image(
            //                   image: AssetImage(
            //                       'assets/images/icons/sales_invoice.jpg'),
            //                   height: 35,
            //                   width: 40,
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text("Top selling"),
            //                 Text("Order"),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),

            //       InkWell(
            //         onTap: () async {
            //           // Navigate and await any updates to the orders list
            //           final updatedOrders = await Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => TopCust(),
            //             ),
            //           );

            //           // // If updated orders are returned, update the current list
            //           if (updatedOrders != null) {
            //             setState(() {
            //               // widget.orders.clear();
            //               widget.orders.addAll(updatedOrders);
            //             });
            //           }
            //         },
            //         child: Container(
            //           color: Colors.white,
            //           child: const Center(
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Image(
            //                   image: AssetImage(
            //                       'assets/images/icons/sales_invoice.jpg'),
            //                   height: 35,
            //                   width: 40,
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text("Top Cust"),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),
            //       InkWell(
            //         onTap: () async {
            //           // Navigate and await any updates to the orders list
            //           final updatedOrders = await Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => JobWork(),
            //             ),
            //           );
            //         },
            //         child: Container(
            //           color: Colors.white,
            //           child: const Center(
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Image(
            //                   image: AssetImage(
            //                       'assets/images/icons/sales_invoice.jpg'),
            //                   height: 35,
            //                   width: 40,
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text("Job work"),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),
            //       // InkWell(
            //       //   onTap: () async {
            //       //     // Navigate and await any updates to the orders list
            //       //     final updatedOrders = await Navigator.push(
            //       //       context,
            //       //       MaterialPageRoute(
            //       //         builder: (context) => Itemwiseorder(
            //       //           username: globals.username,

            //       //           clientcode: clientMap[dropdownValue]!,
            //       //           orders: widget.orders.cast<Map<String, dynamic>>(),
            //       //           clientname: dropdownValue.isNotEmpty
            //       //               ? dropdownValue
            //       //               : 'Unknown',
            //       //           clientMap: dropdownValue,
            //       //         ),
            //       //       ),
            //       //     );

            //       //     // // If updated orders are returned, update the current list
            //       //     if (updatedOrders != null) {
            //       //       setState(() {
            //       //         // widget.orders.clear();
            //       //         widget.orders.addAll(updatedOrders);
            //       //       });
            //       //     }
            //       //   },
            //       //   child: Container(
            //       //     color: Colors.white,
            //       //     child: const Center(
            //       //       child: Column(
            //       //         mainAxisAlignment: MainAxisAlignment.center,
            //       //         children: [
            //       //           Image(
            //       //             image: AssetImage(
            //       //                 'assets/images/icons/sales_invoice.jpg'),
            //       //             height: 35,
            //       //             width: 40,
            //       //           ),
            //       //           SizedBox(height: 5),
            //       //           Text("Design"),
            //       //           Text("Order"),
            //       //         ],
            //       //       ),
            //       //     ),
            //       //   ),
            //       // ),
            //       // InkWell(
            //       //   onTap: () async {
            //       //     // Navigate and await any updates to the orders list
            //       //     final updatedOrders = await Navigator.push(
            //       //       context,
            //       //       MaterialPageRoute(
            //       //         builder: (context) => ChallanList(
            //       //           username: widget.username,
            //       //           clientcode: clientMap[dropdownValue]!,
            //       //           orders: widget.orders.cast<Map<String, dynamic>>(),
            //       //           clientname: dropdownValue.isNotEmpty
            //       //               ? dropdownValue
            //       //               : 'Unknown',
            //       //           clientMap: dropdownValue,
            //       //         ),
            //       //       ),
            //       //     );

            //       //     // If updated orders are returned, update the current list
            //       //     if (updatedOrders != null) {
            //       //       setState(() {
            //       //         // widget.orders.clear();
            //       //         widget.orders.addAll(updatedOrders);
            //       //       });
            //       //     }
            //       //   },
            //       //   child: Container(
            //       //     color: Colors.white,
            //       //     child: const Center(
            //       //       child: Column(
            //       //         mainAxisAlignment: MainAxisAlignment.center,
            //       //         children: [
            //       //           Image(
            //       //             image: AssetImage(
            //       //                 'assets/images/icons/sales_invoice.jpg'),
            //       //             height: 35,
            //       //             width: 40,
            //       //           ),
            //       //           SizedBox(height: 5),
            //       //           Text("Challan"),
            //       //           Text("List"),
            //       //         ],
            //       //       ),
            //       //     ),
            //       //   ),
            //       // ),
            //     ],
            //   ),
            // ),
            // Transform.translate(
            //   offset: Offset(0, -30),
            //   child: GridView.count(
            //     shrinkWrap: true, // Important: Prevents excessive space
            //     physics:
            //         NeverScrollableScrollPhysics(), // Disable internal scrolling
            //     crossAxisCount: 4,
            //     crossAxisSpacing: 6,
            //     mainAxisSpacing: 6,
            //     padding: const EdgeInsets.all(10.0),
            //     children: [
            //       // InkWell(
            //       //           onTap: () async {
            //       //             // Navigate and await any updates to the orders list
            //       //             final updatedOrders = await Navigator.push(
            //       //               context,
            //       //               MaterialPageRoute(
            //       //                 builder: (context) => Itemwiseorder(
            //       //                   username: globals.username,

            //       //                   clientcode: clientMap[dropdownValue]!,
            //       //                   orders: widget.orders.cast<Map<String, dynamic>>(),
            //       //                   clientname: dropdownValue.isNotEmpty
            //       //                       ? dropdownValue
            //       //                       : 'Unknown',
            //       //                   clientMap: dropdownValue,
            //       //                 ),
            //       //               ),
            //       //             );

            //       //             // // If updated orders are returned, update the current list
            //       //             if (updatedOrders != null) {
            //       //               setState(() {
            //       //                 // widget.orders.clear();
            //       //                 widget.orders.addAll(updatedOrders);
            //       //               });
            //       //             }
            //       //           },
            //       //           child: Container(
            //       //             color: Colors.white,
            //       //             child: const Center(
            //       //               child: Column(
            //       //                 mainAxisAlignment: MainAxisAlignment.center,
            //       //                 children: [
            //       //                   Image(
            //       //                     image: AssetImage(
            //       //                         'assets/images/icons/sales_invoice.jpg'),
            //       //                     height: 35,
            //       //                     width: 40,
            //       //                   ),
            //       //                   SizedBox(height: 5),
            //       //                   Text("Design"),
            //       //                   Text("Order"),
            //       //                 ],
            //       //               ),
            //       //             ),
            //       //           ),
            //       //         ),

            //       //         InkWell(
            //       //           onTap: () async {
            //       //             // Navigate and await any updates to the orders list
            //       //             final updatedOrders = await Navigator.push(
            //       //               context,
            //       //               MaterialPageRoute(
            //       //                 builder: (context) => TopSell(

            //       //                 ),
            //       //               ),
            //       //             );

            //       //             // // If updated orders are returned, update the current list
            //       //             if (updatedOrders != null) {
            //       //               setState(() {
            //       //                 // widget.orders.clear();
            //       //                 widget.orders.addAll(updatedOrders);
            //       //               });
            //       //             }
            //       //           },
            //       //           child: Container(
            //       //             color: Colors.white,
            //       //             child: const Center(
            //       //               child: Column(
            //       //                 mainAxisAlignment: MainAxisAlignment.center,
            //       //                 children: [
            //       //                   Image(
            //       //                     image: AssetImage(
            //       //                         'assets/images/icons/sales_invoice.jpg'),
            //       //                     height: 35,
            //       //                     width: 40,
            //       //                   ),
            //       //                   SizedBox(height: 5),
            //       //                   Text("Top selling"),
            //       //                   Text("Order"),
            //       //                 ],
            //       //               ),
            //       //             ),
            //       //           ),
            //       //         ),

            //       //           InkWell(
            //       //           onTap: () async {
            //       //             // Navigate and await any updates to the orders list
            //       //             final updatedOrders = await Navigator.push(
            //       //               context,
            //       //               MaterialPageRoute(
            //       //                 builder: (context) => TopCust(

            //       //                 ),
            //       //               ),
            //       //             );

            //       //             // // If updated orders are returned, update the current list
            //       //             if (updatedOrders != null) {
            //       //               setState(() {
            //       //                 // widget.orders.clear();
            //       //                 widget.orders.addAll(updatedOrders);
            //       //               });
            //       //             }
            //       //           },
            //       //           child: Container(
            //       //             color: Colors.white,
            //       //             child: const Center(
            //       //               child: Column(
            //       //                 mainAxisAlignment: MainAxisAlignment.center,
            //       //                 children: [
            //       //                   Image(
            //       //                     image: AssetImage(
            //       //                         'assets/images/icons/sales_invoice.jpg'),
            //       //                     height: 35,
            //       //                     width: 40,
            //       //                   ),
            //       //                   SizedBox(height: 5),
            //       //                   Text("Top Cust"),

            //       //                 ],
            //       //               ),
            //       //             ),
            //       //           ),
            //       //         ),
            //       InkWell(
            //         onTap: () {
            //           Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => TaskNew(
            //                   // username: widget.username,
            //                   // clientcode: clientMap[
            //                   //     dropdownValue]!, // Fetch client code from map
            //                   // clientname: dropdownValue.isNotEmpty
            //                   //     ? dropdownValue
            //                   //     : 'Unknown',
            //                   // clientMap: dropdownValue,
            //                   ),
            //             ),
            //           );
            //         },
            //         child: Container(
            //           color: Colors.white,
            //           child: const Center(
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Image(
            //                   image: AssetImage(
            //                       'assets/images/icons/New Task.png'),
            //                   height: 35,
            //                   width: 40,
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text("New"),
            //                 Text("Task"),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),
            //       // InkWell(
            //       //   onTap: () {
            //       //   Navigator.push(
            //       //     context,
            //       //     MaterialPageRoute(
            //       //       builder: (context) => MyRequest(
            //       //         // username: widget.username,
            //       //         // clientcode: clientMap[
            //       //         //     dropdownValue]!, // Fetch client code from map
            //       //         // clientname: dropdownValue.isNotEmpty
            //       //         //     ? dropdownValue
            //       //         //     : 'Unknown',
            //       //         // clientMap: dropdownValue,
            //       //       ),
            //       //     ),
            //       //   );
            //       // },
            //       //   child: Container(
            //       //     color: Colors.white,
            //       //     child: const Center(
            //       //       child: Column(
            //       //         mainAxisAlignment: MainAxisAlignment.center,
            //       //         children: [
            //       //           Image(
            //       //             image: AssetImage(
            //       //                 'assets/images/icons/My Request.png'),
            //       //             height: 35,
            //       //             width: 40,
            //       //           ),
            //       //           SizedBox(height: 5),
            //       //           Text("My"),
            //       //           Text("Request"),
            //       //         ],
            //       //       ),
            //       //     ),
            //       //   ),
            //       // ),
            //       InkWell(
            //         onTap: () {
            //           Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => MyTask(
            //                   // username: widget.username,
            //                   // clientcode: clientMap[
            //                   //     dropdownValue]!, // Fetch client code from map
            //                   // clientname: dropdownValue.isNotEmpty
            //                   //     ? dropdownValue
            //                   //     : 'Unknown',
            //                   // clientMap: dropdownValue,
            //                   ),
            //             ),
            //           );
            //         },
            //         child: Container(
            //           color: Colors.white,
            //           child: const Center(
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Image(
            //                   image: AssetImage(
            //                       'assets/images/icons/My Tasks.png'),
            //                   height: 35,
            //                   width: 40,
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text("My"),
            //                 Text("Tasks"),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),
            //       InkWell(
            //         onTap: () {
            //           Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => CompletedTask(
            //                   // username: widget.username,
            //                   // clientcode: clientMap[
            //                   //     dropdownValue]!, // Fetch client code from map
            //                   // clientname: dropdownValue.isNotEmpty
            //                   //     ? dropdownValue
            //                   //     : 'Unknown',
            //                   // clientMap: dropdownValue,
            //                   ),
            //             ),
            //           );
            //         },
            //         child: Container(
            //           color: Colors.white,
            //           child: const Center(
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Image(
            //                   image: AssetImage(
            //                       'assets/images/icons/Completed task.png'),
            //                   height: 35,
            //                   width: 40,
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text("Completed"),
            //                 Text("Task"),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),
            //       InkWell(
            //         onTap: () {
            //           Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => TaskAll(
            //                   // username: widget.username,
            //                   // clientcode: clientMap[
            //                   //     dropdownValue]!, // Fetch client code from map
            //                   // clientname: dropdownValue.isNotEmpty
            //                   //     ? dropdownValue
            //                   //     : 'Unknown',
            //                   // clientMap: dropdownValue,
            //                   ),
            //             ),
            //           );
            //         },
            //         child: Container(
            //           color: Colors.white,
            //           child: const Center(
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Image(
            //                   image: AssetImage(
            //                       'assets/images/icons/approved_request.png'),
            //                   height: 35,
            //                   width: 40,
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text("All"),
            //                 Text("Tasks"),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),
            //       InkWell(
            //         onTap: () {
            //           Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => ClientListPage(
            //                   // username: widget.username,
            //                   // clientcode: clientMap[
            //                   //     dropdownValue]!, // Fetch client code from map
            //                   // clientname: dropdownValue.isNotEmpty
            //                   //     ? dropdownValue
            //                   //     : 'Unknown',
            //                   // clientMap: dropdownValue,
            //                   ),
            //             ),
            //           );
            //         },
            //         child: Container(
            //           color: Colors.white,
            //           child: const Center(
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Image(
            //                   image: AssetImage(
            //                       'assets/images/icons/approved_request.png'),
            //                   height: 35,
            //                   width: 40,
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text("client"),
            //                 Text("master"),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),
            //       InkWell(
            //         onTap: () {
            //           Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => ClientuserList(
            //                   // username: widget.username,
            //                   // clientcode: clientMap[
            //                   //     dropdownValue]!, // Fetch client code from map
            //                   // clientname: dropdownValue.isNotEmpty
            //                   //     ? dropdownValue
            //                   //     : 'Unknown',
            //                   // clientMap: dropdownValue,
            //                   ),
            //             ),
            //           );
            //         },
            //         child: Container(
            //           color: Colors.white,
            //           child: const Center(
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Image(
            //                   image: AssetImage(
            //                       'assets/images/icons/approved_request.png'),
            //                   height: 35,
            //                   width: 40,
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text("client"),
            //                 Text("user"),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),

            //       InkWell(
            //         onTap: () {
            //           Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => CompanyMasterList(
            //                   // username: widget.username,
            //                   // clientcode: clientMap[
            //                   //     dropdownValue]!, // Fetch client code from map
            //                   // clientname: dropdownValue.isNotEmpty
            //                   //     ? dropdownValue
            //                   //     : 'Unknown',
            //                   // clientMap: dropdownValue,
            //                   ),
            //             ),
            //           );
            //         },
            //         child: Container(
            //           color: Colors.white,
            //           child: const Center(
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Image(
            //                   image: AssetImage(
            //                       'assets/images/icons/approved_request.png'),
            //                   height: 35,
            //                   width: 40,
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text("company"),
            //                 Text("master"),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),
            //       InkWell(
            //         onTap: () {
            //           Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => HisabList(
            //                   // username: widget.username,
            //                   // clientcode: clientMap[
            //                   //     dropdownValue]!, // Fetch client code from map
            //                   // clientname: dropdownValue.isNotEmpty
            //                   //     ? dropdownValue
            //                   //     : 'Unknown',
            //                   // clientMap: dropdownValue,
            //                   ),
            //             ),
            //           );
            //         },
            //         child: Container(
            //           color: Colors.white,
            //           child: const Center(
            //             child: Column(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Image(
            //                   image: AssetImage(
            //                       'assets/images/icons/approved_request.png'),
            //                   height: 35,
            //                   width: 40,
            //                 ),
            //                 SizedBox(height: 5),
            //                 Text("Hisab"),
            //                 Text("master"),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            Transform.translate(
              offset: Offset(0, -100),
              child: GridView.count(
                shrinkWrap: true, // Important: Prevents excessive space
                physics:
                    NeverScrollableScrollPhysics(), // Disable internal scrolling
                crossAxisCount: 4,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                padding: const EdgeInsets.all(10.0),
                children: [
                  //  InkWell(
                  //         onTap: () {
                  //             Navigator.push(
                  //               context,
                  //               MaterialPageRoute(
                  //                 builder: (context) => Users(
                  //                 ),
                  //               ),
                  //             );
                  //           },
                  //             child: Container(
                  //               color: Colors.white,
                  //               child: const Center(
                  //                 child: Column(
                  //                   mainAxisAlignment: MainAxisAlignment.center,
                  //                   children: [
                  //                     Image(
                  //                       image: AssetImage(
                  //                           'assets/images/icons/New Task.png'),
                  //                       height: 35,
                  //                       width: 40,
                  //                     ),
                  //                     SizedBox(height: 5),
                  //                     Text("Users"),
                  //                   ],
                  //                 ),
                  //               ),
                  //             ),
                  //           ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.outbox),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Suppliers',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
