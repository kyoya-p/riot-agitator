import 'dart:async';
import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Common.dart';
import 'ListenEvent.dart';

class DemoHumanHeatSensorCreatePage extends StatelessWidget {
  DemoHumanHeatSensorCreatePage(this.clusterId);

  final db = FirebaseFirestore.instance;
  final String clusterId;
  static final String type = "human.feeling_temperature";

  @override
  Widget build(BuildContext context) {
    TextEditingController id = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: Text("体感温度センサーデバイス追加"),
        actions: [buildBell(context)],
      ),
      body: TextField(
        autofocus: true,
        controller: id,
        decoration: InputDecoration(
          labelText: "Device ID (お名前)",
          hintText: "本名でなくてもよいので自分にわかる文字列を入力してください。",
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () {
          Map<String, Object> devDoc = {
            "cluster": clusterId,
            "password": "Sharp_#1",
            "type": type,
          };
          db
              .collection("device")
              .doc(id.text)
              .set(devDoc)
              .then((_) => Navigator.pop(context))
              .catchError((e) =>
                  showAlertDialog(context, e.message + "\nrequest: $devDoc"));
        },
      ),
    );
  }

  static Widget makeCellWidget(
          BuildContext context, QueryDocumentSnapshot devSnapshot) =>
      DemoHumanHeatSensorCell(
        devSnapshot: devSnapshot,
      );
}

class DemoHumanHeatSensorCell extends StatefulWidget {
  DemoHumanHeatSensorCell({this.devSnapshot});

  QueryDocumentSnapshot devSnapshot;

  @override
  State<StatefulWidget> createState() =>
      DemoHumanHeatSensorCellStatus(devSnapshot);
}

class DemoHumanHeatSensorCellStatus extends State<DemoHumanHeatSensorCell>
    with SingleTickerProviderStateMixin {
  DemoHumanHeatSensorCellStatus(QueryDocumentSnapshot this.devSnapshot);

  final QueryDocumentSnapshot devSnapshot;
  Color bgColor = Colors.grey[200];
  Timer timer;
  AnimationController _controller;

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..forward();
    //..repeat(reverse: false);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  logging(QueryDocumentSnapshot devSnapshot, int value) {
    devSnapshot.reference.collection("logs").doc().set({
      "value": value,
      "time": DateTime.now().toUtc().millisecondsSinceEpoch
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget buildButton(String label, Color color, int value) => FlatButton(
          minWidth: 80,
          height: 70,
          child: Text(label, style: TextStyle(color: color)),
          onPressed: () => logging(widget.devSnapshot, value),
        );
    return StreamBuilder(
        stream: devSnapshot.reference
            .collection("logs")
            .orderBy("time", descending: true)
            .limit(1)
            .snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshots) {
          if (!snapshots.hasData)
            return Center(child: CircularProgressIndicator());
          Color c;
          if (snapshots.data.size != 0) {
            Map<String, dynamic> log = snapshots.data.docs[0].data();
            int intr =
                DateTime.now().toUtc().millisecondsSinceEpoch - log["time"];
            c = log["value"] > 0
                ? Color.fromRGBO(255, 0, 0, 1)
                : Color.fromRGBO(0, 0, 255, 1);
            _controller.value = intr / 10000;
          }

          return GestureDetector(
            child: DecoratedBoxTransition(
                decoration:
                    makeDecorationTween(c).animate(_controller..forward()),
                child: Column(children: [
                  Row(children: [
                    Text("${devSnapshot.id}"),
                  ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        buildButton("Hot", Colors.red, 1),
                        buildButton("Cold", Colors.blue, -1),
                      ])
                ])),
            onLongPress: () =>
                naviPush(context, (_) => DeviceLogPage(devSnapshot)),
          );
        });
  }
}

class DeviceLogPage extends StatelessWidget {
  final QueryDocumentSnapshot devSnapshot;

  DeviceLogPage(this.devSnapshot);

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(),
      body: StreamBuilder<QuerySnapshot>(
          stream: devSnapshot.reference
              .collection("logs")
              .orderBy("time", descending: true)
              .limit(20)
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
                          child: Text((e.data()["value"] > 0) ? "Hot" : "Cold"),
                        )
                      ]))
                  .toList(),
            );
          }));
}
