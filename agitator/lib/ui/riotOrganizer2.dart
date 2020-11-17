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
class RiotClusterListAppWidget2 extends StatelessWidget {
  RiotClusterListAppWidget2(User this.user);

  final User user;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIOT HQ',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: RiotClusterListWidget2(user,
          parentCluster: null, title: 'Device Clusters'),
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => FirebaseSignInWidget(),
      },
    );
  }
}

class RiotClusterListWidget2 extends StatelessWidget {
  RiotClusterListWidget2(User this.user,
      {String this.parentCluster, Key key, this.title})
      : super(key: key);
  final String title;
  final User user;
  final String parentCluster;

  @override
  Widget build(BuildContext context) {
    Query queryMyClusters = FirebaseFirestore.instance
        .collection("group")
        .where("users.${user.uid}", isEqualTo: true);
    Query query = (parentCluster == null)
        ? queryMyClusters
        : queryMyClusters.where("parent", isEqualTo: parentCluster);

    double w = MediaQuery
        .of(context)
        .size
        .width;
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        Map<String, QueryDocumentSnapshot> myCls = Map.fromIterable(
          snapshot.data.docs,
          key: (e) => e.id,
          value: (e) => e,
        );
//        myCls.forEach((key, value) => print(
//            key + ":" + JsonEncoder.withIndent("  ").convert(value.data())));
        List<MapEntry<String, QueryDocumentSnapshot>> primaryCls =
        (parentCluster == null)
            ? myCls.entries
            .where((e) => !myCls.containsKey(e.value.data()["parent"]))
            .toList()
            : myCls.entries.toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [loginButton(context)],
          ),
          drawer: appDrawer(context),
          body: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: w ~/ 400,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 2.0),
            itemCount: primaryCls.length,
            itemBuilder: (context, index) =>
                buildCellWidget(primaryCls, index, context),
          ),
        );
      },
    );
  }

  List<MapEntry<String, QueryDocumentSnapshot>> selectChildren(
      List<MapEntry<String, QueryDocumentSnapshot>> set, String parentId) =>
      set.where((e) => e.value.data()["parent"] == parentId);

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
                  children:selectChildren(primaryCls,"").map((e) => Text(e.key)).toList(),
                )
              ],
            )
          ],
        ),
        onTap: () =>
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ClusterViewerAppWidget(
                        clusterId: primaryCls[index].value.id),
              ),
            ),
      ),
    );
  }

  Container buildCellWidgetXX(BuildContext context,
      AsyncSnapshot<QuerySnapshot> snapshots,
      int index,) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.black12,
      ),
      child: GestureDetector(
        child: Text(snapshots.data.docs[index].id,
            overflow: TextOverflow.ellipsis),
        onTap: () =>
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ClusterViewerAppWidget(
                        clusterId: snapshots.data.docs[index].id),
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
            decoration: BoxDecoration(color: Theme
                .of(context)
                .primaryColor),
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
