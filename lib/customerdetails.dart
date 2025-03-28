import 'package:flutter/material.dart';

class CustomerDetailsPage extends StatefulWidget {
  const CustomerDetailsPage({super.key});

  @override
  _CustomerDetailsPageState createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  
  final TextEditingController deliveryAtController = TextEditingController();
  final TextEditingController transportRemarksController = TextEditingController();
  final TextEditingController paymentTermsController = TextEditingController();
  final TextEditingController deliveryTermsController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Form validation key

  // Function to save and return data
  void saveAndPassData() {
    // Store the form values in a Map
    Map<String, String> formData = {
      'deliveryAt': deliveryAtController.text,
      'remarks': remarksController.text,
      'transportRemarks': transportRemarksController.text,
      'paymentTerms': paymentTermsController.text,
      'deliveryTerms': deliveryTermsController.text,
    };

    // Print values for debugging
    debugPrint('Form Data: $formData');

    // Pass data back to the previous screen
    Navigator.pop(context, formData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Additional Details'),
      backgroundColor: Colors.orange,),
      body: SingleChildScrollView(
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
                        contentPadding:EdgeInsets.symmetric(vertical:4,horizontal:12),
                  ),
                ),
                const SizedBox(height: 12),
                  Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: paymentTermsController,
                        decoration: const InputDecoration(
                          labelText: 'Payment Terms',
                          border: OutlineInputBorder(),
                          isDense: true,
                        contentPadding:EdgeInsets.symmetric(vertical:4,horizontal:12),
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
                        contentPadding:EdgeInsets.symmetric(vertical:4,horizontal:12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    border: OutlineInputBorder(),
                  ),
                   maxLines: 2,
                ),
                const SizedBox(height: 12),
               
                  TextFormField(
                        controller: transportRemarksController,
                        decoration: const InputDecoration(
                          labelText: 'Transport Remarks',
                          border: OutlineInputBorder(),
                          
                        ),
                         maxLines: 2,
                      ),
        
                // Payment Terms & Delivery Terms
                const SizedBox(height:12),
                
               
        
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