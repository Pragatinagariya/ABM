import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'supp_detail.dart'; // Import the detail screen
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'globals.dart';

class OutstandingSupplier extends StatefulWidget {
  final String username;
  final String clientcode;
  final String clientname;
  final String clientMap;

  const OutstandingSupplier(
      {super.key,
      required this.username,
      required this.clientcode,
      required this.clientname,
      required this.clientMap});

  @override
  State<OutstandingSupplier> createState() => OutstandingSupplierState();
}

class OutstandingSupplierState extends State<OutstandingSupplier> {
  List userData = [];

  @override
  void initState() {
    super.initState();
    getRecord();
  }

  Future<void> getRecord() async {
    String uri =
        "${uriname}outstanding_supp.php?clientcode=$clientcode&cmp=$cmpcode";

    try {
      var response = await http.get(Uri.parse(uri));
      print(uri);
      print('Raw response body: ${response.body}');
      if (response.statusCode == 200) {
        var jsonResponse;
        try {
          jsonResponse = jsonDecode(response.body);
          print('Parsed JSON Response: $jsonResponse');
        } catch (e) {
          print('JSON decoding error: $e');
          return;
        }
        if (jsonResponse is List) {
          setState(() {
            userData = jsonResponse;
            print("State updated with ${userData.length} items");
          });
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Request error: $e');
    }
  }

  Future<File> _createPDF() async {
    final pdf = pw.Document();
    const int itemsPerPage = 20; // Number of items per page
    final totalPages = (userData.length / itemsPerPage).ceil(); // Total pages
    final totalBillAmount = userData.fold<double>(
      0.0,
      (sum, item) => sum + (double.tryParse(item["d_billamt"] ?? '0') ?? 0.0),
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
                pw.Text('Outstanding Supplier Summary',
                    style: const pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 10),
                pw.Text(
                  'As on ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold), // Corrected this line
                  textAlign: pw.TextAlign.right,
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
                          child: pw.Text('Bill Amt',
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
                              '${pageData[i]["d_accname"] ?? "No name"}',
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
                              '${pageData[i]["d_acccity"] ?? "No name"}',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(3),
                            child: pw.Text(
                              '${pageData[i]["d_billamt"] ?? "0.0"}',
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
    final file = File('${directory.path}/outstanding_supplier_summary.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Function to share the PDF
  Future<void> _sharePDF() async {
    try {
      final pdfFile = await _createPDF();
      await Share.shareFiles([pdfFile.path],
          text: 'Outstanding Supplier Summary PDF');
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Outstanding Supplier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              if (userData.isNotEmpty) {
                _sharePDF();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No data to generate PDF")),
                );
              }
            },
          ),
        ],
      ),
      body: userData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: userData.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(top: 2, left: 10, right: 5),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    title: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Tooltip(
                              message:
                                  userData[index]["d_accname"] ?? 'No name',
                              child: Text(
                                userData[index]["d_accname"] ?? 'No name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    TextSpan(
                                      text:
                                          '${userData[index]["d_agentname"] ?? 'No agent name'}',
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'City: ',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    TextSpan(
                                      text:
                                          '${userData[index]["d_acccity"] ?? 'No city'}',
                                      style:
                                          const TextStyle(color: Colors.black),
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
                            const Icon(
                              Icons.currency_rupee,
                              color: Colors.red,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${userData[index]["d_billamt"] ?? '0.00'}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SuppilerDetailScreen(
                            accid: userData[index]["d_accid"] ?? '',
                            accname: userData[index]["d_accname"] ?? '',
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
    );
  }
}
