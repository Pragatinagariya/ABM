import 'package:flutter/material.dart';
import 'globals.dart';

class AddDataPage extends StatelessWidget {
  const AddDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Data'),
        backgroundColor: themeColor,
      ),
      body: Center(
        child: Text(
          '',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
