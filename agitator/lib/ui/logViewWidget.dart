import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceLogsPage extends StatelessWidget {
  DeviceLogsPage(this.dRef);

  DocumentReference dRef;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text("Log Viewer")),
      body: PrograssiveItemViewWidget(dRef
          .collection("logs")
          .orderBy("timeRec", descending: true)
          .limit(20)));
}

// Firestoreで大きなリストを使う際のテンプレ
class PrograssiveItemViewWidget extends StatefulWidget {
  PrograssiveItemViewWidget(this.qrItems);

  Query qrItems;
  List<DocumentSnapshot> listDocSnapshot = [];
  int itemCount = null;

  @override
  _PrograssiveItemViewWidgetState createState() =>
      _PrograssiveItemViewWidgetState();
}

class _PrograssiveItemViewWidgetState extends State<PrograssiveItemViewWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: widget.itemCount,
        itemBuilder: (context, index) {
          print(index);
          if (index < widget.listDocSnapshot.length) {
            return buildListTile(index, widget.listDocSnapshot[index].data());
          } else if (index > widget.listDocSnapshot.length) {
            return null;
          }
          widget.qrItems.limit(20).get().then((value) {
            setState(() {
              if (value.size == 0) {
                widget.itemCount = widget.listDocSnapshot.length;
              } else {
                widget.listDocSnapshot.addAll(value.docs);
                widget.qrItems =
                    widget.qrItems.startAfterDocument(value.docs.last);
              }
              print("Query: ${value.size} / List: ${widget.listDocSnapshot.length}");
            });
          });

          return Center(child: CircularProgressIndicator());
        });
  }

  Widget buildListTile(int index, Map<String, dynamic> doc) {
    Widget padding = Padding(
      padding: EdgeInsets.only(left: 10),
    );
    return Card(
      child: Row(children: [
        Text("$index"),
        padding,
        Text(doc["timeRec"].toDate().toString()),
        padding,
        Text(doc["dev"]["id"]),
        padding,
        Text(doc["dev"]["type"]),
      ]),
    );
  }
}
