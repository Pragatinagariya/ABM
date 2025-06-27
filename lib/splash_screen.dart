import 'dart:async';
import 'package:ABM2/dashboard.dart';

import 'main.dart';
import 'package:flutter/material.dart';
import 'dashboard_Admin.dart';
// import 'package:abm_agency/login_page.dart';  // import your login page
import 'shared_pref_helper.dart'; // your shared prefs helper
import 'globals.dart' as globals;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadDataAndNavigate();
  }

  List<Map<String, dynamic>> orders = [];
  Future<void> _loadDataAndNavigate() async {
    // Fetch all shared preferences asynchronously
    bool isLoggedIn = await SharedPrefHelper.isLoggedIn();
    String? username = await SharedPrefHelper.getUsername();
    String? usertype = await SharedPrefHelper.getUsertype();
    String? userid = await SharedPrefHelper.getUserid();
    String? clientid = await SharedPrefHelper.getClientId();
    String? clientcode = await SharedPrefHelper.getClientCode();
    String? cmpcode = await SharedPrefHelper.getCmpCode();

    // Set global vars if needed
    globals.username = username ?? '';
    globals.userid = userid ?? '';
    globals.usertype = usertype ?? '';
    globals.clientid = clientid ?? '';
    globals.clientcode = clientcode ?? '';
    globals.cmpcode = cmpcode ?? '';

    // Wait for 3 seconds to show splash screen
    await Future.delayed(const Duration(seconds: 10));

    // Navigate to the correct page
    if (!mounted) return; // Check widget is still mounted before navigating

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => globals.usertype == 'admin'
              ? HomeScreenAdmin(
                  username: globals.username,
                  clientid: '',
                )
              : HomeScreen(
                  username: globals.username,
                  clientid: globals.clientid,
                  orders: orders),
        ));
  }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Image.asset(
//           'assets/images/icons/app_icon.png',
//           width: 150,
//           height: 150,
//         ),
//       ),
//     );
//   }
// }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              // 'assets/images/icons/amisys.png',
              'assets/images/icons/Pragati.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20), // spacing between images
            Image.asset(
              // 'assets/images/icons/Pragati.png', // replace with your actual image path
              'assets/images/icons/amisys.png',
              width: 150,
              height: 150,
            ),
          ],
        ),
      ),
    );
  }
}
