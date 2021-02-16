import 'package:flutter/material.dart';
import 'package:floatingpanel/floatingpanel.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/Common.dart';
import 'package:riotagitator/ui/QueryViewPage.dart';

import 'QuerySpecViewPage.dart';

final db = FirebaseFirestore.instance;

class QueryWidget extends StatelessWidget {
  QueryWidget({
    required this.query,
    required this.builder,
  });

  final Query query;

  Widget Function(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshots)
      builder;

  @override
  Widget build(BuildContext context) {
    return streamWidget(query, context);
  }

  Widget streamWidget(Query query, BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshots) {
          if (snapshots.hasError)
            return SelectableText("Snapshots Error: ${snapshots.toString()}");
          if (!snapshots.hasData)
            return Center(child: CircularProgressIndicator());
          QuerySnapshot querySnapshotData = snapshots.data!;
          return builder(context, snapshots);
        });
  }
}

extension DocumentOperatiron on DocumentReference {
  dynamic operator [](String k) async => (await get()).data()?[k];

  void operator []=(String k, dynamic v) => set({k: v});
}

Widget bell(BuildContext context) {
  User user = FirebaseAuth.instance.currentUser;
  if (user.uid == null) return Center(child: CircularProgressIndicator());

  CollectionReference app1 = db.collection("user/${user.uid}/app1");
  DocumentReference docFilter_Bell = app1.doc("filter_bell_1");
  DocumentReference docLastChecked = app1.doc("lastChecked");
  DocumentReference docFilter_Alerts = app1.doc("filter_alerts");

  docFilter_Bell.set({
    "collectionGroup": "logs",
    "limit": 1,
    "orderBy": [
      {
        "field": "time",
        "descending": true,
      }
    ]
  });

  Widget normalButton =
      IconButton(icon: Icon(Icons.wb_incandescent_outlined), onPressed: null);
  Widget alertButton(BuildContext context, int timeCheckNotification) =>
      IconButton(
        icon: Icon(Icons.wb_incandescent),
        onPressed: () async {
/*          DateTime d = DateTime.fromMillisecondsSinceEpoch(
              timeCheckNotification,
              isUtc: false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("After $d, Some devices informed something //TODO"),
          ));
 */
          int checked = DateTime.now().millisecondsSinceEpoch;
          int lastChecked = await docLastChecked["time"] ?? 0;
          docLastChecked["time"] = checked;

          docFilter_Alerts.set({
            "collectionGroup": "logs",
            "limit": 50,
            "orderBy": [
              {"field": "time", "descending": true}
            ],
            "filter": [
              {
                "field": "time",
                "op": ">",
                "type": "number",
                "value": lastChecked
              }
            ]
          });
          naviPush(context,
              (_) => QuerySpecViewPage(queryDocument: docFilter_Alerts));
        },
      );

  return StreamBuilder<DocumentSnapshot>(
    stream: docFilter_Bell.snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return normalButton;
      var timeCheckNotification =
          snapshot.data?.data()["timeCheckNotification"] ?? 0;
      return StreamBuilder<QuerySnapshot>(
        stream: db
            .collectionGroup("logs")
            .where("time", isGreaterThanOrEqualTo: timeCheckNotification)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data?.size == 0)
            return normalButton;
          print("Notifire: ${snapshot.data!.docs[0]}"); //TODO
          return alertButton(context, timeCheckNotification);
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
