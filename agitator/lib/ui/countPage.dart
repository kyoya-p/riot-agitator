import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';

import 'Common.dart';
import 'QueryBuilder.dart';
import 'QuerySpecViewPage.dart';

Widget counter(BuildContext context) {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final User user = FirebaseAuth.instance.currentUser;
  if (user.uid == null) return Center(child: CircularProgressIndicator());

  CollectionReference app1 = db.collection("user/${user.uid}/app1");
  DocumentReference docFilterAlerts = app1.doc("count_log");

  Widget countChip(BuildContext context, String bells) =>
      ActionChip(
        label: Text(bells),
        onPressed: () async {
          docFilterAlerts.set({
            "collectionGroup": "counter",
            "limit": 500,
          });
          naviPush(context,
                  (_) => QuerySpecViewPage(queryDocument: docFilterAlerts));
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
          snapshot.data?.docs.toList().forEach((e) {
            print(e.data());
          });
          var sum = snapshot.data?.docs
              .map((e) => e.data() ? ["count"])
              .fold<int>(0, (a, e) => a + e as int) ??
              -9999;
          return countChip(context, "$sum");
        },
      );
    },
  );
}

