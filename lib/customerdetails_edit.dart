import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'globals.dart' as globals;

class CustomerDetailsEditPage extends StatefulWidget {
  final String omid;
  final String username;
  final String clientcode;

  const CustomerDetailsEditPage({
    super.key,
    required this.omid,
    required this.username,
    required this.clientcode,
  });

  @override
  _CustomerDetailsEditPageState createState() =>
      _CustomerDetailsEditPageState();
}

class _CustomerDetailsEditPageState extends State<CustomerDetailsEditPage> {
  final TextEditingController deliveryAtController = TextEditingController();
  final TextEditingController transportRemarksController = TextEditingController();
  final TextEditingController paymentTermsController = TextEditingController();
  final TextEditingController deliveryTermsController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>(); // Form validation key
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }

  Future<void> fetchOrderDetails() async {
    final url =
        '${globals.uriname}order_list_2.php?om_id=${widget.omid}&clientcode=${globals.clientcode}&cmp=${globals.cmpcode}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Full response data: $data');

        if (data.isNotEmpty) {
          final orderDetails = data[0]; // Assuming first item is needed

          setState(() {
            deliveryAtController.text = orderDetails['om_deliveryat'] ?? '';
            remarksController.text = orderDetails['om_remarks'] ?? '';
            transportRemarksController.text = orderDetails['om_transportremarks'] ?? '';
            paymentTermsController.text = orderDetails['om_paymentterms'] ?? '';
            deliveryTermsController.text = orderDetails['om_deliveryterms'] ?? '';
            isLoading = false;
          });
        } else {
          print('No data found.');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to save and return data
  void saveAndPassData() {
    Map<String, String> formData = {
      'deliveryAt': deliveryAtController.text,
      'remarks': remarksController.text,
      'transportRemarks': transportRemarksController.text,
      'paymentTerms': paymentTermsController.text,
      'deliveryTerms': deliveryTermsController.text,
    };

    debugPrint('Form Data: $formData');
    Navigator.pop(context, formData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Additional Details'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loader while fetching data
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Delivery At
                      TextFormField(
                        controller: deliveryAtController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery At',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Payment Terms & Delivery Terms
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: paymentTermsController,
                              decoration: const InputDecoration(
                                labelText: 'Payment Terms',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: deliveryTermsController,
                              decoration: const InputDecoration(
                                labelText: 'Delivery Terms',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Remarks
                      TextFormField(
                        controller: remarksController,
                        decoration: const InputDecoration(
                          labelText: 'Remarks',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      // Transport Remarks
                      TextFormField(
                        controller: transportRemarksController,
                        decoration: const InputDecoration(
                          labelText: 'Transport Remarks',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      // Submit Button
                      ElevatedButton(
                        onPressed: saveAndPassData,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}