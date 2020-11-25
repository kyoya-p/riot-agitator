import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/fsCollectionOperator.dart';
import 'package:riotagitator/ui/riotAgentMfpMib.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

import 'Demo.dart';

DecorationTween makeDecorationTween(Color c) => DecorationTween(
      begin: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(5.0),
      ),
      end: BoxDecoration(
        color: Colors.brown[100],
        borderRadius: BorderRadius.circular(5.0),
      ),
    );

Widget buildCellWidget(
    BuildContext context, QueryDocumentSnapshot devSnapshot) {
  Map<String, dynamic> data = devSnapshot.data();
  String type = data["type"];
  if (type == RiotAgentMfpMibAppWidget.type) {
    return RiotAgentMfpMibAppWidget.makeCellWidget(context, devSnapshot);
  } else if (type == DemoHumanHeatSensorCreatePage.type) {
    return DemoHumanHeatSensorCreatePage.makeCellWidget(context, devSnapshot);
  } else
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.black12,
      ),
      child: GestureDetector(
        child: Text(
            data["info"] != null
                ? (data["info"]["model"]) + "/" + (data["info"]["sn"])
                : devSnapshot.id,
            overflow: TextOverflow.ellipsis),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceLogsPage(devSnapshot.reference),
          ),
        ),
        onLongPress: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentPageWidget(devSnapshot.reference),
          ),
        ),
      ),
    );
}

class DeviceLogsPage extends StatelessWidget {
  DeviceLogsPage(this.dRef);

  DocumentReference dRef;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(),
      body: StreamBuilder<QuerySnapshot>(
          stream: dRef
              .collection("logs")
              .orderBy("time", descending: true)
              .limit(30)
              .snapshots(),
          builder: (context, snapshots) {
            if (!snapshots.hasData)
              return Center(child: CircularProgressIndicator());
            return Table(
              children: snapshots.data.docs
                  .map((e) => TableRow(children: [
                        TableCell(
                            child: Text(DateTime.fromMillisecondsSinceEpoch(
                                    e.data()["time"],
                                    isUtc: false)
                                .toString())),
                        TableCell(
                          child: Text(e.data()["type"]),
                        )
                      ]))
                  .toList(),
            );
          }));
}

// Common Styles
Decoration genericCellDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(5),
  color: Colors.black12,
);

// some snippet
naviPush(BuildContext context, WidgetBuilder builder) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: builder,
    ),
  );
}

Future showAlertDialog(context, String value) async {
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

Widget fsStreamBuilder(Query ref, AsyncWidgetBuilder builder) =>
    StreamBuilder<QuerySnapshot>(
        stream: ref.snapshots(),
        builder: (context, snapshots) {
          if (!snapshots.hasData)
            return Center(child: CircularProgressIndicator());
          builder(context, snapshots);
        });

Timer runPeriodicTimer(int start) =>
    Timer.periodic(Duration(milliseconds: 250), (timer) {
      int d = DateTime.now().toUtc().millisecondsSinceEpoch - start;
      if (d >= 5000) {
        timer.cancel();
      } else {
        //func()
      }
    });

class MySwitchListTile extends StatefulWidget {
  MySwitchListTile({this.title, this.value = false});

  Widget title;
  bool value;

  @override
  State<StatefulWidget> createState() => _MySwitchTileState();
}

class _MySwitchTileState extends State<MySwitchListTile> {
  @override
  Widget build(BuildContext context) => SwitchListTile(
        onChanged: (sw) {
          setState(() => widget.value = sw);
        },
        value: widget.value,
        title: widget.title,
      );
}

