import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/firestoreWidget.dart';

/*
デバイスに関する設定
*/
class DeviceOperatorWidget extends StatelessWidget {
  String deviceId;

  Stream<DocumentSnapshot> dbDocSetting;

  var setting = TextEditingController();

  DeviceOperatorWidget({this.deviceId}) {
    dbDocSetting = FirebaseFirestore.instance
        .collection("devSettings")
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
