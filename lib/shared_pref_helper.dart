import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {
  // Keys for SharedPreferences
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _usernameKey = 'username';
  static const String _clientcodeKey = 'clientcode';
  static const String _usertypeKey = 'usertype';
  static const String _clientidKey = 'clientid';
  static const String _cmpcodeKey = 'cmpcode';
  static const String _useridKey = 'userid'; // Re-added User ID key

  // Save login state, username, user type, client ID, and user ID
  static Future<void> saveLoginState(
      String username, String usertype, String clientid, String clientcode, String cmpcode, String userid, bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_clientcodeKey, clientcode);
    await prefs.setString(_usertypeKey, usertype);
    await prefs.setString(_clientidKey, clientid);
    await prefs.setString(_cmpcodeKey, cmpcode);
    await prefs.setString(_useridKey, userid); // Save User ID
  }

  // Debug Function to Print All Stored Data
  static Future<void> debugSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    print('DEBUG - SharedPreferences Values:');
    print('---------------------------------');
    print('Is Logged In: ${prefs.getBool(_isLoggedInKey)}');
    print('Username: ${prefs.getString(_usernameKey)}');
    print('Client Code: ${prefs.getString(_clientcodeKey)}');
    print('Company Code: ${prefs.getString(_cmpcodeKey)}');
    print('User Type: ${prefs.getString(_usertypeKey)}');
    print('Client ID: ${prefs.getString(_clientidKey)}');
    print('User ID: ${prefs.getString(_useridKey)}'); // Print User ID
    print('---------------------------------');
  }

  // Individual getters
  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<String?> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  static Future<String?> getClientCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clientcodeKey);
  }

  static Future<String?> getUsertype() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usertypeKey);
  }

  static Future<String?> getClientId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clientidKey);
  }

  static Future<String?> getCmpCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cmpcodeKey);
  }

  static Future<String?> getUserid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_useridKey); // Retrieve User ID
  }

  // Clear login state (for logout)
  static Future<void> clearLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_usertypeKey);
    await prefs.remove(_clientidKey);
    await prefs.remove(_cmpcodeKey);
    await prefs.remove(_clientcodeKey);
    await prefs.remove(_useridKey); // Clear User ID
  }
}
