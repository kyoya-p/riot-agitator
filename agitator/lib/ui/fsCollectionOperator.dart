import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'deviceOperator.dart';

/*
 Firestore Collectionを操作するWidget - AppBar
 - Docuemntの追加/削除
 - DocumentがTapされた時の動作
 */

// ignore: must_be_immutable
class FsCollectionOperatorAppWidget extends StatelessWidget {
  var collectionId = "";

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
                builder: (context) => SetDocumentAppWidget(
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
  CollectionReference query;

  Widget Function(BuildContext context, int index, List<QueryDocumentSnapshot>)
      itemBuilder;

  Function(BuildContext context, int index, List<QueryDocumentSnapshot>) onTap;

  Stream<QuerySnapshot> _dbSnapshot;

  FsCollectionOperatorWidget({this.query, this.itemBuilder, this.onTap}) {
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
    if (onTap == null) {
      onTap = (context, index, docs) {
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
                    onTap(context, index, snapshot.data.docs);
                  },
                  child: Dismissible(
                    key: Key(snapshot.data.docs[index].id),
                    child: itemBuilder(context, index, snapshot.data.docs),
                    onDismissed: (direction) {
                      query.doc(snapshot.data.docs[index].id).delete();
                    },
                  ),
                ),
              );
            },
          );
        });
  }
}

class SetDocumentAppWidget extends StatelessWidget {
  //String collectionId;
  //DocumentReference docRef;
  String docId = null;
  CollectionReference collectionRef;

  SetDocumentAppWidget({@required this.collectionRef, this.docId});

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
        child: Icon(Icons.send_and_archive),
        onPressed: () {
          try {
            print(setDocWidget.textDocBody.text);
            print(json.decode(setDocWidget.textDocBody.text));
            /*FirebaseFirestore.instance
                .collection(collectionId)
                .doc(setDocWidget.docId.text)
                .set(json.decode(setDocWidget.docText.text))
                .then((value) => Navigator.pop(context))
                .catchError((e) => _showDialog(context, e.message));
            */
            collectionRef
                .doc(docId)
                .set(json.decode(setDocWidget.textDocBody.text))
                .then((value) => Navigator.pop(context))
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
  //String collectionId = null;
  //DocumentReference docRef;
  String docId = null;
  CollectionReference collectionRef;

  Stream<DocumentSnapshot> dbDocSetting;

  var textDocId = TextEditingController(text: "");
  var textDocBody = TextEditingController(text: "{}");

  SetDocumentWidget({this.collectionRef, this.docId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: textDocId,
          decoration: InputDecoration(
            icon: Icon(Icons.label),
            //hintText: '',
            labelText: 'Document ID',
          ),
        ),
        StreamBuilder(
            stream: collectionRef.doc(docId).snapshots(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());

              print("Snapshot: $snapshot");
              textDocBody.text =
                  JsonEncoder.withIndent(" ").convert(snapshot.data.data());

              //textDocBody.text = "{}";
              return TextField(
                controller: textDocBody,
                decoration: InputDecoration(
                  icon: Icon(Icons.note_add),
                  hintText: 'This text must be in JSON format',
                  labelText: 'Document',
                ),
                maxLines: null,
              );
            }),
      ],
    );
  }
}
