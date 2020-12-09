import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/ListenEvent.dart';

import 'Common.dart';

/*
 Firestore Collectionを操作するWidget - AppBar
 - Documentの追加/削除
 - DocumentがTapされた時の動作
 */

// ignore: must_be_immutable
class FsQueryOperatorAppWidget extends StatelessWidget {
  FsQueryOperatorAppWidget(this.query,
      {required this.itemBuilder,
      required this.appBar,
      required this.onAddButtonPressed});

  Query query;
  AppBar? appBar;

  Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots) itemBuilder;

  Widget Function(BuildContext context) onAddButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ??
          AppBar(
            title: Text("Title"),
            actions: [buildBell(context)],
          ),
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

  FsQueryOperatorWidget(this.query, {required this.itemBuilder});

  Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots) itemBuilder;

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshots) {
          if (!snapshots.hasData)
            return Center(child: CircularProgressIndicator());
          QuerySnapshot querySnapshotData = snapshots.data!;

          return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: w ~/ 170,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: 2.0),
              itemCount: querySnapshotData.size,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  child: Dismissible(
                    key: Key(querySnapshotData.docs[index].id),
                    child: itemBuilder(context, index, snapshots),
                    onDismissed: (_) =>
                        querySnapshotData.docs[index].reference.delete(),
                  ),
                );
              });
        });
  }
}

class FsCollectionOperatorAppWidget extends StatelessWidget {
  final String collectionId;

  FsCollectionOperatorAppWidget({required this.collectionId});

  @override
  Widget build(BuildContext context) {
    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection(collectionId);
    return Scaffold(
        appBar: AppBar(title: Text("$collectionId - Collection")),
        body: FsCollectionOperatorWidget(
          query: collectionRef,
          itemBuilder: (context, index, snapshots) => Text("XXX"),
        ),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.note_add),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DocumentPage(collectionRef.doc(null))));
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

  Widget Function(BuildContext context, int index,
      List<QueryDocumentSnapshot> snapshots) itemBuilder;

  Function(BuildContext context, int index, QuerySnapshot snapshots)? onTapItem;

  FsCollectionOperatorWidget(
      {required this.query, required this.itemBuilder, this.onTapItem = null}) {
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
                    DocumentPage(snapshot.docs[index].reference!)
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
          QuerySnapshot snapshotData = snapshot.data!;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: w ~/ 160,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 2.0),
            itemCount: snapshotData.size,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                //child: GestureDetector(
                //onTap: () {
                //  onTapItem(context, index, snapshot);
                //},
                child: Dismissible(
                  key: Key(snapshotData.docs[index].id),
                  child: itemBuilder(context, index, snapshotData.docs),
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

// Document編集Widget
class DocumentPage extends StatelessWidget {
  DocumentPage(DocumentReference dRef, {this.isIdEditable = true})
      : setDocWidget = DocumentWidget(dRef, isIdEditable: isIdEditable);

  final bool isIdEditable;
  DocumentWidget setDocWidget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Document")),
      body: setDocWidget,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () {
          try {
            setDocWidget.documentRef
                .set(JsonDecoder().convert(setDocWidget.textDocBody.text))
                .then((_) {
//                  Navigator.pop(context);
                }
            )
                .catchError((e) => showAlertDialog(context,
                    "${e.message}\nReq:${setDocWidget.documentRef.path}\nBody: ${setDocWidget.textDocBody.text}"));
          } catch (ex) {
            showAlertDialog(context, ex.toString());
          }
        },
      ),
    );
  }
}

pushDocEditor(BuildContext context, DocumentReference docRef) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DocumentPage(docRef)),
    );

class DocumentWidget extends StatefulWidget {
  DocumentWidget(this.documentRef, {this.isIdEditable = false});

  TextEditingController textDocBody = TextEditingController(text: "");

  DocumentReference documentRef;
  final bool isIdEditable;

  @override
  _DocumentWidgetState createState() => _DocumentWidgetState();
}

class _DocumentWidgetState extends State<DocumentWidget> {
  @override
  Widget build(BuildContext context) {
    TextEditingController docPath =
        TextEditingController(text: widget.documentRef.path);

    return Column(
      children: [
        TextField(
          controller: docPath,
          enabled: widget.isIdEditable,
          onSubmitted: widget.isIdEditable
              ? (v) => setState(() =>
                  widget.documentRef = widget.documentRef.firestore.doc(v))
              : null,
          decoration: InputDecoration(
            icon: Icon(Icons.location_pin),
            hintText:
                'Document Path. CollectionId/DocumentId/CollectionId/DocumentId/...',
          ),
        ),
        StreamBuilder(
            //stream: widget.dRef.snapshots(),
            stream: FirebaseFirestore.instance.doc(docPath.text).snapshots(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());
              if (!snapshot.hasData) widget.textDocBody.text = "";
              if (snapshot.hasData)
                widget.textDocBody.text =
                    JsonEncoder.withIndent("  ").convert(snapshot.data?.data());
              return TextField(
                controller: widget.textDocBody,
                decoration: InputDecoration(
                  icon: Icon(Icons.edit),
                  hintText: 'No document. This text must be in JSON format.',
                  //labelText: 'Document'
                ),
                maxLines: null,
              );
            }),
      ],
    );
  }
}
