import 'package:flutter/material.dart';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'gst_income_transaction_read.dart';

class GstincomeTransaction extends StatefulWidget {
  final String username; // Add username parameter
  final String clientcode;
  final String clientname;
  final String clientMap;
  final String itid;
  final String invoice;

  const GstincomeTransaction({
    super.key,
    required this.username,
    required this.clientcode,
    required this.clientname,
    required this.clientMap,
    required this.itid,
    required this.invoice,
  }); // Accept username in constructor

  @override
  State<GstincomeTransaction> createState() => GstincomeTransactionState();
}

class GstincomeTransactionState extends State<GstincomeTransaction> {
  List Data = [];

  @override
  void initState() {
    super.initState();
    getRecord();
  }

  Future<void> getRecord() async {
    String uri =
        "${uriname}GSTIncome_transaction.php?IT_Id=${widget.itid}&clientcode=$clientcode&cmp=$cmpcode"; // Pass username in the query
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
            Data = jsonResponse;
            print("State updated with ${Data.length} items");
          });
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Request error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          widget.invoice,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Data.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: Data.length,
              itemBuilder: (context, index) {
                final item = Data[index];
                return GestureDetector(
                  // Use GestureDetector for tap handling
                  onTap: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => GstincomeTransactionRead(
                    //       srno: Data[index]["IT_SrNo"],
                    //       itid: Data[index]["IT_Id"],
                    //       username: widget.username,
                    //       clientcode: widget.clientcode,
                    //       clientname: widget.clientname,
                    //       clientMap: widget.clientMap,
                    //     ),
                    //   ),
                    // );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(top: 5, left: 10, right: 10),
                    elevation: 3, // Adds shadow effect
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First Row: IT_SrNo | IM_ItemName (HSN Code)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // IT_SrNo and IM_ItemName (50% width)
                              Flexible(
                                flex: 1,
                                child: Text(
                                  "${item["IT_SrNo"] ?? 'N/A'} - ${item["IM_ItemName"] ?? 'N/A'}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines:
                                      2, // Wraps text to next line if needed
                                  overflow:
                                      TextOverflow.visible, // Makes text wrap
                                ),
                              ),
                              // HSN Code
                              Expanded(
                                child: RichText(
                                  textAlign: TextAlign.right,
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: "(HSN : ", // Label in grey
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            "${item["HM_HSNCode"] ?? 'N/A'}", // Data in black
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ")",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Subtotal with Red color
                              Expanded(
                                child: RichText(
                                  textAlign: TextAlign.right,
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: "₹ ",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      TextSpan(
                                        text: (double.tryParse(item[
                                                                "IT_SubTotal"] ??
                                                            '0.00') ??
                                                        0.0) %
                                                    1 ==
                                                0
                                            ? "${item["IT_SubTotal"]?.split('.')[0]}" // Display only whole number if no decimal part
                                            : "${item["IT_SubTotal"]}", // Display with decimal part if there is any
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5), // Spacing
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: item["IT_RateType"] == 'P'
                                      ? "Pcs: "
                                      : "Mtrs: ", // Dynamic Label
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                TextSpan(
                                  text: item["IT_RateType"] ==
                                          'P' // Check for RateType
                                      ? ((double.tryParse(item["IT_Pcs"] ??
                                                          '0.0') ??
                                                      0.0) %
                                                  1 ==
                                              0
                                          ? "${item["IT_Pcs"]?.split('.')[0]}" // Show whole number if no decimal part
                                          : "${item["IT_Pcs"]}") // Show with decimal if it exists
                                      : ((double.tryParse(item["IT_Mtrs"] ??
                                                          '0.0') ??
                                                      0.0) %
                                                  1 ==
                                              0
                                          ? "${item["IT_Mtrs"]?.split('.')[0]}" // Show whole number if no decimal part
                                          : "${item["IT_Mtrs"]}"), // Show with decimal if it exists
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                                const TextSpan(
                                  text: " @ ", // @ symbol
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue,
                                  ),
                                ),
                                TextSpan(
                                  text: (double.tryParse(item["IT_Rate"] ??
                                                      '0.00') ??
                                                  0.0) %
                                              1 ==
                                          0
                                      ? "₹ ${item["IT_Rate"]?.split('.')[0]}" // Show whole number if no decimal part
                                      : "₹ ${item["IT_Rate"]}", // Show with decimal if it exists
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                                const TextSpan(
                                  text: " = ", // Equals symbol
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue,
                                  ),
                                ),
                                TextSpan(
                                  text: (double.tryParse(item["IT_SubTotal"] ??
                                                      '0.00') ??
                                                  0.0) %
                                              1 ==
                                          0
                                      ? "₹ ${item["IT_SubTotal"]?.split('.')[0]}" // Show whole number if no decimal part
                                      : "₹ ${item["IT_SubTotal"]}", // Show with decimal if it exists
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5), // Spacing

                          // Fourth Row: Discount and Taxable Amount
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: "Dis: ", // Label in grey
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                TextSpan(
                                  text: (double.tryParse(item["IT_DisPer"] ??
                                                      '0') ??
                                                  0.0) %
                                              1 ==
                                          0
                                      ? "${item["IT_DisPer"]?.split('.')[0]}%" // Show only whole number if no decimal part
                                      : "${item["IT_DisPer"]}%", // Show with decimal if there's any
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                                const TextSpan(
                                  text: " - ", // Minus symbol in red
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue,
                                  ),
                                ),
                                const TextSpan(
                                  text: "Dis Amt: ", // Label in grey
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                TextSpan(
                                  text: (double.tryParse(item["IT_DisAmt"] ??
                                                      '0.00') ??
                                                  0.0) %
                                              1 ==
                                          0
                                      ? "₹ ${item["IT_DisAmt"]?.split('.')[0]}" // Show only whole number if no decimal part
                                      : "₹ ${item["IT_DisAmt"]}", // Show with decimal if there's any
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                                const TextSpan(
                                  text: " = ", // Equals symbol in red
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue,
                                  ),
                                ),
                                TextSpan(
                                  text: (double.tryParse(item["IT_TaxablAmt"] ??
                                                      '0.00') ??
                                                  0.0) %
                                              1 ==
                                          0
                                      ? "₹ ${item["IT_TaxablAmt"]?.split('.')[0]}" // Show only whole number if no decimal part
                                      : "₹ ${item["IT_TaxablAmt"]}", // Show with decimal if there's any
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5), // Spacing

                          // Fifth Row: GST and Total GST
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: "GST ", // Label in grey
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const TextSpan(
                                  text: "(", // Opening parenthesis in grey
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: (double.tryParse(item["IT_GSTPer"] ??
                                                      '0.0') ??
                                                  0.0) %
                                              1 ==
                                          0
                                      ? "${item["IT_GSTPer"]?.split('.')[0]}" // Show only whole number if no decimal part
                                      : "${item["IT_GSTPer"]}", // Show with decimal if there's any
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                                const TextSpan(
                                  text: "%", // Percentage symbol in grey
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      "): ", // Closing parenthesis and colon in grey
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: (double.tryParse(item["IT_TotalGST"] ??
                                                      '0.00') ??
                                                  0.0) %
                                              1 ==
                                          0
                                      ? "₹ ${item["IT_TotalGST"]?.split('.')[0]}" // Show only whole number if no decimal part
                                      : "₹ ${item["IT_TotalGST"]}", // Show with decimal if there's any
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
