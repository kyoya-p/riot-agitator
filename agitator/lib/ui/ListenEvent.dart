import 'package:flutter/material.dart';
import 'package:floatingpanel/floatingpanel.dart';
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

logListener(BuildContext context) async {
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
