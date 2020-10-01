import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:state_notifier/state_notifier.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore Inquisitor',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Firestore Inquisitor'),
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
      ),
      body: FirestoreForm(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () {},
      ),
    );
  }
}

class FirestoreForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget collectionForm = TextFormField(
      decoration: InputDecoration(labelText: "collection"),
    );
    Widget whereForm = TextFormField(
      decoration: InputDecoration(labelText: "where"),
    );
    Widget orderByForm = TextFormField(
      decoration: InputDecoration(labelText: "order field"),
    );
    return Form(
      child: Column(
        children: [
          collectionForm,
          whereForm,
          orderByForm,
        ],
      ),
    );
  }
}
