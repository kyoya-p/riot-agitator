import 'dart:html';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riotagitator/login.dart';
import 'package:riotagitator/ui/clusterViewPage.dart';
import 'Common.dart';
import 'ListenEvent.dart';
import 'collectionPage.dart';
import 'documentPage.dart';

class GroupTreePage extends StatelessWidget {
  GroupTreePage({required this.user, this.tgGroup});

  final User user;
  final String? tgGroup;
  final db = FirebaseFirestore.instance;
  bool v = false;

  @override
  Widget build(BuildContext context) {
    Query queryMyClusters = db.collection("group");
    queryMyClusters = (user != null)
        ? queryMyClusters.where("users.${user.uid}", //userログインしているなら
            isEqualTo: true) // 自身が管轄するすべてのgroup
        : queryMyClusters; //デバッグ(管理者)モードは全グループ表示

    return Scaffold(
      appBar: AppBar(
        title: Text("${tgGroup} - Group View"),
        actions: [
          globalGroupMenu(context),
          buildBell(context),
          loginButton(context)
        ],
      ),
      //drawer: appDrawer(context),
      body: StreamBuilder<QuerySnapshot>(
          stream: queryMyClusters.snapshots(),
          builder: (context, myClustersSnapshot) {
            if (myClustersSnapshot.data == null)
              return Center(child: CircularProgressIndicator());
            QuerySnapshot myClustersSnapshotData = myClustersSnapshot.data!;

            // 自分の属する全グループ
            Map<String, QueryDocumentSnapshot> myGrs = Map.fromIterable(
              myClustersSnapshotData.docs,
              key: (e) => e.id,
              value: (e) => e,
            );
            Map<String, QueryDocumentSnapshot> dispGrs;
            if (tgGroup == null) // topGroupが指定されていなければ自分の属する全グループのうち最上位のGroup
              dispGrs = Map.fromIterable(
                  myGrs.entries.where(
                      (e) => !myGrs.containsKey(e.value.data()["parent"])),
                  key: (e) => e.key,
                  value: (e) => e.value);
            else // topGroupが指定されていればそれに含まれるGroup
              dispGrs = Map.fromIterable(
                  myGrs.entries
                      .where((e) => e.value.data()["parent"] == tgGroup),
                  key: (e) => e.key,
                  value: (e) => e.value);
            return SingleChildScrollView(
                child: Column(
              children: [
                GroupTreeWidget(user: user, myGrs: myGrs, listGrs: dispGrs),
              ],
            ));
          }),

      floatingActionButton:
          (user.uid == null) ? null : floatingActionButtonBuilder2(context),
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

  floatingActionButtonBuilder1(BuildContext context) => FloatingActionButton(
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
                          decoration: InputDecoration(labelText: "Name")),
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
        };
        docGroup["type"] = {
          "group": sw.value ? {"cluster": {}} : {}
        };
        print("${name.text}: ${docGroup}"); //TODO
        db.collection("group").doc(name.text).set(docGroup);
      });

  floatingActionButtonBuilder2(BuildContext context) => FloatingActionButton(
      child: Icon(Icons.create_new_folder),
      onPressed: () async {
        naviPush(
            context,
            (_) => DocumentPage(db.collection("group").doc("__GroupID__"))
              ..setDocWidget.textDocBody.text = """
{
  "type":{"group":{}},
  "users":{
    "${firebaseAuth.currentUser.uid}": true
  }
}""");
      });
}

class GroupTreeWidget extends StatelessWidget {
  GroupTreeWidget(
      {required this.user, required this.myGrs, required this.listGrs});

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
  GroupWidget({required this.user, required this.myGrs, required this.group});

  final User user;
  final Map<String, QueryDocumentSnapshot> myGrs;
  final QueryDocumentSnapshot group;

  @override
  Widget build(BuildContext context) {
    Map<String, QueryDocumentSnapshot> subGrs = Map.fromEntries(
        myGrs.entries.where((e) => e.value.data()["parent"] == group.id));

    return GestureDetector(
      onTap: () {
        if (group.data().getNested(["type", "group", "cluster"]) != null)
          return naviPush(
              context, (_) => ClusterViewerPage(clusterId: group.id));
        else
          return naviPush(
              context, (_) => GroupTreePage(user: user, tgGroup: group.id));
      },
      onLongPress: () => showDocumentOperationMenu(group.reference, context),
      child: Padding(
        padding: EdgeInsets.only(left: 0, top: 0, right: 0, bottom: 0),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: 2.0),
              left: BorderSide(color: Colors.white, width: 2.0),
            ),
            color: group.data().getNested(["type", "group", "cluster"]) != null
                ? Theme.of(context).accentColor.shift(50, 50, 50)
                : Theme.of(context).primaryColor.withOpacity(0.1),
          ),
          //elevation: 4,
          /*color: group.data().getNested(["type", "group", "cluster"]) != null
              ? Theme.of(context).focusColor
              : Theme.of(context).cardColor,
          */
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

extension ColorExt on Color {
  Color scale(double v) => Color.fromARGB(this.alpha, (this.red * v).toInt(),
      (this.green * v).toInt(), (this.blue * v).toInt());

  Color shift(int r, int g, int b) =>
      Color.fromARGB(this.alpha, this.red + r, this.green + g, this.blue + b);
}
