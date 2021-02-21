import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/Bell.dart';

import 'AnimatedChip.dart';
import 'Common.dart';
import 'QueryBuilder.dart';
import 'User.dart';
import 'collectionGroupPage.dart';
import 'collectionPage.dart';
import 'documentPage.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

class QuerySpecViewPage extends StatelessWidget {
  QuerySpecViewPage({
    required this.queryDocument,
    this.itemBuilder,
    this.appBar,
    this.floatingActionButton,
  });

  final DocumentReference queryDocument;

  final AppBar? appBar;
  final Widget? floatingActionButton;

  final Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots)? itemBuilder;

  late QuerySpecViewWidget querySpecViewWidget;

  @override
  Widget build(BuildContext context) {
    querySpecViewWidget = QuerySpecViewWidget(
      queryDocument: queryDocument,
      itemBuilder: itemBuilder,
    );

    Widget queryEditIcon(BuildContext context) => IconButton(
          icon: Icon(Icons.filter_list),
          onPressed: () => showDocumentEditorDialog(context, queryDocument),
        );

    Widget deleteIcon(BuildContext context) => IconButton(
          icon: Icon(Icons.delete_forever),
          onPressed: () async {
            showConfirmDialog(context, "OK?", (_) {
              print("OK!!"); //TODO
              querySpecViewWidget.deleteItems(context);
              print("Complete!!"); //TODO
            });
          },
        );

    AppBar defaultAppBar(BuildContext context) {
      return AppBar(
        title: Text("${queryDocument.path} - Collection"),
        actions: [
          deleteIcon(context),
          queryEditIcon(context),
          bell(context),
        ],
      );
    }

    return Scaffold(
      appBar: appBar ?? defaultAppBar(context),
      body: querySpecViewWidget,
      floatingActionButton:
          floatingActionButton ?? defaultFloatingActionButton(context),
    );
  }

  FloatingActionButton defaultFloatingActionButton(BuildContext context) {
    /*  String makeCollectionPath(DocumentSnapshot d) {
      dynamic query = d.data();
      return query["collection"] +
          ((query["subCollections"] as List?)
                  ?.map((e) => "/${e["document"]}/${e["collection"]}")
                  .join() ??
              "");
    }
*/
    return FloatingActionButton(
        child: Icon(Icons.note_add),
        onPressed: () {
          queryDocument.get().then((dSs) {
            Query? q = QueryBuilder(dSs.data()).build();
            querySpecViewWidget.showDocumentEditDialog(context, null);
          });
        });
  }
}

