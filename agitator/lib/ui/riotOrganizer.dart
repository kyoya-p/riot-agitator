import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riotagitator/ui/riotCluster.dart';

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
          return RiotClusterListAppWidget();
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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIOT HQ',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: RiotClusterListWidget(title: 'Device Clusters'),
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => MyApp(),
        //'/groupEditor': (BuildContext context) => GroupDeviceList(),
      },
    );
  }
}

class RiotClusterListWidget extends StatelessWidget {
  RiotClusterListWidget({Key key, this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      drawer: appDrawer(context),
      body: // Center(
      //child:
      FsQueryOperatorWidget(
        FirebaseFirestore.instance
            .collection("group")
            .where("operators.9Xi1QAyPBuQc9vk0INFu4CWzM8n1", isEqualTo: true),
        //TODO: use uid
        onTapItem: (context, index, snapshots) => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return ClusterAppWidget(clusterId: snapshots.data.docs[index].id);
          }),
        ),
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
          collectionListTile(context, "devConfig"),
          collectionListTile(context, "devStatus"),
          collectionListTile(context, "devLog"),
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
