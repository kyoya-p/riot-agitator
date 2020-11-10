import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/deviceOperator.dart';

import 'fsCollectionOperator.dart';

class ClusterInfoAppWidget extends StatelessWidget {
  String clusterId;

  ClusterInfoAppWidget({this.clusterId});

  TextEditingController textDoc = TextEditingController(text: "Undefined");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${clusterId} - Cluster"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("group")
                  .doc(clusterId)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());
                textDoc.text =
                    JsonEncoder.withIndent("  ").convert(snapshot.data.data());
                return TextField(
                  controller: textDoc,
                  maxLines: null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/*
グループ編集画面
- 登録デバイス一覧表示
- 登録デバイスの削除
*/
class GroupDeviceList extends StatelessWidget {
  String groupId;

  GroupDeviceList({this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("${groupId} - Cluster / Devices"),
        ),
        body: Column(
          children: [
            Expanded(
              child: FsCollectionOperatorWidget(
                query: FirebaseFirestore.instance
                    .collection("device")
                    .where("cluster", isEqualTo: groupId),
                itemBuilder: (context, index, docs) => Container(
                  color: Theme.of(context).primaryColorLight,
                  child: Text(docs[index].id),
                ),
                onTapItem: (context, index, docs) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ObjectOperatorWidget(
                        docRef: FirebaseFirestore.instance
                            .collection("devConfig")
                            .doc(docs[index].id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EntryDeviceIdWidget(
                  groupId: groupId,
                ),
              ),
            );
          },
        ));
  }
}

/*
登録デバイスの追加
Agentによるデバイス検索
*/
class EntryDeviceIdWidget extends StatefulWidget {
  String groupId;

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
