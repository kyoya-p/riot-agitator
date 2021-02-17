import 'package:flutter/material.dart';
import 'package:floatingpanel/floatingpanel.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/Common.dart';
import 'package:riotagitator/ui/QueryBuilder.dart';
import 'package:riotagitator/ui/documentPage.dart';

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
  DocumentReference docFilter_Bell = app1.doc("filter_bell_1");
  DocumentReference docFilter_Alerts = app1.doc("filter_alerts");

  docFilter_Bell.set({
    "collectionGroup": "logs",
    "limit": 5,
    "where": [
      {"field": "time", "op": ">", "type": "string", "value": "0"} //TODO
    ]
  });

  Widget normalBell = IconButton(
    icon: Icon(Icons.wb_incandescent_outlined),
    onPressed: () => showDocumentEditorDialog(docFilter_Bell, context),
    color: Colors.grey,
  );

  Widget alertBell(
          BuildContext context, int timeCheckNotification, bool exist) =>
      TextButton(
        child: Icon(
          Icons.wb_incandescent,
          color: exist ? Colors.yellow : Theme.of(context).disabledColor,
        ),
        onPressed: () async {
          int checked = DateTime.now().millisecondsSinceEpoch;
          int lastChecked = await docLastChecked["time"] ?? 0;
          docLastChecked["time"] = checked;
          docFilter_Alerts.set({
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
              (_) => QuerySpecViewPage(queryDocument: docFilter_Alerts));
        },
        onLongPress: () => showDocumentEditorDialog(docFilter_Bell, context),
      );

  return StreamBuilder<DocumentSnapshot>(
    stream: docFilter_Bell.snapshots(),
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
          Query? q = queryBuilder.build();
          if (q == null) {
            return normalBell;
          }
          return StreamBuilder<QuerySnapshot>(
            stream: queryBuilder.build()!.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return normalBell;
              if (snapshot.data?.size == 0) {
                return alertBell(context, lastChecked, false);
              }
              return alertBell(context, lastChecked, true);
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
