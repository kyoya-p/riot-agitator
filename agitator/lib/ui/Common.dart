import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/AgentMfpMib.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Demo.dart';
import 'QueryViewPage.dart';
import 'collectionGroupPage.dart';
import 'collectionPage.dart';
import 'documentPage.dart';

DecorationTween makeDecorationTween(Color c) => DecorationTween(
      begin: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(5.0),
      ),
      end: BoxDecoration(
        color: Colors.brown[100],
        borderRadius: BorderRadius.circular(5.0),
      ),
    );

Widget buildCellWidget(
    BuildContext context, QueryDocumentSnapshot devSnapshot) {
  Map<String, dynamic> data = devSnapshot.data();
  String type = data["dev.type"];
  if (type == RiotAgentMfpMibAppWidget.type) {
    return RiotAgentMfpMibAppWidget.makeCellWidget(context, devSnapshot);
  } else if (type == DemoHumanHeatSensorCreatePage.type) {
    return DemoHumanHeatSensorCreatePage.makeCellWidget(context, devSnapshot);
  } else {
    return buildGenericCard(context, devSnapshot.reference);
  }
}

// Label: dev.nameまたはidを表示
// 長押しでメニュー
// - Document編集
// - logs表示
Widget buildGenericCard(BuildContext context, DocumentReference dRef) => Card(
    color: Theme.of(context).cardColor,
    child: StreamBuilder<DocumentSnapshot>(
        stream: dRef.snapshots(),
        builder: (streamCtx, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          String label =
              snapshot.data?.data().getNested<String>(["dev", "name"]) ??
                  snapshot.data?.id ??
                  "no title";
          //User user = FirebaseAuth.instance.currentUser;

          return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.black12,
              ),
              child: GestureDetector(
                  child: Text(label, overflow: TextOverflow.ellipsis),
                  onTap: () => showDocumentOperationMenu(dRef, streamCtx)));
        }));

showDocumentOperationMenu(DocumentReference dRef, BuildContext context) {
  User user = FirebaseAuth.instance.currentUser;

  return showDialog(
    context: context,
    builder: (dialogCtx) {
      return SimpleDialog(
        title: Text(dRef.path),
        children: [
          SimpleDialogOption(
              child: Text("View/Edit"),
              onPressed: () {
                Navigator.pop(dialogCtx);
                naviPush(context, (_) => DocumentPage(dRef));
              }),
          SimpleDialogOption(
              child: Text("Publish (Update 'time' and set)"),
              onPressed: () {
                //Navigator.pop(dialogCtx);
                dRef.get().then((DocumentSnapshot doc) {
                  Map<String, dynamic> map = doc.data();
                  map["time"] = DateTime.now().toUtc().millisecondsSinceEpoch;
                  dRef.set(map);
                });
              }),
          SimpleDialogOption(
              child: Text("SubCollection: query"),
              onPressed: () {
                Navigator.pop(dialogCtx);
                naviPush(
                  context,
                  (_) => CollectionPage(dRef.collection("query")),
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
                naviPush(
                  context,
                  (_) => CollectionGroupPage(
                    //DeviceLogsPage(
                    dRef.collection("logs"),
                    filterConfigRef: FirebaseFirestore.instance
                        .collection("user")
                        .doc(user.uid)
                        .collection("app1")
                        .doc("filterConfig_state"),
                  ),
                );
              }),
          SimpleDialogOption(
              child: Text("SubCollection: logs"),
              onPressed: () {
                Navigator.pop(dialogCtx);
                naviPush(
                  context,
                  (_) => CollectionGroupPage(
                    //DeviceLogsPage(
                    dRef.collection("logs"),
                    filterConfigRef: FirebaseFirestore.instance
                        .collection("user")
                        .doc(user.uid)
                        .collection("app1")
                        .doc("filterConfig_logs"),
                  ),
                );
              }),
        ],
      );
    },
  );
}

// Common Styles
Decoration genericCellDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(5),
  color: Colors.black12,
);

