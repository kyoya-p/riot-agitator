import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/ListenEvent.dart';

import 'Common.dart';
import 'documentPage.dart';

class QueryViewPage extends StatelessWidget {
  QueryViewPage({
    this.query,
    this.querySpec,
    this.queryDocument,
    this.itemBuilder,
    this.appBar,
    this.floatingActionButton,
  });

  Query? query;
  dynamic? querySpec;
  DocumentReference? queryDocument;

  AppBar? appBar;
  Widget? floatingActionButton;

  Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ?? defaultAppBar(context),
      body: QueryViewWidget(
        query: query,
        querySpec: querySpec,
        queryDocument: queryDocument,
        itemBuilder: itemBuilder,
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  AppBar defaultAppBar(BuildContext context) => AppBar(
        title: Text(
            "${querySpec ?? query?.parameters ?? queryDocument?.path} - Query"),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: queryDocument != null
                ? //() => naviPush(context, (_) => DocumentPage(queryDocument!))
                () => showDocumentEditorDialog(queryDocument!, context)
                : null,
          ),
          bell(context),
        ],
      );

  FloatingActionButton defaultFloatingActionButton(
          BuildContext context, DocumentReference dRef) =>
      FloatingActionButton(
        child: Icon(Icons.note_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DocumentPage(dRef)),
          );
        },
      );
}

class QueryViewWidget extends StatelessWidget {
  QueryViewWidget({
    this.query,
    this.querySpec,
    this.queryDocument,
    this.itemBuilder,
  });

  final Query? query;
  final dynamic? querySpec;
  final DocumentReference? queryDocument;

  Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots)? itemBuilder;

  Widget defaultItemBuilder(
      BuildContext context, int index, AsyncSnapshot<QuerySnapshot> snapshots) {
    QueryDocumentSnapshot? e = snapshots.data?.docs[index];
    return Card(child: Text("$index: ${e?.id} ${e?.data()}"));
  }

  @override
  Widget build(BuildContext context) {
    if (query != null) {
      return buildBody(query!, context);
    } else if (querySpec != null) {
      return buildBody(makeQuery(querySpec), context);
    } else if (queryDocument != null) {
      return StreamBuilder<DocumentSnapshot>(
        stream: queryDocument?.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return Center(child: CircularProgressIndicator());
          }
          return buildBody(makeQuery(snapshot.data?.data()), context);
        },
      );
    } else {
      return Text("No Query Parameters.");
    }
  }

  Widget buildBody(Query query, BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshots) {
          if (!snapshots.hasData)
            return Center(child: CircularProgressIndicator());
          QuerySnapshot querySnapshotData = snapshots.data!;
          return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: w ~/ 160,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: 2.0),
              itemCount: querySnapshotData.size,
              itemBuilder: (BuildContext context, int index) {
                DocumentReference? dRef = snapshots.data?.docs[index].reference;

                return Container(
                    child: InkResponse(
                  onLongPress: () {
                    print("long");
                  },
                  child: Dismissible(
                    key: Key(querySnapshotData.docs[index].id),
                    child: itemBuilder != null
                        ? itemBuilder!(context, index, snapshots)
                        : dRef != null
                            ? buildGenericCard(context, dRef)
                            : Text("NULL"),
                    onDismissed: (_) =>
                        querySnapshotData.docs[index].reference.delete(),
                  ),
                ));
              });
        });
  }

  /*
    QuerySpecification for watchDocuments()
    {
      "collection": "collectionId",
      "subCollections": [ {"document":"documentId", "collection":"collectionId" }, ... ],
      "sort": [
        { "field": "sortFieldName",
          "decending": true // true, false
        },...
      ]
      "where": [
        { "field":"filterFieldName",
          "operator" : "==", // "==", "!=", ">", ">=", ">", ">=", "contains"
          "type": "number", // "number", "string", "boolean", "list<string>"
          "value": "fieldValue", // if with scalor-operator
        },
        { "field":"fieldName",
          "operator" : "in", // "in", "notIn", "containsAny"
          "type": "number", // "number", "string", "boolean", "list<string>"
          "values": ["fieldValue1","value2",...] // if with list-operator
        }, ...
      ],

      "limit": 100
    }
  */
  Query makeQuery(dynamic querySpec) {
    FirebaseFirestore db = FirebaseFirestore.instance;
    Query query = db.collection(querySpec["collection"]);
    querySpec["orderBy"]?.forEach((e) {
      query = query.orderBy(e["field"], descending: e["descending"] == true);
    });
    query = querySpec["where"]?.toList().fold(query, (a, e) => a.addFilter(e));
    return query;
  }

  AppBar defaultAppBar(BuildContext context) => AppBar(
      title: Text("${querySpec.parameters} - Query"), actions: [bell(context)]);

  FloatingActionButton defaultFloatingActionButton(
          BuildContext context, DocumentReference dRef) =>
      FloatingActionButton(
        child: Icon(Icons.note_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DocumentPage(dRef)),
          );
        },
      );
}

// Query作成を補助する拡張関数
extension QueryOperation on Query {
  Query addFilter(dynamic filter) {
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
      return orderBy(field, descending: value == "true");
    } else if (filterOp == "==") {
      return where(field, isEqualTo: parseValue(type, value));
    } else if (filterOp == "!=") {
      return where(field, isNotEqualTo: parseValue(type, value));
    } else if (filterOp == ">=") {
      return where(field, isGreaterThanOrEqualTo: parseValue(type, value));
    } else if (filterOp == "<=") {
      return where(field, isLessThanOrEqualTo: parseValue(type, value));
    } else if (filterOp == ">") {
      return where(field, isGreaterThan: parseValue(type, value));
    } else if (filterOp == "<") {
      return where(field, isLessThan: parseValue(type, value));
    } else if (filterOp == "notIn") {
      return where(field, whereNotIn: parseValue(type, value));
    } else if (filterOp == "in") {
      return where(field, whereIn: parseValue(type, values));
    } else if (filterOp == "contains") {
      return where(field, arrayContains: parseValue(type, value));
    } else if (filterOp == "containsAny") {
      return where(field, arrayContainsAny: parseValue(type, values));
    } else {
      throw Exception();
    }
  }

  Query addFilters(dynamic filterList) =>
      filterList.toList().fold(this, (a, e) => a.addFilter(e));
}
