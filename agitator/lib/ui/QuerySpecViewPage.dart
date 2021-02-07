import 'dart:html';

import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/ListenEvent.dart';

import 'Common.dart';
import 'documentPage.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

class QuerySpecViewPage extends StatelessWidget {
  QuerySpecViewPage({
    required this.queryDocument,
    this.itemBuilder,
    this.appBar,
    this.floatingActionButton,
  });

  DocumentReference queryDocument;

  AppBar? appBar;
  Widget? floatingActionButton;

  Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ?? defaultAppBar(context),
      body: QuerySpecViewWidget(
        queryDocument: queryDocument,
        itemBuilder: itemBuilder,
      ),
      floatingActionButton:
          floatingActionButton ?? defaultFloatingActionButton(context),
    );
  }

  AppBar defaultAppBar(BuildContext context) {
    return AppBar(
      title: Text("${queryDocument.path} - Collection"),
      actions: [
        IconButton(
          icon: Icon(Icons.filter_list),
          onPressed: () => showDocumentEditorDialog(queryDocument, context),
        ),
        bell(context),
      ],
    );
  }

  FloatingActionButton defaultFloatingActionButton(BuildContext context) {
    String makeCollectionPath(DocumentSnapshot d) {
      dynamic query = d.data();
      return query["collection"] +
          ((query["subCollections"] as List?)
                  ?.map((e) => "/${e["document"]}/${e["collection"]}")
                  .join() ??
              "");
    }

    return FloatingActionButton(
      child: Icon(Icons.note_add),
      onPressed: () {
        queryDocument.get().then((e) {
          String docPath = makeCollectionPath(e);
          print(docPath); //TODO
          showDocumentEditorDialog(db.collection(docPath).doc(), context);
        });
      },
    );
  }
}

class QuerySpecViewWidget extends StatelessWidget {
  QuerySpecViewWidget({
    required this.queryDocument,
    this.itemBuilder,
  });

