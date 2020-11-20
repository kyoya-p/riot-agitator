import 'dart:html';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riotagitator/ui/riotCluster.dart';
import 'package:riotagitator/ui/riotOrganizer2.dart';
import 'firestoreWidget.dart';
import 'fsCollectionOperator.dart';

/* Landing page
  - Authentication Check
 */
class FirebaseSignInWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'RIOT Sign In', home: _getLandingPage());
  }

  Widget _getLandingPage() {
    return StreamBuilder<User>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          User user = snapshot.data;
          return RiotClusterListApp(user);
        } else {
          return FbLoginPage();
        }
      },
    );
  }
}

IconButton loginButton(BuildContext context) => IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FbLoginPage()),
        );
      },
      icon: Icon(Icons.account_circle),
    );

/*
  Cluster List Page (User Initial Page)
  - Move to Cluster Manager
  - Application Menu (Admin menus)
  - Login page
 */
class RiotClusterListAppWidget extends StatelessWidget {
  RiotClusterListAppWidget(User this.user);

  final User user;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIOT HQ',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: RiotClusterListWidget(user, title: 'Device Clusters'),
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => FirebaseSignInWidget(),
      },
    );
  }
}

class RiotClusterListWidget extends StatelessWidget {
  RiotClusterListWidget(this.user, {Key key, this.title}) : super(key: key);
  final String title;
  final User user;

  @override
  Widget build(BuildContext context) {
    Query qryMyOrgs = FirebaseFirestore.instance
        .collection("group")
        .where("users.${user.uid}", isEqualTo: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [loginButton(context)],
      ),
      drawer: appDrawer(context),
      body: FsQueryOperatorWidget(
        qryMyOrgs,
        itemBuilder: (context, index, snapshots) =>
            buildCellWidget(snapshots, index, context),
      ),
    );
  }

  Container buildCellWidget(
      AsyncSnapshot<QuerySnapshot> snapshots, int index, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.black12,
      ),
      child: GestureDetector(
        child: Text(snapshots.data.docs[index].id,
            overflow: TextOverflow.ellipsis),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClusterViewerPageWidget(
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
