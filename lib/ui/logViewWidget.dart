import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/firestore_access.dart';

class logViewWidget extends StatelessWidget {
  @override
  Query devList =
      FirebaseFirestore.instance.collection("devLogs").orderBy("time");


  Widget build(BuildContext context) {
    return StreamProvider<QuerySnapshot>(
      create: (_) => getDevLogStream(),
      child: GridView.builder(
          reverse: false,
          itemBuilder: (context, index) {
            // とにかくMutableなWidgetを先に返し、内容は後で埋める
            devList.get().then((value) => null);
          }),
    );
  }
}
