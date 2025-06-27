import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';



class ActivityUtil {

  static Future<bool> isInternetAvailable() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      return true;
    } else {
      return false;
    }
  }

  static showSnackBarGetX(BuildContext context, String messageKey,
      {int? lenth}) {
    if (messageKey.isNotEmpty) {
      String message = messageKey;

      Get.showSnackbar(GetSnackBar(
        //  message: messageKey,
        message: message,
        duration: const Duration(seconds: 2),
        isDismissible: true,
      ));
    }
  }

  static showToast(String messageKey) {
    if (messageKey.isNotEmpty) {
      String message = messageKey;
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        // gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,

        // backgroundColor: Colors.white,
        // textColor: AppColors.lightBlack
        gravity: ToastGravity.BOTTOM,
        // timeInSecForIos: 1,
      );
    }
  }
 static String formatDate(String dateTimeStr) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeStr).toLocal(); // Convert to local time
      return DateFormat('yyyy-MM-dd').format(dateTime); // Output: 2024-04-29
    } catch (e) {
      return "Invalid Date";
    }
  }


 static String getJobNumber(Map<String, dynamic> item) {
    String prefix = item["IM_Prefix"] ?? "";
    String invoiceNo = item["IM_InvoiceNo"] ?? "N/A";
    return "$prefix" "_" "$invoiceNo";   // Jo_132839
  }
  static Color getCardColor(Map<String, dynamic> item) {
    print("Raw RefQty: ${item["om_refqty"]}, Raw PendingQty: ${item["om_pendingqty"]}");

    double refQty = double.tryParse(item["om_refqty"]?.toString().trim() ?? "0") ?? 0.0;
    double pendingQty = double.tryParse(item["om_pendingqty"]?.toString().trim() ?? "0") ?? 0.0;

    print("Parsed RefQty: $refQty, Parsed PendingQty: $pendingQty");

    if (refQty == 0) {
      return Colors.pink.shade100; // Pink when RefQty = 0
    } else if (refQty > 0 && pendingQty > 0) {
      return Colors.blue.shade100; // Blue when RefQty > 0 and PendingQty > 0
    } else if (pendingQty == 0) {
      return Colors.green.shade100; // Green when PendingQty = 0
    }

    return Colors.white;  // Default
  }




}
