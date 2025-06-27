import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('General Settings'),
        backgroundColor: themeProvider.themeColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Theme Color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              title: const Text('Pick Theme Color'),
              subtitle: Text('Current color: ${themeProvider.themeColor}'),
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Pick a color'),
                      content: MaterialPicker(
                        pickerColor: themeProvider.themeColor,
                        onColorChanged: (color) {
                          themeProvider.setThemeColor(color); // Update and save color
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
