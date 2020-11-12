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
  Query query;
  String title;

  Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots) itemBuilder;

  Function(BuildContext context, int index,
          AsyncSnapshot<QuerySnapshot> snapshots) onTapItem =
      (context, index, snapshots) {};

  Widget Function(BuildContext context) onAddButtonPressed;

  FsQueryOperatorAppWidget(
    this.query, {
    this.title = "Title",
    this.itemBuilder,
    this.onTapItem,
    this.onAddButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FsQueryOperatorWidget(
        query,
        itemBuilder: itemBuilder,
        onTapItem: onTapItem,
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

  Function(BuildContext context, int index,
          AsyncSnapshot<QuerySnapshot> snapshots) onTapItem =
      (context, index, snapshots) {};

  FsQueryOperatorWidget(this.query, {this.itemBuilder, this.onTapItem}) {
    itemBuilder = itemBuilder ?? defaultItemBuilder;
    onTapItem = onTapItem ?? defaultOnTapItem;
  }

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
                child: GestureDetector(
                  onTap: () {
                    onTapItem(context, index, snapshots);
                  },
                  child: Dismissible(
                    key: Key(snapshots.data.docs[index].id),
                    child: itemBuilder(context, index, snapshots) ??
                        defaultItemBuilder(context, index, snapshots),
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
        return FsSetDocumentAppWidget(doc.reference.parent, docId: doc.id);
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
      appBar: AppBar(
        title: Text("$collectionId - Collection"),
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
                builder: (_) =>
                    FsSetDocumentAppWidget(collectionRef, docId: null)),
          );
        },
      ),
    );
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
                builder: (context) => FsSetDocumentAppWidget(query,
                    docId: snapshot.data.docs[index].id)
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
                child: GestureDetector(
                  onTap: () {
                    onTapItem(context, index, snapshot);
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

class FsSetDocumentAppWidget extends StatefulWidget {
  final String docId;
  final CollectionReference collectionRef;

  FsSetDocumentAppWidget(this.collectionRef, {this.docId});

  FsSetDocumentAppWidget from(DocumentReference dRef) =>
      FsSetDocumentAppWidget(dRef.parent, docId: dRef.id);

  @override
  _SetDocumentAppState createState() =>
      _SetDocumentAppState(collectionRef: collectionRef, docId: docId);
}

class _SetDocumentAppState extends State<FsSetDocumentAppWidget> {
//class SetDocumentAppWidget extends StatelessWidget {

  String docId;
  CollectionReference collectionRef;

  _SetDocumentAppState({@required this.collectionRef, this.docId});

  @override
  Widget build(BuildContext context) {
    SetDocumentWidget setDocWidget =
        SetDocumentWidget(collectionRef: collectionRef, docId: docId);

    return Scaffold(
      appBar: AppBar(
          title: Text(
              "Set a document [${docId ?? "()"}] to [${collectionRef.path}] collection")),
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
                  builder: (context) => FsSetDocumentAppWidget(collectionRef,
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
  SetDocumentWidget({this.collectionRef, this.docId});

  final String docId;
  CollectionReference collectionRef;

  //Stream<DocumentSnapshot> dbDocSetting;

  var textDocId = TextEditingController(text: "");
  var textDocBody = TextEditingController(text: "{}");

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
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());
              if (snapshot.hasData)
                textDocBody.text =
                    JsonEncoder.withIndent(" ").convert(snapshot.data.data());
              return TextField(
                  controller: textDocBody,
                  decoration: InputDecoration(
                      icon: Icon(Icons.edit),
                      hintText: 'This text must be in JSON format.',
                      labelText: 'Document'),
                  maxLines: null);
            }),
      ],
    );
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
      appBar: AppBar(title: Text("${dRef.id} Configuration")),
      body: setDocWidget,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () {
          try {
            String newDocId = setDocWidget.textDocId.text;
            print(newDocId);//TODO
            print(dRef.parent.doc("G1").path);//TODO
            dRef.parent
                .doc(newDocId)
                .set(json.decode(setDocWidget.textDocBody.text))
                .then((_) => Navigator.pop(context))
                .catchError((e) => _showDialog(context, e.message));
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
          controller: TextEditingController(text: dRef.id),
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

  commit() {
    dRef.parent
        .doc(textDocId.text)
        .set(JsonDecoder().convert(textDocBody.text));
  }
}
