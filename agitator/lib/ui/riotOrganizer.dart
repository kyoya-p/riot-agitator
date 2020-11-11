import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/riotGroupEditor.dart';

import 'firestoreWidget.dart';
import 'fsCollectionOperator.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Clusters',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Device Clusters'),
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => MyApp(),
        //'/groupEditor': (BuildContext context) => GroupDeviceList(),
      },
    );
  }
}

IconButton loginButton(BuildContext context) => IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyAuthPage()),
        );
      },
      icon: Icon(Icons.account_circle),
    );

class MyHomePage extends StatelessWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [loginButton(context)],
      ),
      drawer: appDrawer(context),
      body: Center(
        child: FsQueryOperatorWidget(
          FirebaseFirestore.instance
              .collection("group")
              .where("operators.9Xi1QAyPBuQc9vk0INFu4CWzM8n1", isEqualTo: true),
          //TODO: use uid
          /*onTapItem: (context, index, snapshots) => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              //return GroupDeviceList(groupId: snapshots[index].id);
              return ClusterAppWidget(clusterId: snapshots.data.docs[index].id);
            }),*/
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
