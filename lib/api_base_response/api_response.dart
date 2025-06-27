import 'package:ABM2/api_base_response/base_response.dart';

class ApiResponse extends BaseResponse {
  int? status;
  String? message;

  ApiResponse(this.status, this.message);

  ApiResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    return data;
  }

  @override
  String getMessage() {
    return message!;
  }

  //no update
  @override
  bool isSuccess() {
    return status == 1;
  }

  //force update
  bool isForceUpdate() {
    return status == 2;
  }

  //soft update
  bool isSoftUpdate() {
    return status == 4;
  }
}
