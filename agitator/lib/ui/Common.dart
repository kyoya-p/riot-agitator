import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/AgentMfpMib.dart';

import 'Demo.dart';
import 'documentPage.dart';
import 'logViewWidget.dart';

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
  String type = data["dev.type"];
  if (type == RiotAgentMfpMibAppWidget.type) {
    return RiotAgentMfpMibAppWidget.makeCellWidget(context, devSnapshot);
  } else if (type == DemoHumanHeatSensorCreatePage.type) {
    return DemoHumanHeatSensorCreatePage.makeCellWidget(context, devSnapshot);
  } else {
    return buildGenericCard(context, devSnapshot.reference);
  }
}

// Label: dev.nameまたはidを表示
// 長押しでメニュー
// - Document編集
// - logs表示
Widget buildGenericCard(BuildContext context, DocumentReference devRef) => Card(
    color: Theme.of(context).cardColor,
    child: StreamBuilder<DocumentSnapshot>(
        stream: devRef.snapshots(),
        builder: (streamCtx, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          String label =
              snapshot.data?.data()["dev"]["name"] ?? snapshot.data?.id;
          return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.black12,
              ),
              child: GestureDetector(
                  child: Text(label, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    showDialog(
                      context: streamCtx,
                      builder: (dialogCtx) {
                        return SimpleDialog(
                          title: Text(label),
                          children: [
                            SimpleDialogOption(
                                child: Text("Edit"),
                                onPressed: () {
                                  Navigator.pop(dialogCtx);
                                  naviPush(
                                      context, (_) => DocumentPage(devRef));
                                }),
                            SimpleDialogOption(
                                child: Text("Query"),
                                onPressed: () {
                                  Navigator.pop(dialogCtx);
                                  naviPush(
                                      context, (_) => DocumentPage(devRef.collection("query").doc()));
                                }),
                            SimpleDialogOption(
                                child: Text("Logs"),
                                onPressed: () {
                                  Navigator.pop(dialogCtx);
                                  naviPush(
                                      context, (_) => DeviceLogsPage(devRef.collection("logs")));
                                }),
                          ],
                        );
                      },
                    );
                  }));
        }));

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

naviPushReplacement(BuildContext context, WidgetBuilder builder) {
  Navigator.pushReplacement(
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
          return builder(context, snapshots);
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
  MySwitchListTile({required this.title, this.value = false});

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
