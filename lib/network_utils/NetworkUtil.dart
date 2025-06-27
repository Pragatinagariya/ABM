import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ABM2/api_base_response/api_response.dart';
import 'package:ABM2/api_base_response/parsed_response.dart';

import 'package:ABM2/utils/logger_util.dart';
import '../utils/language_constant.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;

class NetworkUtil {
  // Singleton pattern
  static final NetworkUtil _instance = NetworkUtil.internal();
  NetworkUtil.internal();
  factory NetworkUtil() => _instance;

  static const int NO_INTERNET = 404;
  static const String BASE_URL = "http://intern.amisys.in:3000/unit/";
  static const String TOKEN = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
      // shortened for clarity
      ;

  // GET method
  Future<ParsedResponse<dynamic>> getNodeUrlSecond(String uri,
      {Map? headers}) async {
    var connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      PackageInfo info = await PackageInfo.fromPlatform();
      DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      String? deviceID;

      try {
        if (Platform.isAndroid) {
          var build = await deviceInfoPlugin.androidInfo;
          deviceID = build.id.toString();
        } else if (Platform.isIOS) {
          var data = await deviceInfoPlugin.iosInfo;
          deviceID = data.identifierForVendor.toString();
        }
      } catch (e) {
        Logger.get().log('Failed to get platform version');
      }

      try {
        return http
            .get(
              Uri.parse(uri),
              headers: {
                "Language-Code": "en",
                "App-Version": info.version,
                "Authorization": TOKEN,
              },
            )
            .timeout(const Duration(seconds: 30))
            .then((http.Response response) {
              Logger.get().log("Response status: ${response.statusCode}");
              Logger.get().log("Response body: ${response.body}");

              if (response.statusCode < 200 || response.statusCode >= 300) {
                return ParsedResponse(
                  response.statusCode,
                  json.decode(json.encode(
                      ApiResponse(0, LANG_CONST.SOMETHING_WRONG_ERROR_MSG as String?)
                          .toJson())),
                );
              }

              dynamic jsonResponse = json.decode(response.body);
              return ParsedResponse(response.statusCode, jsonResponse);
            })
            .catchError((error) {
              Logger.get().log("Response Error: ${error.toString()}");
              return ParsedResponse(500, LANG_CONST.SOMETHING_WRONG_ERROR_MSG);
            });
      } on TimeoutException {
        Logger.get().log("Timeout Exception");
        return getExceptionResp(408, LANG_CONST.SOMETHING_WRONG_ERROR_MSG as String);
      } on Exception {
        return getExceptionResp(
            NO_INTERNET, LANG_CONST.SOMETHING_WRONG_ERROR_MSG as String);
      }
    } else {
      return getExceptionResp(NO_INTERNET, LANG_CONST.NETWORK_NOT_AVAILABLE as String);
    }
  }

  ParsedResponse<dynamic> getExceptionResp(int statusCode, String message) {
    ApiResponse apiResponse = ApiResponse(0, message);
    String jsonString = json.encode(apiResponse.toJson());
    return ParsedResponse(statusCode, json.decode(jsonString));
  }

  Future<bool> setWorkingBaseUrl() async {
    return getServerUrl().then((appBaseUrl) async {
      try {
        String url = "${appBaseUrl}user/app_base_url";
        Logger.get().log('Actual Base Url $url');
        var response =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
        Logger.get().log('Working Base Url ${response.body}');
        return true;
      } on TimeoutException {
        Logger.get().log('Switch Base Url $BASE_URL');
        return false;
      }
    });
  }

  Future<String> getServerUrl() async {
    return BASE_URL;
  }
}
