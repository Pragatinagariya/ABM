import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'shared_pref_helper.dart'; // Import the shared preferences helper
import 'globals.dart' as globals;
import 'dashboard.dart'; // Main dashboard page
import 'dashboard_Admin.dart'; // Admin dashboard
import 'package:package_info_plus/package_info_plus.dart'; // Import for app version
bool _keepLoggedIn = false;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check login state when app starts
  bool isLoggedIn = await SharedPrefHelper.isLoggedIn();
  String? username = await SharedPrefHelper.getUsername();
  String? usertype = await SharedPrefHelper.getUsertype();
  String? userid = await SharedPrefHelper.getUserid();
  
  String? clientid = await SharedPrefHelper.getClientId();
   String? clientcode = await SharedPrefHelper.getClientCode(); // Retrieve clientcode
  String? cmpcode = await SharedPrefHelper.getCmpCode();         // Retrieve cmpcode
  globals.username = username ?? '';
 globals.userid = userid ?? '';
 
  globals.usertype = usertype ?? '';
  globals.clientid = clientid ?? '';
   globals.clientcode = clientcode ?? '';  
   globals.cmpcode = cmpcode ?? '';
  List<Map<String, dynamic>> orders = [];
  // Navigate directly to the appropriate screen based on login status
  runApp(MyApp(isLoggedIn: isLoggedIn, username: username, usertype: usertype, userid: userid,clientid:clientid,orders:orders,));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? username;
  final String? usertype;
  final String? clientid;
   final String? userid;
 final List<Map<String,dynamic>> orders;
  const MyApp({super.key, required this.isLoggedIn, this.username, this.usertype,this.userid, this.clientid,required this.orders,});

 @override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Login Demo',
    theme: ThemeData(
      primaryColor: globals.themeColor,  // Use primaryColor here instead of primarySwatch
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    // Check if already logged in or navigate to LoginPage
    home: isLoggedIn
        ? (usertype == 'A'
            ? HomeScreenAdmin(username: username ?? '')
            : HomeScreen(username: username ?? '', clientid: clientid ?? '' , orders: orders))
        : const LoginPage(),
  );
}
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _keepLoggedIn = false;
  
  bool _isOtpSent = false;
  final bool _isOtpValid = false;

   // Function to fetch the app version
  Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version; // Returns app version
  }
Future<bool> _checkLoginTime(String userid, String username, String clientcode, String cmpcode) async {
  var timeCheckUrl = Uri.parse('${globals.uriname}check_login_time.php');

  try {
    var timeResponse = await http.post(timeCheckUrl, body: {
      'um_userid': userid,
      'um_username': username,
      'clientcode': clientcode,
      'cmp': cmpcode,
    });

    if (timeResponse.statusCode == 200) {
      var timeData = jsonDecode(timeResponse.body);
      if (timeData['status'] == 'success') {
        return true; // Login allowed
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(timeData['message'] ?? 'Login not allowed')),
        );
        return false; // Login not allowed
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time check failed. Please try again.')),
      );
      return false;
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Time check error: $e')),
    );
    return false;
  }
}