// ignore: must_be_immutable
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

          Map<String, dynamic>? data = snapshot.data?.data();
          if (data == null)
            return Center(child: Text("Query Error: ${snapshot.data?.data()}"));

          QueryBuilder q = QueryBuilder(snapshot.data!.data());
          return streamWidget(q.build()!, context);
        },
      );

  QuerySnapshot? querySnapshotData;

  Widget streamWidget(Query query, BuildContext context) =>
      StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshots) {
            if (snapshots.hasError)
              return SelectableText("Snapshots Error: ${snapshots.toString()}");
            if (!snapshots.hasData)
              return Center(child: CircularProgressIndicator());
            querySnapshotData = snapshots.data!;
            return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width ~/ 220,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    childAspectRatio: 2.0),
                itemCount: snapshots.data?.size,
                itemBuilder: (BuildContext context, int index) {
                  itemBuilder = itemBuilder ?? defaultCell;
                  return Container(
                      child: InkResponse(
                    onLongPress: () {
                      print("long"); //TODO
                    },
                    child: Dismissible(
                      key: Key(querySnapshotData!.docs[index].id),
                      child: itemBuilder!(context, index, snapshots),
                      onDismissed: (_) =>
                          querySnapshotData!.docs[index].reference.delete(),
                    ),
                  ));
                });
          });

  deleteItems(BuildContext context) {
    if (querySpec == null || querySnapshotData == null) return;
    db.runTransaction((transaction) async {
      querySnapshotData!.docs.reversed.toList().asMap().forEach((i, e) {
        e.reference.delete().then((_) {
          print("Delete: $i: ${e.id}");
          /*ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Delete: $i: ${e.id}")),
          );
         */
        });
      });
    });
  }

  Widget defaultCell(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> itemSnapshots) {
    QueryDocumentSnapshot itemDoc = itemSnapshots.data!.docs[index];
    Map<String, dynamic> data = itemDoc.data();
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
    Widget chip(String typeName) => ChoiceChip(
          label: Text(typeName.split(".").last),
          selected: filterTypes.any((e) => e == typeName),
          onSelected: (isSelected) {
            isSelected
                ? filterTypes.add(typeName)
                : filterTypes.remove(typeName);
            queryDocument.set(setTypeFilter(querySpec, filterTypes));
          },
        );

    if (data["type"] is List)
      data["type"]?.forEach((typeName) => chips.add(chip(typeName)));

    Widget menuButtonBuilder(BuildContext context) => TextButton(
        child: Text("Actions"),
        onPressed: () {
          showDialog<String>(
            context: context,
            builder: (context) => SimpleDialog(
              children: [
                ["Sub Collection [query]", "query"],
                ["Sub Collection [state]", "state"],
              ]
                  .map((e) => SimpleDialogOption(
                      child: Text(e[0] as String),
                      onPressed: () => naviPop(context, e[1])))
                  .toList(),
            ),
          ).then((res) {
            if (res != null) {
              naviPop(context);
              naviPush(context, (_) {
                itemDoc.reference.collection(res);
                DocumentReference filter = appData("filter_$res");
                filter.set({"collection": "${itemDoc.reference.path}/$res"});
                return QuerySpecViewPage(queryDocument: filter);
              });
            }
          });
        });

    return wrapDocumentOperationMenu(itemDoc, context,
        buttonBuilder: menuButtonBuilder,
        child: Card(
            color: Colors.grey[200],
            child: Padding(
              padding: EdgeInsets.all(3),
              child: Wrap(
                  children: chips +
                      [
                        timeChip(data),
                        Text("$index: ${itemDoc.id}"),
                      ]),
            )));
  }

  Widget timeChip(Map<String, dynamic> data) {
    int time = data["time"] ?? 0;
    return AnimatedChip(
        ago: DateTime.now().millisecondsSinceEpoch - time,
        builder: (_, color) {
          return Chip(
              label: Text(DateTime.fromMillisecondsSinceEpoch(time).toString()),
              backgroundColor: color.value);
        });
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
                        //onTap: () => showDocumentOperationMenu(d.reference, context),
                        onTap: () =>
                            showDocumentEditDialog(context, d.reference),
                      )),
                ),
              ),
            ),
          );
        });
  }

  showDocumentEditDialog(BuildContext context, DocumentReference? dRef) {
    if (dRef == null) {
      //NoReferenceDocument
      CollectionReference? cRef = QueryBuilder(querySpec).makeSimpleCollRef();
      if (cRef == null) return;
      dRef = cRef.doc();
    }
    Widget menuButton(BuildContext context) => TextButton(
          child: Text("Actions"),
          onPressed: () {
            showDocumentOperationMenu(dRef!, context);
          },
        );
    showDocumentEditorDialog(context, dRef, buttonBuilder: menuButton);
  }
}

showDocumentOperationMenu(DocumentReference dRef, BuildContext context) {
  return showDialog(
    context: context,
    builder: (dialogCtx) {
      print("Dialog!!"); //TODO
      return SimpleDialog(
        title: Text(dRef.path),
        children: [
          SimpleDialogOption(
              child: Text("Publish (Update 'time' and set)"),
              onPressed: () {
                dRef.get().then((DocumentSnapshot doc) {
                  Map<String, dynamic> map = doc.data();
                  map["time"] = DateTime.now().toUtc().millisecondsSinceEpoch;
                  dRef.set(map);
                });
              }),
          SimpleDialogOption(
              child: Text("SubCollection: query"),
              onPressed: () {
                DocumentReference filter = appData("filter_DeviceQuery");
                filter.set({"collection": "${dRef.path}/query"});
                naviPop(context);
                naviPop(context);
                naviPush(
                  context,
                  (_) => QuerySpecViewPage(queryDocument: filter),
                );
              }),
          SimpleDialogOption(
              child: Text("SubCollection: results"),
              onPressed: () {
                Navigator.pop(dialogCtx);
                naviPush(
                    context, (_) => CollectionPage(dRef.collection("results")));
              }),
          SimpleDialogOption(
              child: Text("SubCollection: state"),
              onPressed: () {
                Navigator.pop(dialogCtx);
                DocumentReference filter = appData("filter_DeviceState");
                filter.set({
                  "collection": "${dRef.path}/state",
                  /*"where": [
                    {
                      "field": "cluster",
                      "op": "==",
                      "type": "string",
                      "value": dRef.get().data()["dev"]["cluster"]
                    }
                  ] //TODO cluster?

                   */
                });
                naviPush(
                  context,
                  (_) => QuerySpecViewPage(queryDocument: filter),
                );
              }),
          SimpleDialogOption(
              child: Text("SubCollection: logs"),
              onPressed: () {
                Navigator.pop(dialogCtx);
                naviPush(
                  context,
                  (_) => CollectionGroupPage(dRef.collection("logs"),
                      filterConfigRef: appData("filterConfig")),
                );
              }),
        ],
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
