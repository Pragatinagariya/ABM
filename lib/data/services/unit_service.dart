// data/services/unit_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/unit_model.dart';

class UnitService {
  final String baseUrl = 'http://intern.amisys.in:3000';
final String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjbXBjb2RlIjoiSE5GIiwiY21wbmFtZSI6IkhOIEZhc2hpb24iLCJjbXBpZCI6NiwiY2xpZW50SWQiOjk5LCJjbGllbnRjb2RlIjoiNmQwOTkiLCJpYXQiOjE3NDUzMjUzNDUsImV4cCI6MTc0NTMyODk0NX0.4WCoYcadJQDZOSzlWFfLiQP59HQ0BAHyWcx1ExgqrcU';
 Future<List<UnitModel>> fetchUnits() async {
  

  final response = await http.get(
    Uri.parse('$baseUrl/unit'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print("Status Code: ${response.statusCode}");
  print("Response Body: ${response.body}");

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonResponse = json.decode(response.body);

    if (jsonResponse.containsKey('data')) {
      final List unitsList = jsonResponse['data'];
      return unitsList.map((e) => UnitModel.fromJson(e)).toList();
    } else {
      throw Exception("Key 'data' not found in response");
    }
  } else {
    throw Exception('Failed to fetch units: ${response.body}');
  }
}
Future<bool> insertUnit(UnitModel unit) async {
  final url = Uri.parse('$baseUrl/unit/insert');
  final headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
  final body = jsonEncode(unit.toJson());

  final response = await http.post(url, headers: headers, body: body);

  print("Insert Status: ${response.statusCode}");
  print("Insert Response: ${response.body}");

  if (response.statusCode == 200 || response.statusCode == 201) {
    return true;
  } else {
    throw Exception('Insert failed: ${response.body}');
  }
}

}
