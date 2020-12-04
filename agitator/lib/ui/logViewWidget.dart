import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/Common.dart';
import 'package:riotagitator/ui/fsCollectionOperator.dart';

class DeviceLogsPage extends StatefulWidget {
  DeviceLogsPage(this.devRef);

  DocumentReference devRef;

  @override
  _DeviceLogsPageState createState() => _DeviceLogsPageState();
}

class _DeviceLogsPageState extends State<DeviceLogsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Log Viewer")),
      body: StreamBuilder<DocumentSnapshot>(
          stream: widget.devRef.snapshots(),
          builder: (context, devSnapshot) {
            if (!devSnapshot.hasData)
              return Center(child: CircularProgressIndicator());
            DocumentReference filterConfig = devSnapshot.data.reference
                .collection("app1")
                .doc("filterConfig");
            return StreamBuilder<DocumentSnapshot>(
                stream: devSnapshot.data.reference
                    .collection("app1")
                    .doc("filterConfig")
                    .snapshots(),
                builder: (context, devApp1FilterSnapshot) {
                  if (!devApp1FilterSnapshot.hasData)
                    return Center(child: CircularProgressIndicator());
                  List<dynamic> filterList =
                      devApp1FilterSnapshot.data.data()["filter"];
                  print("F1: $filterList"); //TODO
                  return Column(children: [
                    IconButton(
                      icon: Icon(Icons.filter_list),
                      onPressed: () {
                        naviPush(
                            context, (_) => DocumentPageWidget(filterConfig));
                      },
                    ),
                    FilterListConfigWidget(filterList),
                    Expanded(
                      child: PrograssiveItemViewWidget(devSnapshot
                          .data.reference
                          .collection("logs")
                          .addFilters(filterList)
                          .limit(20)),
                    ),
                  ]);
                });
          }),
    );
  }
}

// QueryにFilterを追加する拡張関数
extension QueryOperation on Query {
  Query addFilters(List<dynamic> filterList) {
    return filterList.fold(this, (a, e) {
      print("Filter: $e"); //TODO
      String filterOp = e["op"];
      String field = e["field"];
      String value = e["value"];
      String type = e["type"];

      if (filterOp == "sort") {
        return a.orderBy(field, descending: value == "true");
      } else if (filterOp == "==") {
        return this.where(field, isEqualTo: int.parse(value));
      } else if (filterOp == ">=") {
        return this
            //.orderBy(field)
            .where(field, isGreaterThanOrEqualTo: int.parse(value));
      } else if (filterOp == "<=") {
        return this
            //.orderBy(field)
            .where(field, isLessThanOrEqualTo: int.parse(value));
      } else if (filterOp == ">") {
        return this
            //.orderBy(field)
            .where(field, isGreaterThan: int.parse(value));
      } else if (filterOp == "<") {
        return this
            //.orderBy(field)
            .where(field, isLessThan: int.parse(value));
      } else {
        print("throw:");
        throw Exception();
      }
    });
  }

  Query addWhere(String field, String filterOp, String type, String value) {
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
          widget.qrItems.get().then((value) {
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
  }
}

class FilterListConfigWidget extends StatelessWidget {
  FilterListConfigWidget(this.filterList);

  // DocumentReference docDevConfig;
//  List<Map<String, dynamic>> filterList;
  List<dynamic> filterList;

  @override
  Widget build(BuildContext context) {
    try {
      if (filterList == null) throw Exception();
    } catch (e, st) {
      print("Exception: $st");
    }

    return Column(
      children: filterList.map((e) => FilterConfigWidget(e)).toList(),
    );
  }
}

class FilterConfigWidget extends StatefulWidget {
  FilterConfigWidget(this.filter);

  dynamic filter;

  @override
  State<StatefulWidget> createState() => _FilterConfigWidgetStatus();
}

class _FilterConfigWidgetStatus extends State<FilterConfigWidget> {
  String filterOperator;
  TextEditingController filterField = TextEditingController();
  String filterValType;
  TextEditingController filterValue = TextEditingController();

  @override
  Widget build(BuildContext context) {
    filterOperator = widget.filter["op"] ?? "sort";
    filterField.text = widget.filter["field"] ?? "timeRec";
    filterValType = widget.filter["type"] ?? "boolean";
    filterValue.text = widget.filter["value"] ?? "false";

    return Row(
      children: [
        Expanded(
            child: TextField(
          controller: filterField,
          decoration: InputDecoration(labelText: "Field"),
        )),
        Expanded(
          child: DropdownButton(
            hint: Icon(Icons.send),
            value: filterOperator,
            icon: Icon(Icons.arrow_drop_down),
            onChanged: (newValue) {
              setState(() {
                filterOperator = newValue;
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
            value: filterValType,
            icon: Icon(Icons.arrow_drop_down),
            onChanged: (newValue) {
              setState(() {
                filterValType = newValue;
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
          controller: filterValue,
          decoration: InputDecoration(labelText: "Value"),
        )),
      ],
    );
  }
}
