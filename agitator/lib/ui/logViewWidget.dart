import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceLogsPage extends StatefulWidget {
  DeviceLogsPage(this.devRef);

  DocumentReference devRef;

  @override
  _DeviceLogsPageState createState() => _DeviceLogsPageState();
}

class _DeviceLogsPageState extends State<DeviceLogsPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text("Log Viewer")),
      body: Column(children: [
        FilterListConfigWidget(
            widget.devRef.collection("app1").doc("filterConfig")),
        Expanded(
          child: PrograssiveItemViewWidget(widget.devRef
              .collection("logs")
              //.addWhere(widget.filterField.text, widget.filterOperator,
              //    widget.filterValue.text)
              .orderBy("timeRec", descending: true)
              .limit(20)),
        )
      ]));

  void updated() {
    setState(() {});
  }
}

// QueryにFilterを追加する拡張関数
extension QueryOperation on Query {
  Query addWhere2(StatefulWidget w) {}

  Query addWhere(String field, String filterOp, String value) {
    if (field == "") return this;
    if (value == "") return this;

    if (filterOp == "==") {
      return this.where(field, isEqualTo: int.parse(value));
    } else if (filterOp == ">=") {
      return this
          .orderBy(field)
          .where(field, isGreaterThanOrEqualTo: int.parse(value));
    } else if (filterOp == "<=") {
      return this
          .orderBy(field)
          .where(field, isLessThanOrEqualTo: int.parse(value));
    } else if (filterOp == ">") {
      return this.orderBy(field).where(field, isGreaterThan: int.parse(value));
    } else if (filterOp == "<") {
      return this.orderBy(field).where(field, isLessThan: int.parse(value));
    }
  }
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
              print(
                  "Query: ${value.size} / List: ${widget.listDocSnapshot.length}");
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
      color: Theme.of(context).cardColor,
      child: Row(children: [
        Text("$index"),
        padding,
        Text(doc["timeRec"].toDate().toString()),
        padding,
        Text(doc["dev"]["id"]),
        padding,
        Text(doc["dev"]["type"]),
        padding,
        Text(doc["seq"].toString()),
      ]),
    );
  }s
}

class FilterListConfigWidget extends StatelessWidget {
  FilterListConfigWidget(this.docDevConfig);

  DocumentReference docDevConfig;
  List<Map<String, dynamic>> filterList;

  @override
  Widget build(BuildContext context) {
    print(docDevConfig.path); //TODO
    return StreamBuilder(
      stream: docDevConfig.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        filterList = snapshot.data["filter"];
        return Column(
          children: snapshot.data.map((e) => FilterConfigWidget(e)),
        );
      },
    );
  }
}

class FilterConfigWidget extends StatefulWidget {
  FilterConfigWidget(this.filter);

  dynamic filter;

  TextEditingController filterField = TextEditingController(text: 'timeRec');
  String filterOperator = "orderBy";
  String filterValType = "boolean";
  TextEditingController filterValue = TextEditingController(text: "false");

  @override
  State<StatefulWidget> createState() => FilterConfigWidgetStatus();
}

class FilterConfigWidgetStatus extends State<FilterConfigWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: TextField(
          controller: widget.filterField,
          decoration: InputDecoration(labelText: "Field"),
        )),
        Expanded(
          child: DropdownButton(
            hint: Icon(Icons.send),
            value: widget.filterOperator,
            icon: Icon(Icons.arrow_drop_down),
            onChanged: (newValue) {
              setState(() {
                widget.filterOperator = newValue;
              });
            },
            items: ['sort', '==', '>', '>=', '<=', '<']
                .map((String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: DropdownButton(
            value: widget.filterValType,
            icon: Icon(Icons.arrow_drop_down),
            onChanged: (newValue) {
              setState(() {
                widget.filterValType = newValue;
              });
            },
            items: ['number', 'string', 'boolean']
                .map((String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ))
                .toList(),
          ),
        ),
        Expanded(
            child: TextField(
          controller: widget.filterValue,
          decoration: InputDecoration(labelText: "Value"),
        )),
      ],
    );
  }
}
