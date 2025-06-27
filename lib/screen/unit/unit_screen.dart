// presentation/screens/unit/unit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/unit_providers.dart';
import '../../../utils/snackbar_util.dart';
import 'add_unit_screen.dart';

class UnitScreen extends ConsumerWidget {
  const UnitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitAsync = ref.watch(unitProvider);

    return Scaffold(
      appBar: AppBar(title: Text("Units")),

      // 👇 Body: Unit List or loading/error
      body: unitAsync.when(
        data: (units) => ListView.builder(
          itemCount: units.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(units[i].umUnit),
            subtitle: Text(units[i].umRemarks),
          ),
        ),
        loading: () => Center(
            child: Text("No data found",
                style: TextStyle(
                  fontSize: 20,
                ))),
        error: (err, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            SnackbarUtil.showError(context, err.toString());
          });
          return Center(child: Text("Failed to load units."));
        },
      ),

      // ✅ Floating Action Button added
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddUnitScreen(),
            ),
          );
        },
        tooltip: 'Add New Unit',
        child: Icon(Icons.add),
      ),
    );
  }
}
