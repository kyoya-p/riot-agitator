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

class FsCollectionOperatorAppWidget extends StatelessWidget {
  var collectionId = "";

  FsCollectionOperatorAppWidget({this.collectionId}) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${collectionId} - Collection"),
      ),
      body: FsCollectionOperatorWidget(
        query: FirebaseFirestore.instance.collection(collectionId),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.note_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    CreateDocumentAppWidget(collectionId: collectionId)),
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
              builder: (context) =>
                  ObjectOperatorWidget(docRef: query.doc(docs[index].id)),
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

class CreateDocumentAppWidget extends StatelessWidget {
  String collectionId;

  CreateDocumentAppWidget({this.collectionId}) {}

  @override
  Widget build(BuildContext context) {
    CreateDocumentWidget createDocWidget =
        CreateDocumentWidget(collectionId: collectionId);

    return Scaffold(
      appBar: AppBar(
          title: Text("Set a new document to ${collectionId} collection")),
      body: createDocWidget,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send_and_archive),
        onPressed: () {
          try {
            print(createDocWidget.initialDoc.text);
            print(json.decode(createDocWidget.initialDoc.text));
            FirebaseFirestore.instance
                .collection(collectionId)
                .doc(createDocWidget.docId.text)
                .set(json.decode(createDocWidget.initialDoc.text))
                //.then((value) => Navigator.pop(context))
                .catchError((e) => _showDialog(context, e.message));
            //.catchError((e) => {});
            //Navigator.pop(context);
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

  showResultDialog(context, String value) => showDialog(
      context: context,
      builder: (context) {
        Column(
          children: <Widget>[
            AlertDialog(
              title: Text("Error"),
              content: Text("aaa"),
              actions: <Widget>[
                // ボタン
              ],
            ),
          ],
        );
      });
}

class CreateDocumentWidget extends StatelessWidget {
  String collectionId;

  Stream<DocumentSnapshot> dbDocSetting;

  var docId = TextEditingController();
  var initialDoc = TextEditingController();

  CreateDocumentWidget({this.collectionId}) {}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: docId,
          decoration: InputDecoration(
            icon: Icon(Icons.label),
            //hintText: '',
            labelText: 'Document ID',
          ),
        ),
        TextField(
          controller: initialDoc,
          decoration: InputDecoration(
            icon: Icon(Icons.note_add),
            hintText: 'This text must be in JSON format',
            labelText: 'Document',
          ),
          maxLines: null,
        ),
      ],
    );
  }
}
