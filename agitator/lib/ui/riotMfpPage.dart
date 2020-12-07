import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'fsCollectionOperator.dart';

class MfpViewerAppWidget extends StatelessWidget {
  MfpViewerAppWidget(this.devId);

  final String devId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("XXX")),
      body: DocumentWidget(//TODO
          FirebaseFirestore.instance.collection("device").doc(devId)),
    );
  }
}
