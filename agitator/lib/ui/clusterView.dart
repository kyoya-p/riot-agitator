import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ChartSample.dart';
import 'Common.dart';
import 'Demo.dart';
import 'ListenEvent.dart';
import 'collectionPage.dart';
import 'documentPage.dart';

/* Cluster管理画面
   - 登録デバイス一覧表示
   - 新規デバイス登録
   - Cluster情報の編集
*/
class ClusterViewerPage extends StatelessWidget {
  ClusterViewerPage({required this.clusterId});

  final String clusterId;
  final db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return QueryViewPage(
      db.collection("device").where("dev.cluster", isEqualTo: clusterId),
      itemBuilder: (context, index, devSnapshots) =>
          buildCellWidget(context, devSnapshots.data!.docs[index]),
      appBar: AppBar(
        title: Text("${clusterId} - Cluster"),
        actions: [
          buildBell(context),
          PopupMenuButton<Widget Function(BuildContext)>(
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                  child: Text("Add Generic Device Entry"),
                  value: (_) =>
                      DocumentPage(db.collection("group").doc(clusterId))),
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
    );
  }
}
