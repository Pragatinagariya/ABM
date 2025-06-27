import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class ThemeProvider with ChangeNotifier {
  Color _themeColor = Colors.blue; // Default color

  Color get themeColor => _themeColor;

  void setThemeColor(Color color) {
    _themeColor = color;
    _storeColorInDatabase(color);
    notifyListeners(); // Notify all widgets
  }

  Future<void> _storeColorInDatabase(Color color) async {
    final db = await _openDatabase();
    String colorHex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

    await db.insert(
      'z_settings',
      {
        'z_page': 'General',
        'z_keyword': 'theme_color',
        'z_keyvalue': 1,
        'z_remarks': colorHex,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.close();
  }

  Future<void> loadColorFromDatabase() async {
    final db = await _openDatabase();

    List<Map<String, dynamic>> result = await db.query(
      'z_settings',
      where: 'z_page = ? AND z_keyword = ?',
      whereArgs: ['General', 'theme_color'],
    );

    if (result.isNotEmpty) {
      String colorHex = result.first['z_remarks'];
      _themeColor = Color(int.parse('0xFF${colorHex.substring(1)}'));
    }

    await db.close();
    notifyListeners(); // Update UI
  }

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
}