Future<void> _login() async {
  setState(() {
    _isLoading = true;
  });

  String username = _usernameController.text;
  String password = _passwordController.text;

  if (username.isEmpty || password.isEmpty) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter both username and password')),
    );
    return;
  }

  var url = Uri.parse('${globals.uriname}login.php');

  try {
    var response = await http.post(url, body: {
      'um_username': username,
      'um_password': password,
    });

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        // Assign values to global variables
        globals.usertype = data['usertype'] ?? 'guest';
        globals.userid = data['userid'] ?? '';
        globals.username = data['username'] ?? '';
        globals.clientid = data['clientid'] ?? '';       
        globals.clientcode = data['clientcode'] ?? '';
        globals.clientname = data['clientname'] ?? '';
        globals.useremail = data['useremail'] ?? '';
        globals.usermobile = data['usermobile'] ?? '';

        // Debugging: Print all global variables
        print('======== GLOBAL VARIABLES ========');
        print('Username: ${globals.username}');
         print('Userid: ${globals.userid}');
        print('User Type: ${globals.usertype}');
        print('Client ID: ${globals.clientid}');
        print('Client Code: ${globals.clientcode}');
         print('client name: ${globals.clientname}');
        print('User Email: ${globals.useremail}');
        print('User Mobile: ${globals.usermobile}');
        print('==================================');

        // Save login state if "Keep me logged in" is checked
        if (_keepLoggedIn) {
          await SharedPrefHelper.saveLoginState(
              globals.username, globals.usertype, globals.clientid, globals.clientcode,globals.cmpcode,globals.userid, true);
        }

          // Fetch app version
          String appVersion = await getAppVersion();

          // Show the version in a Snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login successful! App version: $appVersion')),
          );

        List<Map<String, dynamic>> orders = [];
        // Navigate to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => globals.usertype == 'admin'
                ? HomeScreenAdmin(username: globals.username)
                : HomeScreen(username: globals.username, clientid: globals.clientid, orders: orders),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Invalid username or password')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server error. Please try again later.')),
      );
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: $e')),
    );
  }
}
  Future<void> _validateCredentialsAndSendOtp() async {
  String username = _usernameController.text;
  String password = _passwordController.text;

  // Check if username and password are provided
  if (username.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Username and password cannot be empty.')),
    );
    return; // Exit the function if username or password is empty
  }

  // Validate credentials by calling the server
  var url = Uri.parse('${globals.uriname}login.php');

  try {
    var response = await http.post(url, body: {
      'um_username': username,
      'um_password': password,
    });

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        // Credentials are valid, proceed to send OTP
        await _sendOtp();
      } else {
        // Invalid username or password
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password.')),
        );
      }
    } else {
      // Server error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server error: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print("An error occurred: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: $e')),
    );
  }
}

Future<void> _sendOtp() async {
  String username = _usernameController.text;

  setState(() {
    _isLoading = true;
  });

  var url = Uri.parse('https://abm99.amisys.in/android/PHP/v2/otp_login.php');

  try {
    var response = await http.post(url, body: {
      'um_username': username,
      'action': 'send_otp',
    });

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully!')),
        );
        setState(() {
          _isOtpSent = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send OTP.')),
        );
      }
    }
  } catch (e) {
    print(e);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: $e')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _validateOtpAndLogin() async {
    setState(() {
      _isLoading = true;
    });

    String username = _usernameController.text;
    String submittedOtp = _otpController.text;

    var url = Uri.parse('https://abm99.amisys.in/android/PHP/v2/otp_login.php');

    try {
      // Validate OTP
      var response = await http.post(url, body: {
        'um_username': username,
        'l_otp': submittedOtp,
        'action': 'validate_otp',
      });

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          // OTP validation successful, now login
          await _login();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid OTP')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print("An error occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 1),
              const Text(
                'Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
              ),
                                          const SizedBox(height: 10),
              if (_isOtpSent) ...[
                TextField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
                // const SizedBox(height: 10),
           Align(
  alignment: Alignment.centerLeft, // Align to left side
  child: TextButton(
    onPressed: _sendOtp,
    child: const Text(
      'Resend OTP',
      style: TextStyle(
        color: Colors.blue,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.underline,
      ),
    ),
  ),
),
 // const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: _keepLoggedIn,
                      onChanged: (value) {
                        setState(() {
                          _keepLoggedIn = value!;
                        });
                      },
                    ),
                    const Text('Keep Me Logged In'),
                  ],
                ),
                ElevatedButton(
                  onPressed: _isOtpValid
                      ? () => _login()
                      : _validateOtpAndLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Set the background color
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                    ),
                  ),
                  child: Text(
                    _isOtpValid
                        ? 'Login'
                        : 'Login', // Change button text based on state
                    style: const TextStyle(
                      color: Colors.black, // Set text color to black
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ] else
                ElevatedButton(
                  onPressed:_validateCredentialsAndSendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Set the background color
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                    ),
                  ),
                  child: const Text(
                    'Send OTP',
                    style: TextStyle(
                      color: Colors.black, // Set text color to black
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              
              _isLoading
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}


