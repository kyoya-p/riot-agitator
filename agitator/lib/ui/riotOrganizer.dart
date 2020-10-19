import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:riotagitator/ui/riotGroupEditor.dart';

import 'firestoreWidget.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clusters',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Clusters'),
      routes: <String, WidgetBuilder>{
        '/groupEditor': (BuildContext context) => new GroupDeviceEdit()
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
      body: Center(
        child: GroupListWidget(),
      ),
    );
  }
}
