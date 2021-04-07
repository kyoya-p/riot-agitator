import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:badges/badges.dart';

import 'Common.dart';
import 'QueryBuilder.dart';
import 'QuerySpecViewPage.dart';
import 'documentPage.dart';

Widget count(BuildContext context) {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final User user = FirebaseAuth.instance.currentUser;
  if (user.uid == null) return Center(child: CircularProgressIndicator());

  CollectionReference app1 = db.collection("user/${user.uid}/app1");
  DocumentReference docFilterBell = app1.doc("count_log_1");
  DocumentReference docFilterAlerts = app1.doc("count_log");

  Widget conutWidget(BuildContext context, String bells) => ActionChip(
        label: Text(bells),
        onPressed: () async {
          docFilterAlerts.set({
            "collectionGroup": "counter",
            "limit": 50,
            //"orderBy": [{"field": "time", "descending": true}],
/*            "where": [
              { "field": "time",
                "op": ">",
                "type": "number",
                "value": "$lastChecked"}
            ]

 */
          });
          naviPush(context,
              (_) => QuerySpecViewPage(queryDocument: docFilterAlerts));
        },
      );
  Widget normalBell = conutWidget(context, "Loading..");

  return StreamBuilder<DocumentSnapshot>(
    stream: docFilterBell.snapshots(),
    builder: (context, snapshot) {
      if (snapshot.data!.data() == null) return normalBell;
      print("X0 ${snapshot.data!.data()}"); //TODO
      QueryBuilder queryBuilder = QueryBuilder(snapshot.data!.data());
      print("X1 ${queryBuilder.querySpec}"); //TODO
      return StreamBuilder<QuerySnapshot>(
        stream: queryBuilder.build()!.snapshots(),
        builder: (context, snapshot) {
          print("X2"); //TODO
          if (!snapshot.hasData) return normalBell;
          print("X3"); //TODO
          int bellCount = snapshot.data?.size ?? 0;
          return conutWidget(context, "ccc");
        },
      );
    },
  );
}
