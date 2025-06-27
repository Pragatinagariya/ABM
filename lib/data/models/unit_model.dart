// data/models/unit_model.dart

class UnitModel {
  final String umId;
  final String umMacId;
  final String umRecId;
  final String umUserId;
  final String umUnitCode;
  final String umUnit;
  final String umRemarks;

  UnitModel({
    required this.umId,
    required this.umMacId,
    required this.umRecId,
    required this.umUserId,
    required this.umUnitCode,
    required this.umUnit,
    required this.umRemarks,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
  return UnitModel(
    umId: json['UM_Id'].toString(),
    umMacId: json['UM_MacId'].toString(),
    umRecId: json['UM_RecId'].toString(),
    umUserId: json['UM_UserId'].toString(),
    umUnitCode: json['UM_UnitCode'] ?? '',
    umUnit: json['UM_Unit'] ?? '',
    umRemarks: json['UM_Remarks'] ?? '', // 👈 This is important
  );
}
Map<String, dynamic> toJson() => {
  'UM_Id': umId,
  'UM_MacId': umMacId,
  'UM_RecId': umRecId,
  'UM_UserId': umUserId,
  'UM_UnitCode': umUnitCode,
  'UM_Unit': umUnit,
  'UM_Remarks': umRemarks,
};


}
