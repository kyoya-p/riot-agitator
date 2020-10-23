import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/deviceOperator.dart';

import 'firestoreWidget.dart';

/*
Group一覧を表示
タップでグループ編集画面に遷移
*/
class GroupListWidget extends StatelessWidget {
  Stream<QuerySnapshot> dbSnapshot =
      FirebaseFirestore.instance.collection("group").snapshots();

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return StreamBuilder(
        stream: dbSnapshot,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (w / 160).toInt(),
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 2.0),
            itemCount: snapshot.data.size,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: RouteSettings(
                        //name: "/gr",
                        //arguments: snapshot.data.docs[index].id,
                      ),
                      builder: (context) => GroupDeviceList(
                          groupId: snapshot.data.docs[index].id),
                    ),
                  );
                },
                child: buildCell(snapshot.data.docs[index]),
              );
            },
          );
        });
  }

  Widget buildCell(QueryDocumentSnapshot doc) {
    return Container(
      decoration: BoxDecoration(
        //border: Border.all(color: Colors.blue),
        //borderRadius: BorderRadius.circular(4),
        color: Colors.indigo[50],
      ),
      child: Column(
        children: [
          Text(doc.id),
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
          title: Text("group/${groupId} - Device List"),
        ),
        body: Column(
          children: [
            Expanded(
              child: FsGridWidget(
                query: FirebaseFirestore.instance
                    .collection("group")
                    .doc(groupId)
                    .collection("devices"),
                itemBuilder: (context, index, docs) => Container(
                  color: Colors.indigo[50],
                  child: Text(docs[index].id),
                ),
                onTap: (context, index, docs) {
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
                settings: RouteSettings(
                  name: "/gr",
                ),
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
            dbSnapshot:
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
