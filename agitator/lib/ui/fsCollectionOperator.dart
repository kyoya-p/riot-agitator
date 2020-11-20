import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/*
 Firestore Collectionを操作するWidget - AppBar
 - Documentの追加/削除
 - DocumentがTapされた時の動作
 */

// ignore: must_be_immutable
class FsQueryOperatorAppWidget extends StatelessWidget {
  FsQueryOperatorAppWidget(this.query,
      {@required this.itemBuilder, this.appBar, this.onAddButtonPressed});

  Query query;
  AppBar appBar = AppBar(title: Text("Title"));

  Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots) itemBuilder;

  Widget Function(BuildContext context) onAddButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: FsQueryOperatorWidget(
        query,
        itemBuilder: (context, index, snapshots) =>
            itemBuilder(context, index, snapshots),
      ),
      floatingActionButton: onAddButtonPressed == null
          ? null
          : FloatingActionButton(
              child: Icon(Icons.note_add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: onAddButtonPressed),
                );
              },
            ),
    );
  }
}

class FsQueryOperatorWidget extends StatelessWidget {
  final Query query;

  Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots) itemBuilder;

  FsQueryOperatorWidget(this.query, {@required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshots) {
          if (!snapshots.hasData)
            return Center(child: CircularProgressIndicator());

          return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: w ~/ 160,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: 2.0),
              itemCount: snapshots.data.size,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  child: Dismissible(
                    key: Key(snapshots.data.docs[index].id),
                    child: itemBuilder(context, index, snapshots),
                    onDismissed: (_) =>
                        snapshots.data.docs[index].reference.delete(),
                  ),
                );
              });
        });
  }

  Widget defaultItemBuilder(BuildContext context, int index,
          AsyncSnapshot<QuerySnapshot> snapshots) =>
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Theme.of(context).primaryColorLight,
        ),
        child: Row(children: [
          Icon(Icons.text_snippet_outlined),
          Text(snapshots.data.docs[index].id)
        ]),
//        child: Text(snapshots.data.docs[index].id),
      );

  defaultOnTapItem(
      BuildContext context, int index, AsyncSnapshot<QuerySnapshot> snapshots) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        QueryDocumentSnapshot doc = snapshots.data.docs[index];
        return DocumentPageWidget(doc.reference);
      },
    ));
  }
}

// ignore: must_be_immutable
class FsCollectionOperatorAppWidget extends StatelessWidget {
  String collectionId = "";

  FsCollectionOperatorAppWidget({this.collectionId});

  @override
  Widget build(BuildContext context) {
    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection(collectionId);
    return Scaffold(
        appBar: AppBar(title: Text("$collectionId - Collection")),
        body: FsCollectionOperatorWidget(query: collectionRef),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.note_add),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          DocumentPageWidget(collectionRef.doc(null))));
            }));
  }
}

/*
 Firestore Collectionを操作するWidget - コンテンツ部分
 - Documentの追加/削除
 - DocumentがTapされた時の動作
 */
class FsCollectionOperatorWidget extends StatelessWidget {
  CollectionReference query;

  Widget Function(BuildContext context, int index, List<QueryDocumentSnapshot>)
      itemBuilder;

  Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots) onTapItem;

  // Stream<QuerySnapshot> _dbSnapshot;

  FsCollectionOperatorWidget({this.query, this.itemBuilder, this.onTapItem}) {
    //_dbSnapshot = query.snapshots();
    if (itemBuilder == null) {
      itemBuilder = (context, index, docs) => Container(
            decoration: BoxDecoration(
              //border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(5),
              color: Theme.of(context).primaryColorLight,
            ),
            child: Row(children: [
              Icon(Icons.text_snippet_outlined),
              Text(docs[index].id)
            ]),
          );
    }
    if (onTapItem == null) {
      onTapItem = (context, index, snapshot) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    DocumentPageWidget(snapshot.data.docs[index].reference)
                //ObjectOperatorWidget(docRef: query.doc(docs[index].id)),
                ));
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return StreamBuilder(
        stream: query.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: w ~/ 160,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 2.0),
            itemCount: snapshot.data.size,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                //child: GestureDetector(
                //onTap: () {
                //  onTapItem(context, index, snapshot);
                //},
                child: Dismissible(
                  key: Key(snapshot.data.docs[index].id),
                  child: itemBuilder(context, index, snapshot.data.docs),
                  onDismissed: (direction) {
                    //query.doc(snapshot.data.docs[index].id).delete();
                    //snapshot.data.docs[index].delete();
                  },
                ),
                //),
              );
            },
          );
        });
  }
}

// Document更新Widget (リアルタイム更新)
class DocumentPageWidget extends StatelessWidget {
  DocumentPageWidget(this.dRef, {this.isIdEditable = false});

  DocumentReference dRef;
  final bool isIdEditable;

  @override
  Widget build(BuildContext context) {
    DocumentWidget setDocWidget =
        DocumentWidget(dRef, isIdEditable: isIdEditable);
    return Scaffold(
      appBar: AppBar(
          title: Text("${dRef.parent.id} / ${dRef.id} - Document Editor")),
      body: setDocWidget,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () {
          try {
            dRef
                .set(JsonDecoder().convert(setDocWidget.textDocBody.text))
                .then((_) => Navigator.pop(context))
                .catchError((e) => _showDialog(context,
                    e.message + "\nrequest: ${setDocWidget.textDocBody.text}"));
          } catch (ex) {
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
                      onPressed: () => Navigator.pop(context)),
                ]));
  }
}

pushDocEditor(BuildContext context, DocumentReference docRef) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DocumentPageWidget(docRef)),
    );

class DocumentWidget extends StatelessWidget {
  DocumentWidget(this.dRef, {this.isIdEditable = false});

  DocumentReference dRef;
  final bool isIdEditable;

  var textDocId = TextEditingController(text: "");
  var textDocBody = TextEditingController(text: "{}");

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: textDocId..text = dRef.id,
          enabled: isIdEditable,
          decoration: InputDecoration(
            icon: Icon(Icons.label),
            hintText: 'If empty, the ID will be generated automatically.',
            //labelText: 'Document ID',
          ),
        ),
        StreamBuilder(
            stream: dRef.snapshots(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());
              if (snapshot.hasData)
                textDocBody.text =
                    JsonEncoder.withIndent("  ").convert(snapshot.data.data());
              return TextField(
                controller: textDocBody,
                decoration: InputDecoration(
                  icon: Icon(Icons.edit),
                  hintText: 'This text must be in JSON format.',
                  //labelText: 'Document'
                ),
                maxLines: null,
              );
            }),
      ],
    );
  }
}
