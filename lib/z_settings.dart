import 'package:flutter/material.dart';
import 'add_data.dart'; // Import the AddDataPage
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'globals.dart';  // Import global variables
import 'package:sqflite/sqflite.dart'; // Import database package
import 'package:path/path.dart' as p; // Import for database path


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: themeColor,
      ),
      body: Column(
        children: [
          ListTile(
            leading: Icon(Icons.settings, color: themeColor),
            title: Text(
              'General',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              // Navigate to General Settings Page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GeneralSettingsPage()),
              );
            },
          ),
          Divider(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddDataPage()),
          );
        },
        backgroundColor: themeColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Database helper to open the database and execute queries
Future<Database> _openDatabase() async {
  String path = p.join(await getDatabasesPath(), 'z_settings.db');

  return openDatabase(path, version: 1, onCreate: (db, version) {
    db.execute(''' 
      CREATE TABLE IF NOT EXISTS z_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        z_page TEXT,
        z_flag TEXT,
        z_keyword TEXT,
        z_keyvalue INTEGER,
        z_remarks TEXT
      )
    ''');
  });
}

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  _GeneralSettingsPageState createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  Color _currentColor = themeColor; // Default color

  // Helper method to convert color to hex code
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  // Function to store or update color in SQLite database
  Future<void> _storeColorInDatabase(Color color) async {
    final db = await _openDatabase();

    // Convert the color to hex string
    String colorHex = _colorToHex(color);

    // Check if the record exists with the given z_page and z_keyword
    List<Map<String, dynamic>> existingRecord = await db.query(
      'z_settings',
      where: 'z_page = ? AND z_keyword = ?',
      whereArgs: ['General', 'theme_color'],
    );

    if (existingRecord.isEmpty) {
      // If the record doesn't exist, insert a new record
      await db.insert(
        'z_settings',
        {
          'z_page': 'General',
          'z_keyword': 'theme_color',
          'z_remarks': colorHex, // Store the color hex value
        },
      );
    } else {
      // If the record exists, update the z_remarks with the new color value
      await db.update(
        'z_settings',
        {
          'z_remarks': colorHex, // Update the hex value in z_remarks
        },
        where: 'z_page = ? AND z_keyword = ?',
        whereArgs: ['General', 'theme_color'],  // Specify the page and keyword for theme color
      );
    }

    // Close the database
    await db.close();
  }

  // Function to load the color from the SQLite database
  Future<void> _loadColorFromDatabase() async {
    final db = await _openDatabase();

    // Query the database to get the color (stored in z_remarks)
    List<Map<String, dynamic>> result = await db.query(
      'z_settings',
      where: 'z_page = ? AND z_keyword = ?',
      whereArgs: ['General', 'theme_color'],
    );

    if (result.isNotEmpty) {
      String colorHex = result.first['z_remarks'];
      setState(() {
        // Convert the hex string back to a Color object
        _currentColor = Color(int.parse('0xFF$colorHex'));
        themeColor = _currentColor; // Update global variable
      });
    }

    await db.close();
  }

  @override
  void initState() {
    super.initState();
    _loadColorFromDatabase();  // Load the saved color when the page is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('General Settings'),
        backgroundColor: _currentColor, // Use the current selected color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theme Color',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: const Text('Pick Theme Color'),
              subtitle: Text('Current color: ${_colorToHex(_currentColor)}'), // Display hex code
              onTap: () async {
                // Open color picker dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Pick a color'),
                      content: MaterialPicker(
                        pickerColor: _currentColor, // Set initial color
                        onColorChanged: (color) {
                          setState(() {
                            _currentColor = color; // Update the selected color
                            themeColor = color; // Update the global variable
                          });
                          // Store the new color in the database
                          _storeColorInDatabase(color);
                        },
                      ),
                      actions: [
                        TextButton(
                          child: const Text('OK'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
