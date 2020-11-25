import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ChartSample.dart';
import 'Common.dart';
import 'Demo.dart';
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
      itemBuilder: (context, index, devSnapshots) =>
          buildCellWidget(context, devSnapshots.data.docs[index]),
      appBar: AppBar(
        title: Text("${clusterId} Cluster Viewer"),
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                  child: Text("Add Generic Device Entry"),
                  value: (_) => DocumentPageWidget(
                      db.collection("group").doc(clusterId))),
              PopupMenuItem(child: Text("Add SNMP Device Entry"), value: null),
              PopupMenuItem(
                  child: Text("Add HTTP Device Entry"),
                  value: (_) => DemoHumanHeatSensorCreatePage(clusterId)),
              PopupMenuItem(
                  child: Text("😊体感温度センサーデバイス追加"),
                  value: (_) => DemoHumanHeatSensorCreatePage(clusterId)),
              PopupMenuItem(
                  child: Text("Log Viewer"),
                  value: (_) => LogCountBarChartPage()),
            ],
            onSelected: (value) => naviPush(context, value),
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
