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
        primarySwatch: Colors.blue,
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

    // double w = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text("Clusters View"),
        actions: [loginButton(context)],
      ),
      drawer: appDrawer(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: queryMyClusters.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          // 自分の属する全グループ
          Map<String, QueryDocumentSnapshot> myGrs = Map.fromIterable(
            snapshot.data.docs,
            key: (e) => e.id,
            value: (e) => e,
          );
          // 自分の属する全グループのうち最上位のグループ
          Map<String, QueryDocumentSnapshot> myTopGrs = Map.fromIterable(
              myGrs.entries
                  .where((e) => !myGrs.containsKey(e.value.data()["parent"])),
              key: (e) => e.key,
              value: (e) => e.value);
          return GroupListWidget(user: user, myGrs: myGrs, listGrs: myTopGrs);
        },
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

class GroupListWidget extends StatelessWidget {
  GroupListWidget(
      {@required this.user, @required this.myGrs, @required this.listGrs});

  final User user;
  final Map<String, QueryDocumentSnapshot> myGrs;
  final Map<String, QueryDocumentSnapshot> listGrs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          //borderRadius: BorderRadius.circular(5),
          //color: Colors.brown[100],
          ),
      child: Column(
        children: listGrs.entries.map((e) {
          return GroupWidget(user: user, myGrs: myGrs, group: e.value);
        }).toList(),
      ),
    );
  }
}

class GroupWidget extends StatelessWidget {
  GroupWidget(
      {@required this.user, @required this.myGrs, @required this.group});

  final User user;
  final Map<String, QueryDocumentSnapshot> myGrs;
  final QueryDocumentSnapshot group;

  @override
  Widget build(BuildContext context) {
    Map<String, QueryDocumentSnapshot> subGrs = Map.fromEntries(
        myGrs.entries.where((e) => e.value.data()["parent"] == group.id));

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ClusterViewerPageWidget(clusterId: group.id)),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 0, top: 0, right: 0, bottom: 0),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: 2.0),
              left: BorderSide(color: Colors.white, width: 2.0),
            ),
            color: group.data()["isDevCluster"] == true
                ? Theme.of(context).accentColor
                : Colors.brown[100],
          ),
          child: Column(children: [
            Row(
              children: [Text("${group.id}")],
            ),
            Padding(
              padding:
                  EdgeInsets.only(left: 25.0, top: 20, right: 0, bottom: 0),
              child: GroupListWidget(user: user, myGrs: myGrs, listGrs: subGrs),
            ),
          ]),
        ),
      ),
    );
  }
}
