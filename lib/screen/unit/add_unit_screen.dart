// presentation/screens/unit/add_unit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/unit_model.dart';
import '../../../data/services/unit_service.dart';
import '../../../utils/snackbar_util.dart';

class AddUnitScreen extends ConsumerStatefulWidget {
  const AddUnitScreen({super.key});

  @override
  ConsumerState<AddUnitScreen> createState() => _AddUnitScreenState();
}

class _AddUnitScreenState extends ConsumerState<AddUnitScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all TextFields
  final idCtrl = TextEditingController();
  final macIdCtrl = TextEditingController();
  final recIdCtrl = TextEditingController();
  final userIdCtrl = TextEditingController();
  final unitCodeCtrl = TextEditingController();
  final unitCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();

  bool isLoading = false;

  Future<void> insertUnit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

 final unit = UnitModel(
  umId: idCtrl.text,
  umMacId: macIdCtrl.text,
  umRecId: recIdCtrl.text,
  umUserId: userIdCtrl.text,
  umUnitCode: unitCodeCtrl.text,
  umUnit: unitCtrl.text,
  umRemarks: remarksCtrl.text,
);

    try {
      final result = await UnitService().insertUnit(unit);
      if (result) {
        SnackbarUtil.showSuccess(context, 'Unit inserted successfully!');
        Navigator.pop(context); // Go back to list page
      } else {
        SnackbarUtil.showError(context, 'Insert failed. Try again.');
      }
    } catch (e) {
      SnackbarUtil.showError(context, e.toString());
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add New Unit")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildTextField("UM_Id", idCtrl),
              buildTextField("UM_MacId", macIdCtrl),
              buildTextField("UM_RecId", recIdCtrl),
              buildTextField("UM_UserId", userIdCtrl),
              buildTextField("UM_UnitCode", unitCodeCtrl),
              buildTextField("UM_Unit", unitCtrl),
              buildTextField("UM_Remarks", remarksCtrl),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: isLoading ? null : insertUnit,
                icon: Icon(Icons.save),
                label: Text(isLoading ? "Saving..." : "Insert Unit"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.isEmpty ? "Required" : null,
      ),
    );
  }

  @override
  void dispose() {
    idCtrl.dispose();
    macIdCtrl.dispose();
    recIdCtrl.dispose();
    userIdCtrl.dispose();
    unitCodeCtrl.dispose();
    unitCtrl.dispose();
    remarksCtrl.dispose();
    super.dispose();
  }
}
