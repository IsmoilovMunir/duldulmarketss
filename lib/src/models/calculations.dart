import '../helpers/custom_trace.dart';

class Calculations {
  String subTotal;
  String discount;
  String fee;
  String tax;
  String total;
  String readyBy;

  Calculations();

  Calculations.fromJSON(Map<String, dynamic> jsonMap) {
    try {
      subTotal = jsonMap['sub_total'].toString();
      discount =
          jsonMap['discount'] != null ? jsonMap['discount'].toString() : null;
      fee = jsonMap['delivery_fee'] != null
          ? jsonMap['delivery_fee'].toString()
          : null;
      tax = jsonMap['default_tax'] != null
          ? jsonMap['default_tax'].toString()
          : null;
      total = jsonMap['total'] != null ? jsonMap['total'].toString() : null;
      readyBy = jsonMap['ready_by_date'] != null
          ? jsonMap['ready_by_date'].toString()
          : null;
    } catch (e) {
      subTotal = '';
      discount = '';
      fee = '';
      tax = '';
      total = '';
      readyBy = '';
      print(CustomTrace(StackTrace.current, message: e));
    }
  }

  Map toMap() {
    var map = new Map<String, dynamic>();
    map["sub_total"] = subTotal;
    map["discount"] = discount;
    map["delivery_fee"] = fee;
    map["default_tax"] = tax;
    map["total"] = total;
    return map;
  }
}
