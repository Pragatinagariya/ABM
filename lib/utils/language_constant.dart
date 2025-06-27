class LANG_CONST {
  final _value;

  const LANG_CONST._internal(this._value);

  @override
  toString() => '$_value';

  static const SOMETHING_WRONG_ERROR_MSG =
      LANG_CONST._internal("something_wrong_error_msg");

  static const NETWORK_NOT_AVAILABLE =
      LANG_CONST._internal("network_not_available");
  static const UNIT_LIST = LANG_CONST._internal("unit_list");
  static const QR_CODE = LANG_CONST._internal("qr_code");
  static const ADD_UNIT = LANG_CONST._internal("add_unit");
  static const LOGIN = LANG_CONST._internal("login");
  //add new unit
  static const ORDER_NO = LANG_CONST._internal("Order No.");
  static const ORDER_DATE = LANG_CONST._internal("Order Date");
  static const UM_ID = LANG_CONST._internal("UM ID");
  static const UM_MAC_ID = LANG_CONST._internal("UM MAC ID");
  static const UM_REC_ID = LANG_CONST._internal("UM REC ID");
  static const UM_USER_ID = LANG_CONST._internal("UM USR ID");
  static const UM_UNIT_CODE = LANG_CONST._internal("UM UNIT CODE");
  static const UM_UNIT = LANG_CONST._internal("UM UNIT");
  static const UM_REMARK = LANG_CONST._internal("UM REMARK");
}
