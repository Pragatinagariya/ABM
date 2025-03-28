import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'agency_outstanding_c_detail.dart';
import 'globals.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class AgencyOutstandingScreen extends StatefulWidget {
  final String username;
  final String clientcode;
  final String clientname;
  final String clientMap;

  const AgencyOutstandingScreen({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
  });

  @override
  State<AgencyOutstandingScreen> createState() =>
      AgencyOutstandingScreenState();
}

class AgencyOutstandingScreenState extends State<AgencyOutstandingScreen> {
  String? selectedItem;
  String? selectedAccId;
  List<String> dropdownItems = [];
  Map<String, String> accountIds = {};
  List<dynamic> userData = [];
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  List<String> filteredItems = [];
  bool isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    getRecord();

    fetchDropdownItems();
    // Ensure dropdown is open on initial load
    isDropdownOpen = true;
  }

  Future<void> fetchDropdownItems() async {
    String uri =
        "${uriname}read_customer.php?clientcode=$clientcode&cmp=$cmpcode";
    try {
      final response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          dropdownItems =
              List<String>.from(data.map((item) => item['d_accname']));
          accountIds = {
            for (var item in data) item['d_accname']: item['d_accid']
          };
          filteredItems = dropdownItems; // Show all items by default
        });
      } else {
        print('Failed to load dropdown items');
      }
    } catch (e) {
      print('Error fetching dropdown items: $e');
    }
  }

  void filterDropdownItems(String query) {
    setState(() {
      if (query.isEmpty) {
        // Show all items if search field is empty
        filteredItems = dropdownItems;
      } else {
        // Filter items based on query
        filteredItems = dropdownItems
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void getRecord() async {
    if (selectedAccId != null) {
      String uri =
          "${uriname}agency_outstanding_c.php?clientcode=$clientcode&cmp=$cmpcode&d_accid=$selectedAccId";
      try {
        var response = await http.get(Uri.parse(uri));
        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          if (jsonResponse is List) {
            setState(() {
              userData = jsonResponse;
            });
          }
        } else {
          print('Request failed with status: ${response.statusCode}');
        }
      } catch (e) {
        print('Request error: $e');
      }
    }
  }

  Future<File> _createPDF() async {
    final pdf = pw.Document();
    const int itemsPerPage = 20; // Number of items per page
    final totalPages = (userData.length / itemsPerPage).ceil(); // Total pages
    final totalBillAmount = userData.fold<double>(
      0.0,
      (sum, item) =>
          sum + (double.tryParse(item["d_pendingamt"] ?? '0') ?? 0.0),
    ); // Calculate total bill amount

    // Iterate through the pages and generate each page
    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      final startIndex = pageNum * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;
      final pageData = userData.sublist(
        startIndex,
        endIndex > userData.length ? userData.length : endIndex,
      );

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(widget.clientMap,
                    style: const pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 5),
                pw.Text('Agency Outstanding Customer Summary',
                    style: const pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(selectedItem ?? 'No Customer Selected',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        'As on ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(0.5),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('No',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Supplier',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Agent',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('City',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Pending Amt',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Divider(thickness: 1),
                        pw.Divider(thickness: 1),
                        pw.Divider(thickness: 1),
                        pw.Divider(thickness: 1),
                        pw.Divider(thickness: 1),
                      ],
                    ),
                    // Loop through the pageData to generate table rows dynamically
                    for (int i = 0; i < pageData.length; i++)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('${startIndex + i + 1}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${pageData[i]["d_suppname"] ?? "No name"}',
                              style: const pw.TextStyle(fontSize: 9),
                              maxLines: 2,
                              overflow: pw.TextOverflow.clip,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${pageData[i]["d_agentname"] ?? "No name"}',
                              style: const pw.TextStyle(fontSize: 9),
                              maxLines: 2,
                              overflow: pw.TextOverflow.clip,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${pageData[i]["d_suppcity"] ?? "No name"}',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(3),
                            child: pw.Text(
                              '${pageData[i]["d_pendingamt"] ?? "0.0"}',
                              style: const pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 10),
                if (pageNum ==
                    totalPages - 1) // Add total only on the last page
                  pw.Column(
                    children: [
                      pw.Divider(), // Divider above the total
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Spacer(), // Add space to push the text to the right
                          pw.Text(
                            'Total Bill Amount: ${totalBillAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Divider(), // Divider below the total
                    ],
                  ),
                pw.SizedBox(height: 10),
              ],
            );
          },
        ),
      );
    }

    // Saving the PDF
    final directory = await getApplicationDocumentsDirectory();
    final file =
        File('${directory.path}/agency_outstanding_customer_summary.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Function to share the PDF
  Future<void> _sharePDF() async {
    try {
      final pdfFile = await _createPDF();
      await Share.shareFiles([pdfFile.path],
          text: 'Agency Outstanding Customer Summary PDF');
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    bool isKeyboardVisible = keyboardHeight > 0;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text(
          'Agency Outstanding Customer',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePDF,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search Customer',
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    filterDropdownItems(value);
                    setState(() {
                      isDropdownOpen =
                          value.isEmpty || filteredItems.isNotEmpty;
                    });
                  },
                ),
                if (isDropdownOpen && filteredItems.isNotEmpty)
                  Container(
                    height: isKeyboardVisible
                        ? keyboardHeight - 10
                        : 550, // Adjust height slightly
                    padding: const EdgeInsets.only(
                        bottom: 8.0), // Add bottom padding
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(filteredItems[index]),
                          onTap: () {
                            setState(() {
                              selectedItem = filteredItems[index];
                              selectedAccId = accountIds[selectedItem]!;
                              searchController.text = selectedItem!;
                              isDropdownOpen = false;
                            });
                            getRecord();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: userData.isEmpty
                ? const Center(
                    // child: Text(
                    //   'Please select a customer',
                    //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    // ),
                    )
                : ListView.builder(
                    itemCount: userData.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin:
                            const EdgeInsets.only(top: 2, left: 10, right: 5),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          title: Row(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Tooltip(
                                    message: userData[index]["d_suppname"] ??
                                        'No name',
                                    child: Text(
                                      userData[index]["d_suppname"] ??
                                          'No name',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          const TextSpan(
                                              text: 'Agent: ',
                                              style: TextStyle(
                                                  color: Colors.grey)),
                                          TextSpan(
                                            text:
                                                '${userData[index]["d_agentname"] ?? 'No agent name'}',
                                            style: const TextStyle(
                                                color: Colors.black),
                                          ),
                                        ],
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          const TextSpan(
                                              text: 'City: ',
                                              style: TextStyle(
                                                  color: Colors.grey)),
                                          TextSpan(
                                            text:
                                                '${userData[index]["d_suppcity"] ?? 'No city'}',
                                            style: const TextStyle(
                                                color: Colors.black),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.currency_rupee,
                                      color: Colors.red, size: 15),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${userData[index]["d_pendingamt"] ?? '0.00'}',
                                    style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AgencyOutstandingDetailScreen(
                                  accid: userData[index]["d_accid"] ?? '',
                                  accname: userData[index]["d_accname"] ?? '',
                                  suppid: userData[index]["d_suppid"] ?? '',
                                  suppname: userData[index]["d_suppname"] ?? '',
                                  username: widget.username,
                                  clientcode: widget.clientcode,
                                  clientname: widget.clientname,
                                  clientMap: widget.clientMap,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}