  final DocumentReference queryDocument;
  dynamic? querySpec;

  Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots)? itemBuilder;

  Widget defaultItemBuilder(
      BuildContext context, int index, AsyncSnapshot<QuerySnapshot> snapshots) {
    QueryDocumentSnapshot? e = snapshots.data?.docs[index];
    return Card(child: Text("$index: ${e?.id} ${e?.data()}"));
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<DocumentSnapshot>(
        stream: queryDocument.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.data == null)
            return Center(child: CircularProgressIndicator());
          print("query=${snapshot.data?.data()}"); //TODO
          querySpec = snapshot.data?.data();
          Query? q = makeQuery(snapshot.data?.data());
          if (q == null)
            return Center(child: Text("Query Error: ${snapshot.data?.data()}"));
          return streamWidget(q, context);
        },
      );

  Widget streamWidget(Query query, BuildContext context) =>
      StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshots) {
            if (snapshots.hasError)
              return SelectableText("Snapshots Error: ${snapshots.toString()}");
            if (!snapshots.hasData)
              return Center(child: CircularProgressIndicator());
            QuerySnapshot querySnapshotData = snapshots.data!;
            return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width ~/ 220,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    childAspectRatio: 2.0),
                itemCount: snapshots.data?.size,
                itemBuilder: (BuildContext context, int index) {
                  QueryDocumentSnapshot doc = snapshots.data!.docs[index];
                  itemBuilder = itemBuilder ?? defaultCell;
                  return Container(
                      child: InkResponse(
                    onLongPress: () {
                      print("long");
                    },
                    child: Dismissible(
                      key: Key(querySnapshotData.docs[index].id),
                      child: itemBuilder!(context, index, snapshots),
                      onDismissed: (_) =>
                          querySnapshotData.docs[index].reference.delete(),
                    ),
                  ));
                });
          });

  Widget defaultCell(
      BuildContext context, int index, AsyncSnapshot<QuerySnapshot> snapshots) {
    QueryDocumentSnapshot doc = snapshots.data!.docs[index];
    Map<String, dynamic> data = doc.data();
    DateTime? time = data["time"] != null
        ? DateTime.fromMillisecondsSinceEpoch(data["time"])
        : null;

    List<String> getTypeFilter(Map<String, dynamic> q) {
      List<List<String>> f = (q["where"] as List<dynamic>?)
              ?.where((e) => e["field"] == "type" && e["op"] == "containsAny")
              .map(
                  (e) => (e["values"] as List).map((e) => e as String).toList())
              .toList() ??
          [];
      if (f.length == 0) return [];
      return f[0];
    }

    Map<String, dynamic> setTypeFilter(
        Map<String, dynamic> q, List<String> typeFilter) {
      if (typeFilter.length > 0) {
        Map<String, dynamic> newQuery = setTypeFilter(q, []);
        if (newQuery["where"] == null) newQuery["where"] = [];
        (newQuery["where"] as List).add({
          "field": "type",
          "op": "containsAny",
          "type": "list<string>",
          "values": typeFilter,
        });
        return newQuery;
      } else {
        return q.map((k, v) {
          return k == "where"
              ? MapEntry(
                  k,
                  (v as List)
                      .where((e) =>
                          e["field"] != "type" || e["op"] != "containsAny")
                      .toList())
              : MapEntry(k, v);
        });
      }
    }

    List<String> filterTypes = getTypeFilter(querySpec);

    List<Widget> chips = [];
    Widget chip(String typeName) {
      return ChoiceChip(
        label: Text(typeName.split(".").last),
        selected: filterTypes.any((e) => e == typeName),
        onSelected: (isSelected) {
          isSelected ? filterTypes.add(typeName) : filterTypes.remove(typeName);
          queryDocument.set(setTypeFilter(querySpec, filterTypes));
        },
      );
    }

    data["type"]?.forEach((typeName) => chips.add(chip(typeName)));

    return wrapDocumentOperationMenu(doc.reference, context,
        child: Card(
//          margin: EdgeInsets.all(3),
            color: Colors.grey[200],
            child: Padding(
              padding: EdgeInsets.all(3),
              child: Wrap(
                  children: chips +
                      [
                        Chip(label: Text(time?.toString() ?? "no-time"),backgroundColor: Colors.orange[100],),
                        Text("$index: ${doc.id}"),
                      ]),
            )));
  }

  Widget body(List<QueryDocumentSnapshot> docs, BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: w ~/ 160,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            childAspectRatio: 2.0),
        itemCount: docs.length,
        itemBuilder: (BuildContext context, int index) {
          QueryDocumentSnapshot d = docs[index];

          return Container(
            child: InkResponse(
              onLongPress: () {
                print("long");
              },
              child: Dismissible(
                key: Key(docs[index].id),
//              child: buildGenericCard(context, dRef),
                onDismissed: (_) => docs[index].reference.delete(),
                child: Card(
                  color: Theme.of(context).cardColor,
                  child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.black26,
                      ),
                      child: GestureDetector(
                        child: Text(d.id, overflow: TextOverflow.ellipsis),
                        onTap: () =>
                            showDocumentOperationMenu(d.reference, context),
                      )),
                ),
              ),
            ),
          );
        });
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

/* ================================================================================
    QuerySpecification for watchDocuments()
    {
      "collection": "collectionId",
      "subCollections": [ {"document":"documentId", "collection":"collectionId" }, ... ],

      "collectionGroup": "collectionGroupId",

      "orderBy": [
        { "field": "orderByFieldName",
          "descending": false  // true, false
        }//,...
      ],
      "where": [
        { "field":"filterFieldName",
          "op" : "==", // "==", "!=", ">", ">=", "<", "<=", "contains"
          "type": "number", // "number", "string", "boolean"
          "value": "fieldValue", // if with scalor-operator
        },
        { "field":"fieldName",
          "op" : "in", // "in", "notIn", "containsAny"
          "type": "list<string>", // "list<number>", "list<string>"
          "values": ["fieldValue1","fieldValue2",...] // if with list-operator
        }, ...
      ],

      "limit": 100
    }
  ================================================================================ */

Query? makeQuery(dynamic querySpec) {
  Query? makeCollRef(dynamic querySpec) {
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

  Query? query = makeCollRef(querySpec);
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
    return query.where(field, isGreaterThanOrEqualTo: parseValue(type, value));
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

Query addFilters(Query query, dynamic filterList) =>
    filterList.toList().fold(query, (a, e) => addFilter(a, e));

Query addOrderBy(Query query, dynamic order) =>
    query.orderBy(order["field"], descending: order["descending"] == true);
