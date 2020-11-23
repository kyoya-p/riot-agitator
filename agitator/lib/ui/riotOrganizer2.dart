import 'dart:html';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riotagitator/ui/riotCluster.dart';
import 'package:riotagitator/ui/riotOrganizer.dart';
import 'Common.dart';
import 'fsCollectionOperator.dart';

/*
  Cluster List Page (User Initial Page)
  - Move to Cluster Manager
  - Application Menu (Admin menus)
  - Login page
 */
class RiotApp extends StatelessWidget {
  RiotApp(User this.user);

  final User user;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIOT HQ',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: RiotGroupTreePage(user: user),
      routes: <String, WidgetBuilder>{
        "/home": (BuildContext context) => FirebaseSignInWidget(),
        "/wide": (BuildContext context) => FirebaseSignInWidget(), //TODO
      },
    );
  }
}

class RiotGroupTreePage extends StatelessWidget {
  RiotGroupTreePage({@required this.user, this.tgGroup = null});

//  final String title;
  final User user;
  final String tgGroup;
  final db = FirebaseFirestore.instance;
  bool v = false;

  @override
  Widget build(BuildContext context) {
    Query queryMyClusters = db.collection("group");
    queryMyClusters = (user != null)
        ? queryMyClusters.where("users.${user.uid}", //userログインしているなら
            isEqualTo: true) // 自身が管轄するすべてのgroup
        : queryMyClusters; //デバッグ(管理者)モードは全グループ表示

    // double w = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text("Clusters View"),
        actions: [loginButton(context)],
      ),
      //drawer: appDrawer(context),
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
          Map<String, QueryDocumentSnapshot> dispGrs;
          if (tgGroup == null) // topGroupが指定されていなければ自分の属する全グループのうち最上位のGroup
            dispGrs = Map.fromIterable(
                myGrs.entries
                    .where((e) => !myGrs.containsKey(e.value.data()["parent"])),
                key: (e) => e.key,
                value: (e) => e.value);
          else // topGroupが指定されていればそれに含まれるGroup
            dispGrs = Map.fromIterable(
                myGrs.entries.where((e) => e.value.data()["parent"] == tgGroup),
                key: (e) => e.key,
                value: (e) => e.value);
          return SingleChildScrollView(
              child:
                  GroupTreeWidget(user: user, myGrs: myGrs, listGrs: dispGrs));
        },
      ),
      floatingActionButton: user?.uid == null
          ? null
          : FloatingActionButton(
              child: Icon(Icons.create_new_folder),
              onPressed: () async {
                MySwitchListTile sw =
                    MySwitchListTile(title: Text("As device cluster"));
                TextEditingController name = TextEditingController();

                await showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                            title: Text('Create Group/Cluster'),
                            content: Column(children: [
                              TextField(
                                  controller: name,
                                  decoration:
                                      InputDecoration(labelText: "Name")),
                              sw,
                            ]),
                            actions: <Widget>[
                              new SimpleDialogOption(
                                  child: new Text('OK'),
                                  onPressed: () => Navigator.pop(context)),
                            ]));

                Map<String, Object> docGroup = {
                  "parent": tgGroup ?? "world",
                  "users": {user.uid: true},
                  "isDevCluster": sw.value,
                };
                print("${name.text}: ${docGroup}"); //TODO
                db.collection("group").doc(name.text).set(docGroup);
              }),
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

class GroupTreeWidget extends StatelessWidget {
  GroupTreeWidget(
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
          return Dismissible(
            key: Key(e.value.id),
            child: GroupWidget(user: user, myGrs: myGrs, group: e.value),
            onDismissed: (_) {
              e.value.reference.delete();
            },
          );
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
      onTap: () {
        bool isCluster = group.data()["isDevCluster"];
        if (isCluster != null && isCluster)
          return Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ClusterViewerPageWidget(clusterId: group.id)),
          );
        else
          return naviPush(
              context,
              (_) =>
                  RiotGroupTreePage(user: user, tgGroup: group.id));
      },
      child: Padding(
        padding: EdgeInsets.only(left: 0, top: 0, right: 0, bottom: 0),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: 2.0),
              left: BorderSide(color: Colors.white, width: 2.0),
            ),
            color: group.data()["isDevCluster"] == true
                ? Theme.of(context).focusColor
                : Colors.brown[100],
          ),
          child: Column(children: [
            Row(
              children: [Text("${group.id}")],
            ),
            Padding(
              padding:
                  EdgeInsets.only(left: 24.0, top: 36, right: 0, bottom: 0),
              child: GroupTreeWidget(user: user, myGrs: myGrs, listGrs: subGrs),
            ),
          ]),
        ),
      ),
    );
  }
}
