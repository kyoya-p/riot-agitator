import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Common.dart';
import 'fsCollectionOperator.dart';

/*
Agent操作
*/
class RiotAgentMfpMibAppWidget extends StatelessWidget {
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
                          onPressed: () => pushDocEditor(context, docRef))
                    ],
                    bottom: TabBar(tabs: _tabs)),
                body: TabBarView(children: <Widget>[
                  deviceSettings(context, snapshot),
                  scanSettingsTable(context, snapshot),
                  Center(child: Text("Under Construction...")),
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

  static String type = "agent.mfp.mib";

  static Widget makeCellWidget(
      BuildContext context, QueryDocumentSnapshot snapshot) {
    print("RiotAgentMfpMibAppWidget.makeCellWidget"); //TODO
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.blue[100],
        ),
        child: GestureDetector(
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.search),
                    Text("${snapshot.data()["name"] ?? snapshot.id}"),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                        icon: Icon(Icons.play_circle_outline),
                        onPressed: () => update(snapshot)),
                    IconButton(icon: Icon(Icons.list), onPressed: () => null)
                  ],
                ),
              ],
            ),
            onTap: () {
              print("xxxxxxxxxxxxxxxxxxxxxxx:");
            }
            /*=> Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RiotAgentMfpMibAppWidget(snapshot.reference),
              )),

           */
            ));
  }

  static update(QueryDocumentSnapshot snapshot) {
    snapshot.reference.get().then((snapshot) {
      print(snapshot.data());
      dynamic data = snapshot.data();
      data["time"] = DateTime.now().millisecondsSinceEpoch;
      snapshot.reference.set(data);
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
