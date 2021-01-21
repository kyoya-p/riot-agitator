import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/ListenEvent.dart';

import 'Common.dart';
import 'documentPage.dart';

class QueryViewPage extends StatelessWidget {
  QueryViewPage(this.query,
      {this.itemBuilder, this.appBar, this.floatingActionButton,this.filter});

  Query query;
  AppBar? appBar;
  Widget? floatingActionButton;
  DocumentReference? filter;

  Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ?? defaultAppBar(context),
      body: QueryViewWidget(
        query,
        itemBuilder: itemBuilder,
      ),
      floatingActionButton:
      floatingActionButton, //TODO ?? defaultFloatingActionButton(context, dRef)
    );
  }

  AppBar defaultAppBar(BuildContext context) =>
      AppBar(
          title: Text("${query.parameters} - Query"),
          actions: [buildBell(context)]);

  FloatingActionButton defaultFloatingActionButton(BuildContext context,
      DocumentReference dRef) =>
      FloatingActionButton(
        child: Icon(Icons.note_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DocumentPage(dRef)),
          );
        },
      );
}

class QueryViewWidget extends StatelessWidget {
  QueryViewWidget(this.query, {this.itemBuilder});

  final Query query;

  Widget Function(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots)? itemBuilder;

  Widget defaultItemBuilder(BuildContext context, int index,
      AsyncSnapshot<QuerySnapshot> snapshots) {
    QueryDocumentSnapshot? e = snapshots.data?.docs[index];
    return Card(child: Text("$index: ${e?.id} ${e?.data()}"));
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery
        .of(context)
        .size
        .width;

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
                DocumentReference? dRef = snapshots.data?.docs[index].reference;

                return Container(
                    child: InkResponse(
                      onLongPress: () {
                        print("long");
                      },
                      child: Dismissible(
                        key: Key(querySnapshotData.docs[index].id),
                        child: itemBuilder != null
                            ? itemBuilder!(context, index, snapshots)
                            : dRef != null
                            ? buildGenericCard(context, dRef)
                            : Text("NULL"),
                        onDismissed: (_) =>
                            querySnapshotData.docs[index].reference.delete(),
                      ),
                    ));
              });
        });
  }

  AppBar defaultAppBar(BuildContext context) =>
      AppBar(
          title: Text("${query.parameters} - Query"),
          actions: [buildBell(context)]);

  FloatingActionButton defaultFloatingActionButton(BuildContext context,
      DocumentReference dRef) =>
      FloatingActionButton(
        child: Icon(Icons.note_add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DocumentPage(dRef)),
          );
        },
      );
}


