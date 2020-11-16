import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Common.dart';
import 'firestoreWidget.dart';
import 'fsCollectionOperator.dart';

/* Landing page
  - Authentication Check
 */
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'RIOT HQ', home: _getLandingPage());
  }

  Widget _getLandingPage() {
    return StreamBuilder<User>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          User user = snapshot.data;
          return RiotClusterListAppWidget(user);
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
        primarySwatch: Colors.lime,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: RiotClusterListWidget(user, title: 'Device Clusters'),
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => MyApp(),
        //'/groupEditor': (BuildContext context) => GroupDeviceList(),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [loginButton(context)],
      ),
      drawer: appDrawer(context),
      body: FsQueryOperatorWidget(
        FirebaseFirestore.instance
            .collection("group")
            .where("users.${user.uid}", isEqualTo: true),
        itemBuilder: (context, index, snapshots) =>
            buildCellWidget(context, snapshots.data.docs[index]),
        /* onTapItem: (context, index, snapshots) => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return ClusterViewerAppWidget(clusterId: snapshots.data.docs[index].id);
          }),
        ),

        */
        //),
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
