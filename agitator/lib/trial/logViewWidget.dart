import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Firestoreを使う際のテンプレ
class logViewWidget_XXX extends StatelessWidget {
  @override
  Query qrDevList =
      FirebaseFirestore.instance.collection("devLogs").orderBy("time");

  List<DocumentSnapshot> devList;

  Widget build(BuildContext context) {
    return StreamProvider<QuerySnapshot>(
      create: (_) => FirebaseFirestore.instance.collection("devLogs").snapshots(),
      child: GridView.builder(
          reverse: false,
          itemBuilder: (context, index) {
            while (index >= devList.length) {
              if (!devList.isEmpty) {
                qrDevList = qrDevList.startAfter([devList[devList.length - 1]]);
              }
              qrDevList.get().then((value) => null);
            }
          }),
    );
  }
}
