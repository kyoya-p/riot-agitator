import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class RiotDevice {
  static String type;

  static Widget cellWidget(QueryDocumentSnapshot snapshot) {}
}

/*
Agent操作
*/
class RiotAgentMfpMibAppWidget extends StatelessWidget implements RiotDevice {
  final DocumentReference docRef;

  RiotAgentMfpMibAppWidget({this.docRef});

  final TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: docRef.snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          textController.text = //json.encode(snapshot.data.data());
              JsonEncoder.withIndent(" ").convert(snapshot.data.data());
          return Scaffold(
            appBar: AppBar(title: Text("${docRef.path} - Configuration")),
            body: TextField(
              maxLines: null,
              controller: textController,
            ),
            floatingActionButton: FloatingActionButton(
              child: Icon(Icons.send),
              onPressed: () {
                var doc = json.decode(textController.text);
                doc["time"] = DateTime.now().millisecondsSinceEpoch;
                docRef.set(doc);
                Navigator.pop(context);
              },
            ),
          );
        });
  }

  @override
  static final String type = "agent.mfp.mib";

  @override
  static Widget cellWidget(
      BuildContext context, QueryDocumentSnapshot snapshot) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Theme.of(context).highlightColor,
        ),
        child: Column(children: [
          Row(
            children: [
              Icon(Icons.search),
              Text("${snapshot.data()["name"] ?? snapshot.id}"),
            ],
          )
        ]));
  }
}

/*
デバイス操作
*/
class DeviceOperatorWidget extends StatelessWidget {
  final Stream<DocumentSnapshot> dbDocSetting;

  final TextEditingController setting = TextEditingController();

  DeviceOperatorWidget(this.dbDocSetting);

  DeviceOperatorWidget from(String deviceId) =>
      DeviceOperatorWidget(FirebaseFirestore.instance
          .collection("devConfig")
          .doc(deviceId)
          .snapshots());

  @override
  Widget build(BuildContext context) {
    //double w = MediaQuery.of(context).size.width;

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
  final String groupId;

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
