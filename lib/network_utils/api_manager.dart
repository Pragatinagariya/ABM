// import 'dart:async';

// import 'package:ABM2/api_base_response/api_response.dart';
// import 'package:ABM2/api_base_response/parsed_response.dart';
// import 'package:ABM2/network_utils/NetworkUtil.dart';
// import 'package:ABM2/response/item_list_response.dart';

// class ApiManager {
//   static final ApiManager _apiManager = ApiManager._internal();

//   static ApiManager get() {
//     return _apiManager;
//   }

//   ApiManager._internal();

//   final NetworkUtil _netUtil = NetworkUtil();

//   Future<ParsedResponse<ItemListResponse>> getItemListData(
//     String uri,
//     String pageNumber,
//   ) async {
//     return _netUtil.getNodeUrlSecond(uri).then((response) {
//       try {
//         if (response.body != null && response.body is List) {
//           List<ItemModel> items = (response.body as List)
//               .map((item) => ItemModel.fromJson(item))
//               .toList();

//           return ParsedResponse(
//               response.statusCode, ItemListResponse(data: items));
//         } else {
//           throw Exception("Invalid response format");
//         }
//       } catch (e) {
//         print("❌ Parsing error: $e");
//         return ParsedResponse(
//             500, ItemListResponse(data: [])); // handle empty fallback
//       }
//     });
//   }
// }
