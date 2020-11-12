import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'fsCollectionOperator.dart';

abstract class RiotDeviceInterface {
  static String type;

  static Widget cellWidget(QueryDocumentSnapshot snapshot) {}
}

/*
Agent操作
*/
class RiotAgentMfpMibAppWidget extends StatelessWidget
    implements RiotDeviceInterface {
  final DocumentReference docRef;

  RiotAgentMfpMibAppWidget(this.docRef);

  final TextEditingController textController = TextEditingController();
  final TextEditingController name = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController cluster = TextEditingController();
  final TextEditingController config = TextEditingController();

  final _tabs = <Tab>[
    //Tab(child: Row(children: [Icon(Icons.settings), Text("Device")])),
    //Tab(child: Row(children: [Icon(Icons.search), Text("Scan")])),
    //Tab(child: Row(children: [Icon(Icons.text_snippet_rounded), Text("Text")])),
    Tab(icon: Icon(Icons.settings), text: "Device"),
    Tab(icon: Icon(Icons.search), text: "Scan"),
    Tab(icon: Icon(Icons.access_time), text: "Schedule"),
    Tab(icon: Icon(Icons.text_snippet_rounded), text: "By Text"),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: _tabs.length,
        child: StreamBuilder(
            stream: docRef.snapshots(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());
              textController.text =
                  JsonEncoder.withIndent(" ").convert(snapshot.data.data());
              return Scaffold(
                appBar: AppBar(
                    title: Text("${docRef.path} - Configuration"),
                    actions: [
                      IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => navigateToDocEditor(context))
                    ],
                    bottom: TabBar(tabs: _tabs)),
                body: TabBarView(children: <Widget>[
                  deviceSettings(context, snapshot),
                  scanSettingsTable(context, snapshot),
                  scanSettingsTable(context, snapshot),
                  SingleChildScrollView(child: DocumentWidget(docRef)),
                ]),
                //body: form(context, snapshot),
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
            }));
  }

  navigateToDocEditor(BuildContext context) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => DocumentPageWidget(docRef)));

  Widget deviceSettings(
      BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
    name.text = snapshot.data.data()["name"];
    password.text = snapshot.data.data()["password"];
    cluster.text = snapshot.data.data()["cluster"];
    config.text =
        JsonEncoder.withIndent("  ").convert(snapshot.data.data()["config"]);
    return Column(
      children: [
        TextField(
            controller: name,
            decoration:
                InputDecoration(labelText: "Name", icon: Icon(Icons.label))),
        TextField(
            controller: password,
            decoration: InputDecoration(
                labelText: "Password", icon: Icon(Icons.security))),
        TextField(
            controller: cluster,
            decoration: InputDecoration(
                labelText: "Cluster ID", icon: Icon(Icons.home_filled))),
        Padding(padding: EdgeInsets.all(5.0)),
        CheckboxListTile(
          title: Text("Automatic registration of detected devices"),
          value: true,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget scanSettingsTable(
      BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
    List<dynamic> scans = snapshot.data.data()["config"]["scanAddrSpecs"];
    return DataTable(
      columns: ["IP", "Range", "Broadcast", ""]
          .map((e) => DataColumn(label: Text(e)))
          .toList(),
      rows: scans.map((e) => scanSettingsTableRow(e)).toList(),
    );
  }

  DataRow scanSettingsTableRow(dynamic scanAddr) {
    return DataRow(cells: [
      DataCell(TextField(
          controller:
              TextEditingController(text: scanAddr["addr"].toString()))),
      DataCell(TextField(
        controller: TextEditingController(text: scanAddr["addrRangeEnd"]),
        decoration: InputDecoration(
            hintText: "If empty, scan one address or broadcast"),
      )),
      DataCell(Checkbox(value: scanAddr["isBroadcast"] ?? false)),
      DataCell(IconButton(
        icon: Icon(Icons.delete_rounded),
      ))
    ]);
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
