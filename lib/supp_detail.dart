import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'globals.dart';

class SuppilerDetailScreen extends StatefulWidget {
  final String accid;
  final String accname;
  final String username;
  final String clientcode; // Add clientcode as a parameter
  final String clientname;
  final String clientMap;

  const SuppilerDetailScreen({
    super.key,
    required this.accid,
    required this.accname,
    required this.username,
    required this.clientcode,
    required this.clientname, // Accept clientcode
    required this.clientMap,
  });

  @override
  State<SuppilerDetailScreen> createState() =>
      _SuppilerDetailScreenState();
}

class _SuppilerDetailScreenState extends State<SuppilerDetailScreen> {
  List userData = [];

  @override
  void initState() {
    super.initState();
    getRecord();
  }

  Future<void> getRecord() async {
    String uri =
        "${uriname}outstanding_supp_detail.php?accid=${widget.accid}&clientcode=$clientcode&cmp=$cmpcode"; // Include clientcode in the URL
    try {
      var response = await http.get(Uri.parse(uri));
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
    final totalRcvdAmount = userData.fold<double>(
      0.0,
      (sum, item) => sum + (double.tryParse(item["d_rcptamt"] ?? '0') ?? 0.0),
    );
    final totalPndgAmount = userData.fold<double>(
      0.0,
      (sum, item) =>
          sum + (double.tryParse(item["d_pendingamt"] ?? '0') ?? 0.0),
    );

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
              pw.Text(widget.clientMap, style: const pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 5),
              pw.Text('Outstanding Supplier', style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(widget.accname,
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
                    0: const pw.FlexColumnWidth(0.8),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(2),
                    4: const pw.FlexColumnWidth(2),
                    5: const pw.FlexColumnWidth(2),
                    6: const pw.FlexColumnWidth(2),
                    7: const pw.FlexColumnWidth(2),
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
                          child: pw.Text('Bill No',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Bill Date',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Bill Amt',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Rcvd Amt',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Pndg Amt',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Due Date',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Due Days',
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
                                '${pageData[i]["d_billno"] ?? "No name"}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                                '${pageData[i]["d_billdate"] ?? "No date"}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${pageData[i]["d_billamt"] ?? "0.0"}',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${pageData[i]["d_rcptamt"] ?? "0.0"}',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${pageData[i]["d_pendingamt"] ?? "0.0"}',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('${pageData[i]["due_date"] ?? "-"}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${pageData[i]["due_days"] ?? "0.0"}',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),

                    // Divider above totals row
                    if (pageNum == totalPages - 1)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Divider(thickness: 1),
                          ),
                          for (int j = 1; j < 8; j++)
                            pw.Padding(
                              padding:
                                  const pw.EdgeInsets.symmetric(vertical: 2),
                              child: pw.Divider(thickness: 1),
                            ),
                        ],
                      ),

                    // Totals row
                    if (pageNum == totalPages - 1)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(''),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(''),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Total:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              totalBillAmount.toStringAsFixed(1),
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                  textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              totalRcvdAmount.toStringAsFixed(1),
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                  textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              totalPndgAmount.toStringAsFixed(1),
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                  textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(''),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(''),
                          ),
                        ],
                      ),

                    // Divider below totals row
                    if (pageNum == totalPages - 1)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Divider(thickness: 1),
                          ),
                          for (int j = 1; j < 8; j++)
                            pw.Padding(
                              padding:
                                  const pw.EdgeInsets.symmetric(vertical: 2),
                              child: pw.Divider(thickness: 1),
                            ),
                        ],
                      ),
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
    final file = File('${directory.path}/outstanding_supplier_detail.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Function to share the PDF
  Future<void> _sharePDF() async {
    try {
      final pdfFile = await _createPDF();
      await Share.shareFiles([pdfFile.path],
          text: 'Outstanding Supplier Detail PDF');
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text(
    widget.accname,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
            _sharePDF();
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
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              userData[index]["d_billno"] ?? "N/A",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              '|',
                              style: TextStyle(color: Colors.black),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              userData[index]["d_billdate"] ?? "N/A",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        const SizedBox(height: 2),

                        // Row for Due Days, Due Date, and Rupee Value
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Due Days: ',
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13), // Label in grey
                                      ),
                                      TextSpan(
                                        text:
                                            '${userData[index]["due_days"] ?? "N/A"}',
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 13), // Data in black
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  '|',
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Due Date: ',
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13), // Label in grey
                                      ),
                                      TextSpan(
                                        text:
                                            '${userData[index]["due_date"] ?? "N/A"}',
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 13), // Data in black
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.currency_rupee,
                                    color: Colors.red, size: 15),
                                const SizedBox(
                                    width: 0), // Adjust spacing as needed
                                Flexible(
                                  child: Text(
                                    '${userData[index]["d_pendingamt"] ?? '0.00'}', // Rupee value
                                    style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                        fontWeight: FontWeight
                                            .bold // Adjust font size here
                                        ),
                                    overflow: TextOverflow
                                        .ellipsis, // Handle overflow
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),

                        const SizedBox(height: 2),

                        // Row for Agent
                        Row(
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Agent: ',
                                    style: TextStyle(
                                        color: Colors.grey), // Label in grey
                                  ),
                                  TextSpan(
                                    text:
                                        '${userData[index]["d_agentname"] ?? "N/A"}',
                                    style: const TextStyle(
                                        color: Colors.black), // Data in black
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );  }
}
