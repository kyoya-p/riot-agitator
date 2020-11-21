import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Common.dart';
import 'fsCollectionOperator.dart';

/* Cluster管理画面
   - 登録デバイス一覧表示
   - 新規デバイス登録
   - Cluster情報の編集
*/
class ClusterViewerPageWidget extends StatelessWidget {
  final String clusterId;
  final db = FirebaseFirestore.instance;

  ClusterViewerPageWidget({@required this.clusterId});

  @override
  Widget build(BuildContext context) {
    return FsQueryOperatorAppWidget(
      db.collection("device").where("cluster", isEqualTo: clusterId),
      itemBuilder: (context, index, snapshots) =>
          buildCellWidget(context, snapshots.data.docs[index]),
      appBar: AppBar(
        title: Text("${clusterId} Cluster Viewer"),
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(child: Text("Add Generic Device Entry"), value: 1),
              PopupMenuItem(child: Text("Add SNMP Device Entry"), value: 2),
              PopupMenuItem(child: Text("Add HTTP Device Entry"), value: 3),
            ],
            onSelected: (value) => naviPush(context, (_) {
              if (value == 1)
                naviPush(
                    context,
                    (_) => DocumentPageWidget(
                        db.collection("group").doc(clusterId)));
              else if (value == 2)
                pushDocEditor(context, db.collection("group").doc(clusterId));
              else if (value == 3)
                pushDocEditor(context, db.collection("group").doc(clusterId));
            }),
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () =>
                pushDocEditor(context, db.collection("group").doc(clusterId)),
          )
        ],
      ),
      onAddButtonPressed: (_) {
        return DocumentPageWidget(
            FirebaseFirestore.instance.collection("device").doc());
      },
    );
  }
}
