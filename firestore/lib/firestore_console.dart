import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:state_notifier/state_notifier.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIOT Observer',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'RIOT Observer'),
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
  FirestoreForm firestoreForm = FirestoreForm('devLogs');
  Stream<QuerySnapshot> dbSnapshot;

  @override
  Widget build(BuildContext context) {
    dbSnapshot = FirebaseFirestore.instance
        .collection(firestoreForm.fsCollection.text)
        .snapshots();
    ObserverWidget observer = ObserverWidget(dbSnapshot);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Container(
            child: firestoreForm,
            padding: EdgeInsets.all(10),
          ),
          Expanded(
            child: observer,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () {
          setState(() {
            dbSnapshot = FirebaseFirestore.instance
                .collection(firestoreForm.fsCollection.text)
                .snapshots();
            var query = FirebaseFirestore.instance
                .collection(firestoreForm.fsCollection.text);

            if (firestoreForm.fsWhere.text.isNotEmpty) {
//              dbSnapshot = dbSnapshot.where((event) => false)
            }
          });
        },
      ),
    );
  }
}

class FirestoreForm extends StatelessWidget {
  TextEditingController fsCollection;

  TextEditingController fsWhere = TextEditingController(text: '');
  TextEditingController fsOrderBy = TextEditingController(text: '');

  FirestoreForm(collectionName) {
    fsCollection = TextEditingController(text: collectionName);
  }

  @override
  Widget build(BuildContext context) {
    Widget collectionForm = TextField(
      controller: fsCollection,
      decoration: InputDecoration(labelText: "collection"),
    );
    Widget whereForm = TextFormField(
      initialValue: '',
      decoration: InputDecoration(labelText: "where"),
    );
    Widget orderByForm = TextFormField(
      initialValue: '',
      decoration: InputDecoration(labelText: "order by"),
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

class ObserverWidget extends StatelessWidget {
  Stream<QuerySnapshot> dbSnapshot =
  FirebaseFirestore.instance.collection("devLogs").snapshots();

  ObserverWidget(this.dbSnapshot);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: dbSnapshot,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          return GridView.builder(
            gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemCount: snapshot.data.size,
            padding: EdgeInsets.all(2.0),
            itemBuilder: (BuildContext context, int index) {
              return Container(
                child: GestureDetector(
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(snapshot.data.docs[index].id);
                    },
                    child: Column(
                      children: <Widget>[
                        Text(snapshot.data.docs[index].id),
                        Text(snapshot.data.docs[index].data().toString()),
                      ],
                    )),
                padding: EdgeInsets.all(2.0),
              );
            },
          );
        });
  }
}
