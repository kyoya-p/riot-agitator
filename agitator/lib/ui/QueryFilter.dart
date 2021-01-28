import 'package:cloud_firestore/cloud_firestore.dart';

// QueryにFilterを追加する拡張関数
extension QueryOperation on Query {
  dynamic parseValue(String op, var value) {
    if (op == "boolean") return value == "true";
    if (op == "number") return num.parse(value);
    if (op == "string") return value as String;
    if (op == "list<string>") return value.map((e)=>e as String).toList();
    return null;
  }

  Query addFilters(List<dynamic> filterList) {
    return filterList.fold(this, (a, e) {
      String filterOp = e["op"];
      String field = e["field"];
      var value = e["value"];
      var values = e["values"];
      String type = e["type"];

      if (filterOp == "sort") {
        return a.orderBy(field, descending: value == "true");
      } else if (filterOp == "==") {
        return a.where(field, isEqualTo: parseValue(type, value));
      } else if (filterOp == "!=") {
        return a.where(field, isNotEqualTo: parseValue(type, value));
      } else if (filterOp == ">=") {
        return a.where(field, isGreaterThanOrEqualTo: parseValue(type, value));
      } else if (filterOp == "<=") {
        return a.where(field, isLessThanOrEqualTo: parseValue(type, value));
      } else if (filterOp == ">") {
        return a.where(field, isGreaterThan: parseValue(type, value));
      } else if (filterOp == "<") {
        return a.where(field, isLessThan: parseValue(type, value));
      } else if (filterOp == "not-in") {
        return a.where(field, whereNotIn: parseValue(type, value));
      } else if (filterOp == "in") {
        return a.where(field, whereIn: parseValue(type, values));
      } else if (filterOp == "contains") {
        return a.where(field, arrayContains: parseValue(type, value));
      } else if (filterOp == "containsAny") {
        return a.where(field, arrayContainsAny: parseValue(type, values));
      } else {
        throw Exception();
      }
    });
  }
}
