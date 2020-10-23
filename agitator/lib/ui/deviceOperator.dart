import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/*
オブジェクト(ドキュメント)操作
*/
class ObjectOperatorWidget extends StatelessWidget {
  DocumentReference docRef;

  ObjectOperatorWidget({this.docRef});

  TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: docRef.snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          textController.text = //json.encode(snapshot.data.data());
          JsonEncoder.withIndent(" ").convert(snapshot.data.data());
          String id = snapshot.data.id;
          return Scaffold(
            appBar: AppBar(title: Text("${docRef.path} - Configuration")),
            body: TextField(
              maxLines: null,
              controller: textController,
            ),
            floatingActionButton: FloatingActionButton(
              child: Icon(Icons.send),
              onPressed: () {
                var doc=json.decode(textController.text);
                doc["time"]=DateTime.now().millisecondsSinceEpoch;
                docRef.set(doc);
                Navigator.pop(context);
              },
            ),
          );
        });
  }
}

/*
デバイス操作
*/
class DeviceOperatorWidget extends StatelessWidget {
  String deviceId;

  Stream<DocumentSnapshot> dbDocSetting;

  var setting = TextEditingController();

  DeviceOperatorWidget({this.deviceId}) {
    dbDocSetting = FirebaseFirestore.instance
        .collection("devConfig")
        .doc(deviceId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return StreamBuilder(
        stream: dbDocSetting,
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          setting.text = snapshot.data.data().toString();
          return TextField(
            controller: setting,
            keyboardType: TextInputType.multiline,
            maxLines: null,
          );
        });
  }
}

/*
SNMP Agent検索用コンソール
*/
class SnmpDiscoveryWidget extends StatelessWidget {
  String groupId;

  SnmpDiscoveryWidget({this.groupId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("group")
          .doc(groupId)
          .collection("devices")
          .snapshots(),
      builder: (context, snapshot) => Row(
          children: [IconButton(icon: Icon(Icons.search), onPressed: null)]),
    );
  }
}
