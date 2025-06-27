import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'globals.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  _GeneralSettingsPageState createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  Color _tempColor = themeColorNotifier.value;

  @override
  void initState() {
    super.initState();
    _loadColorFromDatabase();
  }

  String _colorToHex(Color color) {
    return color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }

  Future<Database> _openDatabase() async {
    String path = p.join(await getDatabasesPath(), 'z_settings.db');
    if (kDebugMode) {
      print(path);
    }
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

  Future<void> _storeColorInDatabase(Color color) async {
    final db = await _openDatabase();
    String colorHex = _colorToHex(color);

    List<Map<String, dynamic>> existingRecord = await db.query(
      'z_settings',
      where: 'z_page = ? AND z_keyword = ?',
      whereArgs: ['General', 'theme_color'],
    );

    if (existingRecord.isEmpty) {
      await db.insert('z_settings', {
        'z_page': 'General',
        'z_keyword': 'theme_color',
        'z_remarks': colorHex,
      });
    } else {
      await db.update(
        'z_settings',
        {'z_remarks': colorHex},
        where: 'z_page = ? AND z_keyword = ?',
        whereArgs: ['General', 'theme_color'],
      );
    }

    await db.close();
  }

  Future<void> _loadColorFromDatabase() async {
    final db = await _openDatabase();
    List<Map<String, dynamic>> result = await db.query(
      'z_settings',
      where: 'z_page = ? AND z_keyword = ?',
      whereArgs: ['General', 'theme_color'],
    );

    if (result.isNotEmpty) {
      String colorHex = result.first['z_remarks'];
      Color loadedColor = Color(int.parse('0xFF$colorHex'));
      themeColorNotifier.value = loadedColor;

      setState(() {
        _tempColor = loadedColor; // <-- update tempColor too
      });
    }

    await db.close();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: themeColorNotifier,
      builder: (context, currentColor, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('General Settings'),
            backgroundColor: currentColor,
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
                  subtitle:
                      Text('Current color: #${_colorToHex(currentColor)}'),
                  onTap: () {
                    _tempColor = currentColor;
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Pick a color'),
                          content: MaterialPicker(
                            pickerColor: _tempColor,
                            onColorChanged: (color) {
                              setState(() {
                                _tempColor = color;
                              });
                            },
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text('OK'),
                              onPressed: () {
                                print('Selected color: $_tempColor');
                                themeColorNotifier.value = _tempColor;
                                _storeColorInDatabase(_tempColor);
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
      },
    );
  }
}
