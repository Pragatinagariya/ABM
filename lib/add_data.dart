import 'package:flutter/material.dart';

class AddDataPage extends StatelessWidget {
  const AddDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Data'),
        backgroundColor: Theme.of(context).primaryColor,
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
