import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:riotagitator/ui/riotAgentMfpMib.dart';

import 'Common.dart';
import 'fsCollectionOperator.dart';

/* Cluster管理画面
   - 登録デバイス一覧表示
   - 新規デバイス登録
   - Cluster情報の編集
*/
class ClusterViewerPageWidget extends StatelessWidget {
  final String clusterId;

  ClusterViewerPageWidget({@required this.clusterId});

  @override
  Widget build(BuildContext context) {
    return FsQueryOperatorAppWidget(
      FirebaseFirestore.instance
          .collection("device")
          .where("cluster", isEqualTo: clusterId),
      itemBuilder: (context, index, snapshots) =>
          buildCellWidget(context, snapshots.data.docs[index]),
      appBar: AppBar(
        title: Text("${clusterId} Cluster Viewer"),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => pushDocEditor(context,
                FirebaseFirestore.instance.collection("group").doc(clusterId)),
          )
        ],
      ),
      onAddButtonPressed: (_) {
        return DocumentPageWidget(
            FirebaseFirestore.instance.collection("device").doc());
      },
    );
  }

  /*pushNewDevicePage(
      BuildContext context, int index, AsyncSnapshot<QuerySnapshot> snapshots) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return makeNewDevicePage(context, index, snapshots);
        },
      ),
    );
  }

   */
/*
  Widget makeNewDevicePage(
    BuildContext context,
    int index,
    AsyncSnapshot<QuerySnapshot> snapshots,
  ) {
    QueryDocumentSnapshot doc = snapshots.data.docs[index];
    switch (doc.data()["type"]) {
      case "agent.mfp.mib":
        return RiotAgentMfpMibAppWidget(doc.reference);
    }
    return null; //default Widget
  }

 */
}

/*
登録デバイスの追加
Agentによるデバイス検索
*/
/*
class EntryDeviceIdWidget extends StatefulWidget {
  final String groupId;

  EntryDeviceIdWidget({this.groupId});

  @override
  State<StatefulWidget> createState() => EntryDeviceIdState(groupId: groupId);
}

class EntryDeviceIdState extends State<EntryDeviceIdWidget> {
  String groupId;

  EntryDeviceIdState({@required this.groupId});

  var devList = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${groupId} - Register Device ID"),
      ),
      body: Column(children: [
        TextField(
          controller: devList,
          decoration: InputDecoration(hintText: "Enter new device IDs"),
          keyboardType: TextInputType.multiline,
          maxLines: null,
          minLines: 3,
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection("device")
                    .doc("snmp1")
                    .get()
                    .then((value) {
                  setState(() {
                    List detected = value.data()["result"]["detected"];
                    devList.text = detected.join("\n");
                  });
                });
              },
            )
          ],
        )
      ]),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () {
          devList.text.split("\n").where((e) => e.length != 0).forEach((i) {
            FirebaseFirestore.instance
                .collection("group")
                .doc(groupId)
                .collection("devices")
                .doc(i)
                .set({});
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

 */
