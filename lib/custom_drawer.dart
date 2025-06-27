import 'package:ABM2/agency_outstanding_c.dart';
import 'package:ABM2/agency_outstanding_s.dart';
import 'package:ABM2/agent_list.dart';
import 'package:ABM2/customer_list.dart';
import 'package:ABM2/group_list.dart';
import 'package:ABM2/item_list_2.dart';
import 'package:ABM2/itemgroup_list.dart';
import 'package:ABM2/outstanding_screen.dart';
import 'package:ABM2/supp_screen.dart';
import 'package:ABM2/supplier_list.dart';
import 'package:ABM2/unit_list.dart';
import 'package:ABM2/z_settings.dart';
import 'package:flutter/material.dart';
import 'shared_pref_helper.dart';
import 'globals.dart' as globals;
import 'main.dart'; // LoginPage

class CustomDrawer extends StatefulWidget {
  final String username;
  final String clientcode;
  final String clientname;
  final Map<String, String> clientMap;
  final String dropdownValue;

  const CustomDrawer({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
    required this.dropdownValue,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool isMastersExpanded = false;
  bool isSalesExpanded = false;
  bool isPurchaseExpanded = false;
  bool isJobworkExpanded = false;
  bool isOutstandingExpanded = false;
  bool isSettingExpanded = false;
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child:
                      Icon(Icons.account_circle, size: 48, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        globals.username ?? "Guest",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Mandate Holder",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // const _DrawerItem(icon: Icons.sync, text: 'Sync'),
                ListTile(
                  leading: const Icon(Icons.supervised_user_circle),
                  title: const Text('Masters'),
                  trailing: Icon(isMastersExpanded
                      ? Icons.expand_less
                      : Icons.expand_more),
                  onTap: () {
                    setState(() {
                      isMastersExpanded = !isMastersExpanded;
                    });
                  },
                ),
                if (isMastersExpanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      children: [
                        _SubDrawerItem(
                          icon: Icons.person,
                          text: 'Group',
                          destination: GroupList(
                            username: widget.username,
                            clientcode: widget.clientMap[widget.dropdownValue]!,
                            clientname: widget.dropdownValue.isNotEmpty
                                ? widget.dropdownValue
                                : 'Unknown',
                            clientMap: widget.clientMap[widget.dropdownValue]!,
                          ),
                        ),
                        _SubDrawerItem(
                          icon: Icons.people,
                          text: 'Customer',
                          destination: CustomerList(
                            username: widget.username,
                            clientcode: widget.clientMap[widget.dropdownValue]!,
                            clientname: widget.dropdownValue.isNotEmpty
                                ? widget.dropdownValue
                                : 'Unknown',
                            clientMap: widget.clientMap[widget.dropdownValue]!,
                          ),
                        ),
                        _SubDrawerItem(
                          icon: Icons.person,
                          text: 'Supplier',
                          destination: SupplierList(
                            username: widget.username,
                            clientcode: widget.clientMap[widget.dropdownValue]!,
                            clientname: widget.dropdownValue.isNotEmpty
                                ? widget.dropdownValue
                                : 'Unknown',
                            clientMap: widget.clientMap[widget.dropdownValue]!,
                          ),
                        ),
                        _SubDrawerItem(
                          icon: Icons.people,
                          text: 'Agent',
                          destination: AgentList(
                            username: widget.username,
                            clientcode: widget.clientMap[widget.dropdownValue]!,
                            clientname: widget.dropdownValue.isNotEmpty
                                ? widget.dropdownValue
                                : 'Unknown',
                            clientMap: widget.clientMap[widget.dropdownValue]!,
                          ),
                        ),
                        _SubDrawerItem(
                          icon: Icons.person,
                          text: 'Item Groups',
                          destination: ItemGroupList(
                            username: widget.username,
                            clientcode: widget.clientMap[widget.dropdownValue]!,
                            clientname: widget.dropdownValue.isNotEmpty
                                ? widget.dropdownValue
                                : 'Unknown',
                            clientMap: widget.clientMap[widget.dropdownValue]!,
                          ),
                        ),
                        _SubDrawerItem(
                          icon: Icons.person,
                          text: 'Items',
                          destination: ItemListNew(
                            username: widget.username,
                            clientcode: widget.clientMap[widget.dropdownValue]!,
                            cmpcode: widget.clientcode,
                            clientname: widget.dropdownValue.isNotEmpty
                                ? widget.dropdownValue
                                : 'Unknown',
                            clientMap: widget.clientMap[widget.dropdownValue]!,
                          ),
                        ),
                        _SubDrawerItem(
                          icon: Icons.person,
                          text: 'Unit',
                          destination: UnitList(
                            username: widget.username,
                            clientcode: widget.clientMap[widget.dropdownValue]!,
                            clientname: widget.dropdownValue.isNotEmpty
                                ? widget.dropdownValue
                                : 'Unknown',
                            clientMap: widget.clientMap[widget.dropdownValue]!,
                          ),
                        ),
                        const _SubDrawerItem(
                            icon: Icons.person, text: 'HSN Code'),
                      ],
                    ),
                  ),

                // sales
                // ListTile(
                //   leading: const Icon(Icons.supervised_user_circle),
                //   title: const Text('Sales'),
                //   trailing: Icon(
                //       isSalesExpanded ? Icons.expand_less : Icons.expand_more),
                //   onTap: () {
                //     setState(() {
                //       isSalesExpanded = !isSalesExpanded;
                //     });
                //   },
                // ),
                // if (isSalesExpanded)
                //   Padding(
                //     padding: const EdgeInsets.only(left: 20),
                //     child: Column(
                //       children: [
                //         _SubDrawerItem(
                //           icon: Icons.people,
                //           text: 'Sales Order',
                //           destination: CustomerList(
                //             username: widget.username,
                //             clientcode: widget.clientMap[widget.dropdownValue]!,
                //             clientname: widget.dropdownValue.isNotEmpty
                //                 ? widget.dropdownValue
                //                 : 'Unknown',
                //             clientMap: widget.clientMap[widget.dropdownValue]!,
                //           ),
                //         ),
                //         _SubDrawerItem(
                //           icon: Icons.person,
                //           text: 'Sales challan',
                //           destination: SupplierList(
                //             username: widget.username,
                //             clientcode: widget.clientMap[widget.dropdownValue]!,
                //             clientname: widget.dropdownValue.isNotEmpty
                //                 ? widget.dropdownValue
                //                 : 'Unknown',
                //             clientMap: widget.clientMap[widget.dropdownValue]!,
                //           ),
                //         ),
                //         _SubDrawerItem(
                //           icon: Icons.person,
                //           text: 'Sales Invoice',
                //           destination: ItemGroupList(
                //             username: widget.username,
                //             clientcode: widget.clientMap[widget.dropdownValue]!,
                //             clientname: widget.dropdownValue.isNotEmpty
                //                 ? widget.dropdownValue
                //                 : 'Unknown',
                //             clientMap: widget.clientMap[widget.dropdownValue]!,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),

                // Purchase

                // ListTile(
                //   leading: const Icon(Icons.supervised_user_circle),
                //   title: const Text('Purchase'),
                //   trailing: Icon(isPurchaseExpanded
                //       ? Icons.expand_less
                //       : Icons.expand_more),
                //   onTap: () {
                //     setState(() {
                //       isPurchaseExpanded = !isPurchaseExpanded;
                //     });
                //   },
                // ),
                // if (isPurchaseExpanded)
                //   Padding(
                //     padding: const EdgeInsets.only(left: 20),
                //     child: Column(
                //       children: [
                //         _SubDrawerItem(
                //           icon: Icons.people,
                //           text: 'Purchase Order',
                //           destination: CustomerList(
                //             username: widget.username,
                //             clientcode: widget.clientMap[widget.dropdownValue]!,
                //             clientname: widget.dropdownValue.isNotEmpty
                //                 ? widget.dropdownValue
                //                 : 'Unknown',
                //             clientMap: widget.clientMap[widget.dropdownValue]!,
                //           ),
                //         ),
                //         _SubDrawerItem(
                //           icon: Icons.person,
                //           text: 'Purchase challan',
                //           destination: SupplierList(
                //             username: widget.username,
                //             clientcode: widget.clientMap[widget.dropdownValue]!,
                //             clientname: widget.dropdownValue.isNotEmpty
                //                 ? widget.dropdownValue
                //                 : 'Unknown',
                //             clientMap: widget.clientMap[widget.dropdownValue]!,
                //           ),
                //         ),
                //         _SubDrawerItem(
                //           icon: Icons.person,
                //           text: 'Purchase Invoice',
                //           destination: ItemGroupList(
                //             username: widget.username,
                //             clientcode: widget.clientMap[widget.dropdownValue]!,
                //             clientname: widget.dropdownValue.isNotEmpty
                //                 ? widget.dropdownValue
                //                 : 'Unknown',
                //             clientMap: widget.clientMap[widget.dropdownValue]!,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),

                // ListTile(
                //   leading: const Icon(Icons.supervised_user_circle),
                //   title: const Text('Job work'),
                //   trailing: Icon(isJobworkExpanded
                //       ? Icons.expand_less
                //       : Icons.expand_more),
                //   onTap: () {
                //     setState(() {
                //       isJobworkExpanded = !isJobworkExpanded;
                //     });
                //   },
                // ),
                // if (isJobworkExpanded)
                //   Padding(
                //     padding: const EdgeInsets.only(left: 20),
                //     child: Column(
                //       children: [
                //         _SubDrawerItem(
                //           icon: Icons.people,
                //           text: 'Job Work',
                //           destination: CustomerList(
                //             username: widget.username,
                //             clientcode: widget.clientMap[widget.dropdownValue]!,
                //             clientname: widget.dropdownValue.isNotEmpty
                //                 ? widget.dropdownValue
                //                 : 'Unknown',
                //             clientMap: widget.clientMap[widget.dropdownValue]!,
                //           ),
                //         ),
                //         _SubDrawerItem(
                //           icon: Icons.person,
                //           text: 'Job challan',
                //           destination: SupplierList(
                //             username: widget.username,
                //             clientcode: widget.clientMap[widget.dropdownValue]!,
                //             clientname: widget.dropdownValue.isNotEmpty
                //                 ? widget.dropdownValue
                //                 : 'Unknown',
                //             clientMap: widget.clientMap[widget.dropdownValue]!,
                //           ),
                //         ),
                //         _SubDrawerItem(
                //           icon: Icons.person,
                //           text: 'Job Invoice',
                //           destination: ItemGroupList(
                //             username: widget.username,
                //             clientcode: widget.clientMap[widget.dropdownValue]!,
                //             clientname: widget.dropdownValue.isNotEmpty
                //                 ? widget.dropdownValue
                //                 : 'Unknown',
                //             clientMap: widget.clientMap[widget.dropdownValue]!,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                ListTile(
                  leading: const Icon(Icons.supervised_user_circle),
                  title: const Text('Outstanding'),
                  trailing: Icon(isOutstandingExpanded
                      ? Icons.expand_less
                      : Icons.expand_more),
                  onTap: () {
                    setState(() {
                      isOutstandingExpanded = !isOutstandingExpanded;
                    });
                  },
                ),
                if (isOutstandingExpanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      children: [
                        _SubDrawerItem(
                          icon: Icons.person,
                          text: 'Customer',
                          destination: OutstandingScreen(
                            username: widget.username,
                            clientcode: widget.clientMap[widget.dropdownValue]!,
                            clientname: widget.dropdownValue.isNotEmpty
                                ? widget.dropdownValue
                                : 'Unknown',
                            clientMap: widget.clientMap[widget.dropdownValue]!,
                          ),
                        ),
                        _SubDrawerItem(
                          icon: Icons.person,
                          text: 'Supplier',
                          destination: OutstandingSupplier(
                            username: widget.username,
                            clientcode: widget.clientMap[widget.dropdownValue]!,
                            clientname: widget.dropdownValue.isNotEmpty
                                ? widget.dropdownValue
                                : 'Unknown',
                            clientMap: widget.clientMap[widget.dropdownValue]!,
                          ),
                        ),
                      ],
                    ),
                  ),
                // const _DrawerItem(icon: Icons.shopping_cart, text: 'MIS'),
                // const _DrawerItem(
                //     icon: Icons.shopping_bag, text: 'Quick Reports'),
                // const _DrawerItem(
                //     icon: Icons.precision_manufacturing,
                //     text: 'Daily Analysis'),
                // const _DrawerItem(icon: Icons.inventory, text: 'Manage Stock'),
                // const _DrawerItem(
                //     icon: Icons.business_center,
                //     text: 'Smart Business Planning',
                //     isPro: true),
                // const _DrawerItem(icon: Icons.analytics, text: 'ABM Analytics'),
                // const _DrawerItem(
                //     icon: Icons.history, text: 'Shared Design History'),
                // const _DrawerItem(
                //     icon: Icons.notifications_active, text: 'Reminders'),
                // const _DrawerItem(
                //     icon: Icons.production_quantity_limits,
                //     text: 'Our Other Products'),
                // const _DrawerItem(icon: Icons.more_horiz, text: 'More'),
                ListTile(
                  leading: const Icon(Icons.supervised_user_circle),
                  title: const Text('Setting'),
                  trailing: Icon(isSettingExpanded
                      ? Icons.expand_less
                      : Icons.expand_more),
                  onTap: () {
                    setState(() {
                      isSettingExpanded = !isSettingExpanded;
                    });
                  },
                ),
                if (isSettingExpanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      children: [
                        _SubDrawerItem(
                          icon: Icons.people,
                          text: 'Theme',
                          destination: SettingsPage(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await SharedPrefHelper.clearLoginState();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

// Drawer item with optional destination navigation
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isPro;
  final Widget? destination;

  const _DrawerItem(
      {required this.icon,
      required this.text,
      required this.isPro,
      required this.destination});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Row(
        children: [
          Expanded(child: Text(text)),
          if (isPro)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
      onTap: () {
        if (destination != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination!),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Development mode on")),
          );
        }
      },
    );
  }
}

// Sub-item under a collapsible section like Masters
class _SubDrawerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? destination;

  const _SubDrawerItem({
    required this.icon,
    required this.text,
    this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -3),
      contentPadding: const EdgeInsets.only(left: 40, right: 16),
      leading: Icon(icon, size: 20, color: Colors.grey[700]),
      title: Text(
        text,
        style: const TextStyle(fontSize: 14),
      ),
      onTap: () {
        if (destination != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination!),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Development mode on")),
          );
        }
      },
    );
  }
}
