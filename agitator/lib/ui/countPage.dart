import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';

import 'Common.dart';
import 'QueryBuilder.dart';
import 'QuerySpecViewPage.dart';
import 'documentPage.dart';

Widget counter(
    BuildContext context, String collectionGroup, String counterField) {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final User user = FirebaseAuth.instance.currentUser;
  if (user.uid == null) return Center(child: CircularProgressIndicator());

  CollectionReference app1 = db.collection("user/${user.uid}/app1");
  DocumentReference docFilterAlerts = app1.doc("countLog");

  Widget countChip(BuildContext context, String bells) => ActionChip(
        label: Text(bells),
        onPressed: () {

          showDocumentEditorDialog(
              context, docFilterAlerts);
          /* showDialog(
            context: context,
            builder: (BuildContext context1) => SimpleDialog(children: [
              SimpleDialogOption(
                  child: Text("Close"), onPressed: () => naviPop(context1)),
              SimpleDialogOption(
                  child: Text("Open Conter Configuration"),
                  onPressed: () => naviPush(
                      context1,
                      (_) => documentEditorDialog(
                          _, db.doc("user/${user.uid}/app1/logFilter"))))
            ]),
          );

          */
        },
      );
  Widget normalBell = countChip(context, "Loading..");

  return StreamBuilder<DocumentSnapshot>(
    stream: docFilterAlerts.snapshots(),
    builder: (context, snapshot) {
      if (snapshot.data == null) return normalBell;
      QueryBuilder queryBuilder = QueryBuilder(snapshot.data!.data());
      return StreamBuilder<QuerySnapshot>(
        stream: queryBuilder.build()!.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return normalBell;
          var sum = snapshot.data?.docs
                  .map((e) => e.data()?[counterField])
                  .fold<int>(0, (a, e) => a + e as int) ??
              -9999;
          return countChip(context, "$sum");
        },
      );
    },
  );
}
