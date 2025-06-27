import 'dart:async';
import 'package:ABM2/main.dart';
import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'dashboard_Admin.dart';
import 'shared_pref_helper.dart';
import 'globals.dart' as globals;
 // Make sure this import points to your actual login page

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    _loadDataAndNavigate();
  }

  Future<void> _loadDataAndNavigate() async {
    // Fetch login state and saved details
    bool isLoggedIn = await SharedPrefHelper.isLoggedIn();
    String? username = await SharedPrefHelper.getUsername();
    String? usertype = await SharedPrefHelper.getUsertype();
    String? userid = await SharedPrefHelper.getUserid();
    String? clientid = await SharedPrefHelper.getClientId();
    String? clientcode = await SharedPrefHelper.getClientCode();
    String? cmpcode = await SharedPrefHelper.getCmpCode();

    // Store in globals
    globals.username = username ?? '';
    globals.userid = userid ?? '';
    globals.usertype = usertype ?? '';
    globals.clientid = clientid ?? '';
    globals.clientcode = clientcode ?? '';
    globals.cmpcode = cmpcode ?? '';

    // Show splash screen for a short time
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Navigate based on login state
    if (isLoggedIn && userid != null && userid.isNotEmpty) {
      // Logged in → go to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => globals.usertype == 'admin'
              ? HomeScreenAdmin(
                  username: globals.username,
                  clientid: globals.clientid,
                )
              : HomeScreen(
                  username: globals.username,
                  clientid: globals.clientid,
                  orders: orders,
                ),
        ),
      );
    } else {
      // Not logged in → go to login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/icons/Pragati.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            Image.asset(
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
