import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

class QueryBuilder {
  QueryBuilder(this.querySpec);

  dynamic querySpec;

  Query? build() {
    Query? query = makeCollRef();
    if (query == null)
      return null;
    else {
      querySpec["orderBy"]?.forEach((e) => query = addOrderBy(query!, e));
      querySpec["where"]?.forEach((e) => query = addFilter(query!, e));
    }
    int? limit = querySpec["limit"];
    if (limit != null) query = query?.limit(limit);

    return query;
  }

  Query? makeCollRef() {
    String? collection = querySpec["collection"];
    String? collectionGroup = querySpec["collectionGroup"];
    if (collection != null) {
      CollectionReference c = db.collection(collection);
      querySpec["subCollections"]?.forEach(
              (e) => c = c.doc(e["document"]).collection(e["collection"]));
      return c;
    } else if (collectionGroup != null) {
      return db.collectionGroup(collectionGroup);
    } else {
      return null;
    }
  }

  Query addFilter(Query query, dynamic filter) {
    dynamic parseValue(String op, var value) {
      if (op == "boolean") return value == "true";
      if (op == "number") return num.parse(value);
      if (op == "string") return value as String;
      if (op == "list<string>") return value.map((e) => e as String).toList();
      return null;
    }

    String filterOp = filter["op"];
    String field = filter["field"];
    String type = filter["type"];
    dynamic value = filter["value"];
    dynamic values = filter["values"];

    if (filterOp == "sort") {
      return query.orderBy(field, descending: value == "true");
    } else if (filterOp == "==") {
      return query.where(field, isEqualTo: parseValue(type, value));
    } else if (filterOp == "!=") {
      return query.where(field, isNotEqualTo: parseValue(type, value));
    } else if (filterOp == ">=") {
      return query.where(field,
          isGreaterThanOrEqualTo: parseValue(type, value));
    } else if (filterOp == "<=") {
      return query.where(field, isLessThanOrEqualTo: parseValue(type, value));
    } else if (filterOp == ">") {
      return query.where(field, isGreaterThan: parseValue(type, value));
    } else if (filterOp == "<") {
      return query.where(field, isLessThan: parseValue(type, value));
    } else if (filterOp == "notIn") {
      return query.where(field, whereNotIn: parseValue(type, value));
    } else if (filterOp == "in") {
      return query.where(field, whereIn: parseValue(type, values));
    } else if (filterOp == "contains") {
      return query.where(field, arrayContains: parseValue(type, value));
    } else if (filterOp == "containsAny") {
      return query.where(field, arrayContainsAny: parseValue(type, values));
    } else {
      throw Exception();
    }
  }

  Query addOrderBy(Query query, dynamic order) =>
      query.orderBy(order["field"], descending: order["descending"] == true);
}
