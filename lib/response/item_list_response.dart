class ItemModel {
  int? iMItemId;        // Changed from String? to int?
  String? iMItemCode;
  String? iMItemName;
  String? iMItemAlias;
  double? iMSRate1;     // Changed from String? to double?
  String? iMFlag;
  String? iMGroupName;
  double? iMPRate1;     // Changed from String? to double?
  String? iMExtra5;
  String? uMUnitCode;
  String? iMHSNCode;

  ItemModel({
    this.iMItemId,
    this.iMItemCode,
    this.iMItemName,
    this.iMItemAlias,
    this.iMSRate1,
    this.iMFlag,
    this.iMGroupName,
    this.iMPRate1,
    this.iMExtra5,
    this.uMUnitCode,
    this.iMHSNCode,
  });

  ItemModel.fromJson(Map<String, dynamic> json) {
    iMItemId = json['IM_ItemId'] is int ? json['IM_ItemId'] : int.tryParse(json['IM_ItemId']?.toString() ?? '');
    iMItemCode = json['IM_ItemCode'];
    iMItemName = json['IM_ItemName'];
    iMItemAlias = json['IM_ItemAlias'];

    // Convert to double safely
    iMSRate1 = json['IM_SRate1'] is double
        ? json['IM_SRate1']
        : double.tryParse(json['IM_SRate1']?.toString() ?? '0');

    iMFlag = json['IM_Flag'];
    iMGroupName = json['IM_GroupName'];

    iMPRate1 = json['IM_PRate1'] is double
        ? json['IM_PRate1']
        : double.tryParse(json['IM_PRate1']?.toString() ?? '0');

    iMExtra5 = json['IM_Extra5'];
    uMUnitCode = json['UM_UnitCode'];
    iMHSNCode = json['IM_HSNCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['IM_ItemId'] = iMItemId;
    data['IM_ItemCode'] = iMItemCode;
    data['IM_ItemName'] = iMItemName;
    data['IM_ItemAlias'] = iMItemAlias;
    data['IM_SRate1'] = iMSRate1;
    data['IM_Flag'] = iMFlag;
    data['IM_GroupName'] = iMGroupName;
    data['IM_PRate1'] = iMPRate1;
    data['IM_Extra5'] = iMExtra5;
    data['UM_UnitCode'] = uMUnitCode;
    data['IM_HSNCode'] = iMHSNCode;
    return data;
  }
}
