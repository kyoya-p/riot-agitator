import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:riotagitator/ui/riotGroupEditor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestoreWidget.dart';
import 'fsCollectionOperator.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clusters',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Clusters'),
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => MyApp(),
        '/groupEditor': (BuildContext context) => GroupDeviceList(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyAuthPage(),
                  ));
            },
            icon: Icon(Icons.account_circle),
          ),
        ],
      ),
      drawer: appDrawer(),
      body: Center(
        child: GroupListWidget(),
      ),
    );
  }

  Widget appDrawer() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Text('Road to IoT'),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          ),
          ListTile(
            title: Text("All Devices"),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  settings: RouteSettings(
                    name: "/gr",
                  ),
                  builder: (context) =>
                      FsCollectionOperatorAppWidget(collectionId: "device"),
                ),
              );
            },
          ),
          ListTile(
            title: Text("All Device Logs"),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  settings: RouteSettings(
                    name: "/gr",
                  ),
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text("device - All Device Logs"),
                    ),
                    body: FsCollectionOperatorWidget(
                      query: FirebaseFirestore.instance.collection("devLog"),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
