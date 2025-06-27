// import 'package:flutter/material.dart';
// import 'order_master.dart';

// import 'package:flutter_riverpod/flutter_riverpod.dart';

// void navigateToScreen({
//   required BuildContext context,
//   required String screen,
//   String? username,
//   String? clientcode,
//   String? clientname,
//   Map<String, dynamic>? clientMap,
//   String? cmpcode,
//   List<Map<String, dynamic>>? orders,
// })  {
//   if (screen == 'order_master') {
//     if (username != null &&
//         clientcode != null &&
//         clientname != null &&
//         clientMap != null &&
//         cmpcode != null &&
//         orders != null) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => OrderMaster(
//             username: username,
//             clientcode: clientcode,
//             clientname: clientname,
//             clientMap: clientMap,
//             cmpcode: cmpcode,
//             orders: orders,
//           ),
//         ),
//       );
//     }
//   }
// }
