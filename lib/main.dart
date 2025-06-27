import 'package:ABM2/dashboard_Admin.dart';
import 'package:ABM2/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'shared_pref_helper.dart'; // Import the shared preferences helper
import 'globals.dart' as globals;
import 'dashboard.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Import for app version
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'order_master.dart';

bool _keepLoggedIn = false;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// For background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔵 Handling a background message: ${message.messageId}');
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Init local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Check login state
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

  List<Map<String, dynamic>> orders = [];

  runApp(
    ProviderScope(
      child: MyApp(
        isLoggedIn: isLoggedIn,
        username: username,
        usertype: usertype,
        userid: userid,
        clientid: clientid,
        orders: orders,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final String? username;
  final String? usertype;
  final String? clientid;
  final String? userid;
  final List<Map<String, dynamic>> orders;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    this.username,
    this.usertype,
    this.userid,
    this.clientid,
    required this.orders,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _loadColorFromDatabase(); // 🔴 Call it before runApp
    _setupFCM();

    getToken();
  }

  Future<void> _loadColorFromDatabase() async {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase('$dbPath/z_settings.db');
    final result = await db.query(
      'z_settings',
      where: 'z_page = ? AND z_keyword = ?',
      whereArgs: ['General', 'theme_color'],
    );

    if (result.isNotEmpty) {
      Object? colorHex = result.first['z_remarks'];
      Color loadedColor = Color(int.parse('0xFF$colorHex'));
      globals.themeColorNotifier.value = loadedColor;
    }

    await db.close();
  }

  void _initializeLocalNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        print('🔔 Notification tapped with payload: $payload');
        if (payload != null) {
          _handleNotificationPayload(payload);
        }
      },
    );
  }

  void _handleNotificationPayload(String payload) {
    print('📦 Payload received: $payload');

    if (payload == 'order_master') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => OrderMaster(
            username: globals.username,
            clientcode: globals.clientcode,
            clientname: globals.username,
            clientMap: "",
            cmpcode: globals.cmpcode,
            orders: [], // or pass as needed
          ),
        ),
      );
    } else {
      print('⚠️ No valid screen from local notification payload.');
    }
  }

  void getToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      print("🔐 Your FCM Token is: $token");

      String cuId = globals.userid;
      final response = await http.post(
        Uri.parse('https://abm99.amisys.in/android/PHP/v2/firebase_token.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cu_id': cuId,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Token sent successfully.");
      } else {
        print("❌ Failed to send token.");
      }
    } else {
      print("❌ Permission not granted.");
    }
  }

  void _setupFCM() async {
    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📲 Foreground message: ${message.notification?.title}');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: message.data['screen'],
        );
      }
    });

    // Background (when tapped)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🟡 App opened from background notification: ${message.data}');
      _handleNotificationNavigation(message);
    });

    // Terminated state
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print('🔴 App opened from terminated state via notification');
      _handleNotificationNavigation(initialMessage);
    }
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    final screen = message.data['screen'];
    print('🔍 Navigating based on screen: $screen');

    if (screen != null) {
      if (screen == 'order_master') {
        // Defer navigation until the widget tree is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => OrderMaster(
                username: globals.username,
                clientcode: globals.clientcode,
                clientname: globals.username,
                clientMap: "",
                cmpcode: globals.cmpcode,
                orders: widget.orders,
              ),
            ),
          );
        });
      } else {
        print('⚠️ No valid screen found in payload: $screen');
      }
    } else {
      print('⚠️ No screen data in the notification payload.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
        valueListenable: globals.themeColorNotifier,
        builder: (context, color, _) {
          print('Building MaterialApp with color: $color'); // Debug print

          // renamed to 'color'
          return MaterialApp(
            title: 'Login Demo',
            theme: ThemeData(
              primaryColor: color,
              primarySwatch: globals.createMaterialColor(color),
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            navigatorKey: navigatorKey,
            home: SplashScreen(),
          );
        });
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

  Future<bool> _checkLoginTime(
      String userid, String username, String clientcode, String cmpcode) async {
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
      const SnackBar(
          content: Text('Please enter both username and password')),
    );
    return;
  }

  var url = Uri.parse('${globals.uriname}login.php');
  print('Login URL: $url');  // Debugging URL
  print('Sending username: $username, password: $password');  // Debug

  try {
    var response = await http.post(url, body: {
      'um_username': username,
      'um_password': password,
    });

    print('Login Response status: ${response.statusCode}');  // Debug
    print('Login Response body: ${response.body}');  // Debug

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
        print('Client Name: ${globals.clientname}');
        print('User Email: ${globals.useremail}');
        print('User Mobile: ${globals.usermobile}');
        print('==================================');

        // Save login state if "Keep me logged in" is checked
        if (_keepLoggedIn) {
          print('Saving login state...');
          await SharedPrefHelper.saveLoginState(
              globals.username,
              globals.usertype,
              globals.clientid,
              globals.clientcode,
              globals.cmpcode,
              globals.userid,
              true);
        }

        // Fetch app version
        String appVersion = await getAppVersion();
        print('App version: $appVersion');

        // Show the version in a Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Login successful! App version: $appVersion')),
        );

        List<Map<String, dynamic>> orders = [];

        print('Navigating to ${globals.usertype == 'admin' ? 'HomeScreenAdmin' : 'HomeScreen'}');

        // Navigate to dashboard
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
        setState(() {
          _isLoading = false;
        });
        print('Login failed: ${data['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(data['message'] ?? 'Invalid username or password')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      print('Server error: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Server error. Please try again later.')),
      );
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    print('Login Exception: $e');
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
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
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.black,
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
