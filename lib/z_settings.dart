import 'package:flutter/material.dart';
import 'add_data.dart';
import 'globals.dart'; // Import themeColorNotifier
import 'general_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: themeColorNotifier,
      builder: (context, color, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: color,
          ),
          body: Column(
            children: [
              ListTile(
                leading: Icon(Icons.settings, color: color),
                title: const Text(
                  'General',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GeneralSettingsPage()),
                  );
                },
              ),
              const Divider(),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddDataPage()),
              );
            },
            backgroundColor: color,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
