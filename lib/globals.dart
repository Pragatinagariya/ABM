// globals.dart
library;

import 'package:flutter/material.dart';

String username = '';
String usertype = '';
String usermobile = '';
String useremail = '';
String clientid = '';
String userid = '';
String cmpid = '';
String cmpcode = '';
String cmpname = '';
String clientname = '';
String clientcode = '';
String token = '';
Map<String, String> companyTokens = {}; // ✅ Fix declaration

String xyz = cmpcode.toLowerCase();
String uriname = 'https://abm99.amisys.in/android/PHP/v2/';

String baseImageUrl =
    'https://abm99.amisys.in/android/PHP/v2/$clientcode/$cmpcode/Images/Items/';
Color themeColor = Colors.orange;

ValueNotifier<Color> themeColorNotifier = ValueNotifier(Colors.teal);
// class global {
//   static String clientid = '';
//   static String clientcode = '';
//   static String userid = '';
//   static String username = '';
//   static String usermobile = '';
//   static String useremail = '';

//   static Company company = Company();
// }

// class Company {
//   String currentcmpid = '';
//   String currentcmpcode = '';
//   String currentcmpname = '';
// }
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  final swatch = <int, Color>{};
  final r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }

  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }

  return MaterialColor(color.value, swatch);
}
