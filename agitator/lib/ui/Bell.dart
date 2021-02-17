import 'package:flutter/material.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:floatingpanel/floatingpanel.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/Common.dart';
import 'package:riotagitator/ui/QueryBuilder.dart';
import 'package:riotagitator/ui/documentPage.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:badges/badges.dart';

import 'QuerySpecViewPage.dart';

final db = FirebaseFirestore.instance;

extension DocumentOperatiron on DocumentReference {
  dynamic operator [](String k) async => (await get()).data()?[k];

  void operator []=(String k, dynamic v) => set({k: v});
}

Widget bell(BuildContext context) {
  User user = FirebaseAuth.instance.currentUser;
  if (user.uid == null) return Center(child: CircularProgressIndicator());

  CollectionReference app1 = db.collection("user/${user.uid}/app1");
  DocumentReference docLastChecked = app1.doc("lastChecked");
  DocumentReference docFilterBell = app1.doc("filter_bell_1");
  DocumentReference docFilterBlerts = app1.doc("filter_alerts");

  Widget normalBell = IconButton(
    icon: Icon(Icons.wb_incandescent_outlined),
    onPressed: () => showDocumentEditorDialog(docFilterBell, context),
    color: Colors.grey,
  );

  Widget alertBell(
          BuildContext context, int timeCheckNotification, int bells) =>
      TextButton(
        child: Badge(
          badgeContent: bells>5 ? Text("+5") : Text("$bells"),
          badgeColor: Colors.orange, //Theme.of(context).bottomAppBarColor,
          child: Icon(
            Icons.wb_incandescent,
            color: bells != 0 ? Colors.yellow : Theme.of(context).disabledColor,
          ),
        ),
        onPressed: () async {
          int checked = DateTime.now().millisecondsSinceEpoch;
          int lastChecked = await docLastChecked["time"] ?? 0;
          docLastChecked["time"] = checked;
          docFilterBlerts.set({
            "collectionGroup": "logs",
            "limit": 50,
            "orderBy": [
              {"field": "time", "descending": true}
            ],
            "where": [
              {
                "field": "time",
                "op": ">",
                "type": "number",
                "value": "$lastChecked"
              }
            ]
          });
          naviPush(context,
              (_) => QuerySpecViewPage(queryDocument: docFilterBlerts));
        },
        onLongPress: () => showDocumentEditorDialog(docFilterBell, context),
      );

  return StreamBuilder<DocumentSnapshot>(
    stream: docFilterBell.snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return normalBell;
      QueryBuilder queryBuilder = QueryBuilder(snapshot.data!.data());
      return StreamBuilder<DocumentSnapshot>(
        stream: docLastChecked.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return normalBell;
          int lastChecked = snapshot.data?.data()["time"] ?? 0;
          queryBuilder = queryBuilder.where(
              field: "time", op: ">", type: "number", value: "$lastChecked");
          docFilterBell.set(queryBuilder.querySpec);
          Query? q = queryBuilder.build();
          if (q == null) {
            return normalBell;
          }
          return StreamBuilder<QuerySnapshot>(
            stream: queryBuilder.build()!.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return normalBell;
              int bellCount = snapshot.data?.size ?? 0;
              return bellCount == 0
                  ? normalBell
                  : alertBell(context, lastChecked, bellCount);
            },
          );
        },
      );
    },
  );
}

class FloatSample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            // Add Float Box Panel at the bottom of the 'stack' widget.
            FloatBoxPanel(
              //Customize properties
              backgroundColor: Color(0xFF222222),
              panelShape: PanelShape.rectangle,
              borderRadius: BorderRadius.circular(8.0),

              buttons: [
                // Add Icons to the buttons list.
                Icons.message,
                Icons.photo_camera,
                Icons.video_library
              ],
            ),
          ],
        ),
      ),
    );
  }
}
