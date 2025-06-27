import 'package:ABM2/insertread.dart';
import 'package:flutter/material.dart';

// Dashboard Page
class dashboardNew extends StatefulWidget {
  final String username;

  const dashboardNew({super.key, required this.username});

  @override
  State<dashboardNew> createState() => _dashboardNewState();
}

class _dashboardNewState extends State<dashboardNew> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text('Welcome, ${widget.username}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            IconButton(
              icon: const Icon(Icons.person),
              iconSize: 40,
              tooltip: 'Go to Customer Page',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ItemRead()),
                );
              },
            ),
            const Text('Customer'),
          ],
        ),
      ),
    );
  }
}
