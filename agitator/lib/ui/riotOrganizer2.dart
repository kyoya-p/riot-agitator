import 'dart:html';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riotagitator/ui/riotCluster.dart';
import 'package:riotagitator/ui/riotOrganizer.dart';
import 'fsCollectionOperator.dart';

/*
  Cluster List Page (User Initial Page)
  - Move to Cluster Manager
  - Application Menu (Admin menus)
  - Login page
 */
class RiotClusterListApp extends StatelessWidget {
  RiotClusterListApp(User this.user);

  final User user;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIOT HQ',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: RiotClusterListPage(user: user, title: 'Device Clusters'),
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => FirebaseSignInWidget(),
      },
    );
  }
}

class RiotClusterListPage extends StatelessWidget {
  RiotClusterListPage({@required this.user, this.title = ""});

  final String title;
  final User user;

  @override
  Widget build(BuildContext context) {
    Query queryMyClusters = FirebaseFirestore.instance
        .collection("group")
        .where("users.${user.uid}", isEqualTo: true); // 自身が管轄するすべてのgroup
    Query query = queryMyClusters;

    // double w = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text("Clusters View"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          Map<String, QueryDocumentSnapshot> myCls = Map.fromIterable(
            snapshot.data.docs,
            key: (e) => e.id,
            value: (e) => e,
          );
          List<MapEntry<String, QueryDocumentSnapshot>> myClsEntries =
              myCls.entries.toList();
          return GroupCellListWidget(user: user, groups: myClsEntries);
        },
      ),
    );
  }

  GridView buildGridView(
      double w, List<MapEntry<String, QueryDocumentSnapshot>> primaryCls) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: w ~/ 300,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          childAspectRatio: 2.0),
      itemCount: primaryCls?.length ?? 0,
      itemBuilder: (context, index) =>
          buildCellWidget(primaryCls, index, context),
    );
  }

  List<MapEntry<String, QueryDocumentSnapshot>> selectChildren(
          List<MapEntry<String, QueryDocumentSnapshot>> set, String parentId) =>
      set.where((e) => e.value.data()["parent"] == parentId).toList();

  Container buildCellWidget(
      List<MapEntry<String, QueryDocumentSnapshot>> primaryCls,
      int index,
      BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.brown[100],
      ),
      child: GestureDetector(
        child: Column(
          children: [
            Row(children: [
              Text(primaryCls[index].value.id,
                  textAlign: TextAlign.left, overflow: TextOverflow.ellipsis)
            ]),
            Row(
              children: [
                Padding(padding: EdgeInsets.all(10.0)),
                Column(
                  children: selectChildren(primaryCls, "")
                      .map((e) => Text(e.key))
                      .toList(),
                )
              ],
            )
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ClusterViewerAppWidget(clusterId: primaryCls[index].value.id),
          ),
        ),
      ),
    );
  }

  Widget appDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Text('Debugger for Admin'),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          ),
          collectionListTile(context, "device"),
          collectionListTile(context, "user"),
          collectionListTile(context, "group"),
        ],
      ),
    );
  }

  Widget collectionListTile(BuildContext context, String collectionId) {
    return ListTile(
      title: Text("${collectionId} collection"),
      trailing: Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FsCollectionOperatorAppWidget(collectionId: collectionId),
          ),
        );
      },
    );
  }
}

class GroupCellListWidget extends StatelessWidget {
  GroupCellListWidget({@required this.user, @required this.groups});

  final User user;
  final List<MapEntry<String, QueryDocumentSnapshot>> groups;

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: w ~/ 260,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          childAspectRatio: 2.0),
      itemCount: groups.length,
      //itemBuilder: (context, index) => buildCellWidget(groups, index, context),
      itemBuilder: (context, index) =>
          buildCellContents(user, groups[index].value),
    );
  }

  Container buildCellWidget(
      User user, QueryDocumentSnapshot group, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.brown[100],
      ),
      child: GestureDetector(
        child: buildCellContents(user, group),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClusterViewerAppWidget(clusterId: group.id),
          ),
        ),
      ),
    );
  }

  Column buildCellContents(
      @required User user, @required QueryDocumentSnapshot group) {
    return Column(children: [
      Row(children: [
        Text(group.id,
            textAlign: TextAlign.left, overflow: TextOverflow.ellipsis)
      ]),
      Padding(
        padding: EdgeInsets.only(left: 10.0),
        child: StreamBuilder(
            stream: group.reference.firestore
                .collection("group")
                .where("users.${user.uid}", isEqualTo: true)
                .where("parent", isEqualTo: group.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());
              //return Text(group.id);
              return Text(snapshot.data);
            }),
      ),
    ]);
  }

  List<MapEntry<String, QueryDocumentSnapshot>> selectChildren(
          List<MapEntry<String, QueryDocumentSnapshot>> set, String parentId) =>
      set.where((e) => e.value.data()["parent"] == parentId).toList();
}