naviPop(BuildContext context) => Navigator.pop(context);

// some snippet
naviPush(BuildContext context, WidgetBuilder builder) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: builder,
    ),
  );
}

naviPushReplacement(BuildContext context, WidgetBuilder builder) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: builder,
    ),
  );
}

Future showAlertDialog(context, String value) async {
  await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
              title: Text('AlertDialog'),
              content: Text(value),
              actions: <Widget>[
                new SimpleDialogOption(
                    child: new Text('Close'),
                    onPressed: () => Navigator.pop(context)),
              ]));
}

Widget fsStreamBuilder(Query ref, AsyncWidgetBuilder builder) =>
    StreamBuilder<QuerySnapshot>(
        stream: ref.snapshots(),
        builder: (context, snapshots) {
          if (!snapshots.hasData)
            return Center(child: CircularProgressIndicator());
          return builder(context, snapshots);
        });

Timer runPeriodicTimer(int start) =>
    Timer.periodic(Duration(milliseconds: 250), (timer) {
      int d = DateTime.now().toUtc().millisecondsSinceEpoch - start;
      if (d >= 5000) {
        timer.cancel();
      } else {
        //func()
      }
    });

class MySwitchListTile extends StatefulWidget {
  MySwitchListTile({required this.title, this.value = false});

  Widget title;
  bool value;

  @override
  State<StatefulWidget> createState() => _MySwitchTileState();
}

class _MySwitchTileState extends State<MySwitchListTile> {
  @override
  Widget build(BuildContext context) => SwitchListTile(
        onChanged: (sw) {
          setState(() => widget.value = sw);
        },
        value: widget.value,
        title: widget.title,
      );
}

// extention functions for debug
extension Debug on Object {
  pby(Function f) {
    print(f(this));
    return this;
  }

  p() {
    print(this);
    return this;
  }
}

extension MapExt on Map<String, dynamic?>? {
  T? get<T>(String key) {
    if (this == null) return null;
    dynamic t = (this as Map<String, dynamic?>)[key];
    if (t == null) return null;
    if (!(t is T)) return null;
    return t as T;
  }

  T? getNested<T>(List<String> keys) {
    Map<String, dynamic?>? map = this;
    dynamic t = null;
    for (String key in keys) {
      if (map == null) return null;
      if (!map.containsKey(key)) return null;
      t = map[key];
      if (map[key] is Map<String, dynamic?>?) map = map[key];
    }
    if (t == null) return null;
    if (!(t is T)) return null;
    return t as T;
  }
}

Widget globalGroupMenu(BuildContext context) {
  FirebaseFirestore db = FirebaseFirestore.instance;
  User user = FirebaseAuth.instance.currentUser;

  return PopupMenuButton<Widget Function(BuildContext)>(
    itemBuilder: (BuildContext context) => [
      PopupMenuItem(
          child: Text("Generic Query"),
          value: (_) => QueryViewPage(
              queryDocument: db.doc("user/${user.uid}/app1/filterGeneral"))),
      PopupMenuItem(
          child: Text("User Viewer (admin)"),
          value: (_) => CollectionGroupPage(db.collection("user"))),
      PopupMenuItem(
          child: Text("Device Viewer (admin)"),
          value: (_) => CollectionGroupPage(db.collection("device"))),
      PopupMenuItem(
          child: Text("Group Viewer (admin)"),
          value: (_) => CollectionGroupPage(
              db.collection("group").where("users", arrayContains: user.uid),
              filterConfigRef:
                  db.doc("user/${user.uid}/app1/logFilter_group"))),
      PopupMenuItem(
          child: Text("Notification Viewer (admin)"),
          value: (_) => CollectionGroupPage(db.collection("notification"))),
      PopupMenuItem(
          child: Text("Log Viewer (admin)"),
          value: (_) => CollectionGroupPage(db.collectionGroup("logs"),
              filterConfigRef: db.doc("user/${user.uid}/app1/logFilter"))),
    ],
    onSelected: (value) => naviPush(context, value),
  );
}

