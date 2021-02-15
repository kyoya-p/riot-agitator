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

Widget bell(BuildContext context) {
  User user = FirebaseAuth.instance.currentUser;
  if (user.uid == null) return Center(child: CircularProgressIndicator());

  DocumentReference docBell = db.doc("user/${user.uid}/app1/filter_bell_1");

  docBell.set({
    "collectionGroup": "logs",
    "limit": 50,
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
        onPressed: () {
/*          DateTime d = DateTime.fromMillisecondsSinceEpoch(
              timeCheckNotification,
              isUtc: false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("After $d, Some devices informed something //TODO"),
          ));

 */
          naviPush(context, (_) => QuerySpecViewPage(queryDocument: docBell));
        },
      );

  return StreamBuilder<DocumentSnapshot>(
    stream: docBell.snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return normalButton;
      var timeCheckNotification =
          snapshot.data?.data()["timeCheckNotification"] ?? 0;
      return StreamBuilder<QuerySnapshot>(
        stream: db
            .collectionGroup("logs")
            //.orderBy("time", descending: true)
            .where("time", isGreaterThanOrEqualTo: timeCheckNotification)
            //.where("dev.type", isEqualTo: "mfp.mib")
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
