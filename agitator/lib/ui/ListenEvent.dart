import 'package:flutter/material.dart';
import 'package:floatingpanel/floatingpanel.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

Widget buildBell(BuildContext context) {
  User user = FirebaseAuth.instance.currentUser;
  if (user.uid == null) return Center(child: CircularProgressIndicator());

  FirebaseFirestore db = FirebaseFirestore.instance;
  DocumentReference docUser = db.collection("user").doc(user.uid);

  Widget normalButton =
      IconButton(icon: Icon(Icons.wb_incandescent_outlined), onPressed: null);
  Widget alertButton(int timeCheckNotification) => IconButton(
        icon: Icon(Icons.wb_incandescent),
        onPressed: () {
          DateTime d = DateTime.fromMillisecondsSinceEpoch(
              timeCheckNotification,
              isUtc: false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("After $d, Some devices informed something //TODO"),
          ));
          docUser.set({
            "timeCheckNotification":
                DateTime.now().toUtc().millisecondsSinceEpoch
          });
        },
      );

  return StreamBuilder<DocumentSnapshot>(
    stream: docUser.snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return normalButton;
      var timeCheckNotification = snapshot.data["timeCheckNotification"] ?? 0;
      return StreamBuilder(
        stream: db
            .collectionGroup("logs")
            .orderBy("time", descending: true)
            .where("time", isGreaterThanOrEqualTo: timeCheckNotification)
            .where("type", isEqualTo: "mfp.mib")
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data.size == 0) return normalButton;
          return alertButton(timeCheckNotification);
        },
      );
    },
  );
}

logListenerX(BuildContext context) async {
  final db = FirebaseFirestore.instance;

  db
      .collectionGroup("logs")
      .orderBy("time", descending: true)
      .where(
        "time",
        isGreaterThanOrEqualTo:
            DateTime.now().toUtc().millisecondsSinceEpoch - 1 * 1000,
      )
      .where("type", isEqualTo: "mfp.mib")
      .limit(1)
      .snapshots()
      .listen((event) {
    print(event);
    if (event.docs.length != 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("###")
          //Column(
          //  children: event.docs
          //    .map((e) => ListTile(title: Text("XX")))
          //  .toList());
          ));
    }
  });
}
