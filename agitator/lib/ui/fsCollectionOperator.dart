import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/*
 Firestore Collectionを操作するWidget - AppBar
 - Docuemntの追加/削除
 - DocumentがTapされた時の動作
 */

// ignore: must_be_immutable
class FsCollectionOperatorAppWidget2 extends StatelessWidget {
  //String collectionId = "";
  CollectionReference collectionRef;

  FsCollectionOperatorAppWidget2({this.collectionRef});

  @override
  Widget build(BuildContext context) {
//    CollectionReference collectionRef =    FirebaseFirestore.instance.collection(collectionId);

    return Scaffold(
      appBar: AppBar(
        title: Text("${collectionRef.path} - Collection"),
      ),
      body: FsCollectionOperatorWidget(
        query: collectionRef,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.note_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SetDocumentAppWidget(
                    collectionRef: collectionRef, docId: null)),
          );
        },
      ),
    );
  }
}

// ignore: must_be_immutable
class FsCollectionOperatorAppWidget extends StatelessWidget {
  String collectionId = "";

  //CollectionReference cRef;

  FsCollectionOperatorAppWidget({this.collectionId});

  @override
  Widget build(BuildContext context) {
    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection(collectionId);

    return Scaffold(
      appBar: AppBar(
        title: Text("${collectionId} - Collection"),
      ),
      body: FsCollectionOperatorWidget(
        query: collectionRef,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.note_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SetDocumentAppWidget(
                    collectionRef: collectionRef, docId: null)),
          );
        },
      ),
    );
  }
}

/*
 Firestore Collectionを操作するWidget - コンテンツ部分
 - Docuemntの追加/削除
 - DocumentがTapされた時の動作
 */
class FsCollectionOperatorWidget extends StatelessWidget {
  //CollectionReference query;
  Query query;

  Widget Function(BuildContext context, int index, List<QueryDocumentSnapshot>)
      itemBuilder;

  Function(BuildContext context, int index,
      List<QueryDocumentSnapshot> snapshots) onTapItem;

  Stream<QuerySnapshot> _dbSnapshot;

  FsCollectionOperatorWidget({this.query, this.itemBuilder, this.onTapItem}) {
    _dbSnapshot = query.snapshots();
    if (itemBuilder == null) {
      itemBuilder = (context, index, docs) => Container(
            decoration: BoxDecoration(
              //border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(5),
              color: Theme.of(context).primaryColorLight,
            ),
            child: Text(docs[index].id),
          );
    }
    if (onTapItem == null) {
      onTapItem = (context, index, docs) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SetDocumentAppWidget(
                    collectionRef: query, docId: docs[index].id)
                //ObjectOperatorWidget(docRef: query.doc(docs[index].id)),
                ));
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return StreamBuilder(
        stream: _dbSnapshot,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (w / 160).toInt(),
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 2.0),
            itemCount: snapshot.data.size,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                child: GestureDetector(
                  onTap: () {
                    onTapItem(context, index, snapshot.data.docs);
                  },
                  child: Dismissible(
                    key: Key(snapshot.data.docs[index].id),
                    child: itemBuilder(context, index, snapshot.data.docs),
                    onDismissed: (direction) {
                      //query.doc(snapshot.data.docs[index].id).delete();
                      //snapshot.data.docs[index].delete();
                    },
                  ),
                ),
              );
            },
          );
        });
  }
}

class SetDocumentAppWidget extends StatefulWidget {
  String docId = null;
  CollectionReference collectionRef;

  SetDocumentAppWidget({@required this.collectionRef, this.docId});

  @override
  _SetDocumentAppState createState() =>
      _SetDocumentAppState(collectionRef: collectionRef, docId: docId);
}

class _SetDocumentAppState extends State<SetDocumentAppWidget> {
//class SetDocumentAppWidget extends StatelessWidget {

  String docId = null;
  CollectionReference collectionRef;

  _SetDocumentAppState({@required this.collectionRef, this.docId});

  @override
  Widget build(BuildContext context) {
    SetDocumentWidget setDocWidget =
        SetDocumentWidget(collectionRef: collectionRef, docId: docId);

    return Scaffold(
      appBar: AppBar(
          title: Text(
              "Set a document to ${collectionRef.path} / ${docId ?? "()"}")),
      body: setDocWidget,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () {
          try {
            /*setState(() {
              _duration = Duration(milliseconds: 300);
              jump = context.size.height ;
            });

             */
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SetDocumentAppWidget(
                      collectionRef: collectionRef,
                      docId: setDocWidget.textDocId.text),
                ));
            String newDocId = setDocWidget.textDocId.text;
            collectionRef
                .doc(newDocId)
                .set(json.decode(setDocWidget.textDocBody.text))
                .then((value) {})
                .catchError((e) => _showDialog(context, e.message));
          } catch (ex) {
            print(ex);
            _showDialog(context, ex.toString());
          }
        },
      ),
    );
  }

  Future _showDialog(context, String value) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('AlertDialog'),
        content: Text(value),
        actions: <Widget>[
          new SimpleDialogOption(
            child: new Text('Close'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class SetDocumentWidget extends StatelessWidget {
  String docId = null;
  CollectionReference collectionRef;

  Stream<DocumentSnapshot> dbDocSetting;

  var textDocId = TextEditingController(text: "");
  var textDocBody = TextEditingController(text: "{}");

  SetDocumentWidget({this.collectionRef, this.docId});

  @override
  Widget build(BuildContext context) {
    textDocId.text = docId;
    return Column(
      children: [
        TextField(
          controller: textDocId,
          decoration: InputDecoration(
            icon: Icon(Icons.label),
            hintText: 'If empty, the ID will be generated automatically.',
            labelText: 'Document ID',
          ),
        ),
        StreamBuilder(
            stream: collectionRef.doc(docId).snapshots(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());
              textDocBody.text =
                  JsonEncoder.withIndent(" ").convert(snapshot.data.data());
              return TextField(
                controller: textDocBody,
                decoration: InputDecoration(
                  icon: Icon(Icons.note_add),
                  hintText: 'This text must be in JSON format.',
                  labelText: 'Document',
                ),
                maxLines: null,
              );
            }),
      ],
    );
  }
}
