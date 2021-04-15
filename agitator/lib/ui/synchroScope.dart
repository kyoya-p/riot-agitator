import 'package:flutter/material.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:charts_flutter/flutter.dart' as charts;

// ignore: import_of_legacy_library_into_null_safe
import 'package:charts_common/common.dart' as common;
import 'package:riotagitator/ui/QueryBuilder.dart';

import 'documentPage.dart';

class Sample {
  final DateTime time;
  final int value;

  Sample(this.time, this.value);
}

class SynchroScopePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final User user = FirebaseAuth.instance.currentUser;
    if (user.uid == null) return Center(child: CircularProgressIndicator());

    DocumentReference synchro = db.doc("user/${user.uid}/app1/synchro");

    int leftEnd = 0;
    int rightEnd = 0;
    int reso = 0;
    Stream<List<Sample>> sampler() async* {
      try {
        int now = DateTime.now().millisecondsSinceEpoch;
        await for (DocumentSnapshot querySs in synchro.snapshots()) {
          Map<String, dynamic> queryData;
          if (querySs.exists) {
            queryData = querySs.data();
          } else {
            queryData = {
              "collectionGroup": "logs",
              "orderBy": [
                {"field": "time", "descending": false}
              ],
              "endTime": now,
              "range": 24 * 3600 * 1000,
              "resolution": 3600 * 1000,
              "levelLimit": 3,
            };
          }
          Query? query = QueryBuilder(queryData).build();
          if (query == null) return;

          reso = queryData["resolution"] ?? 3600;
          int range = queryData["range"] ?? 24 * 3600 * 1000;
          range = (range ~/ reso) * reso;
          int end = queryData["endTime"] ?? now;
          end = (end ~/ reso) * reso;
          int start = end - range;
          int peak = queryData["levelLimit"] ?? 3;

          leftEnd = start;
          rightEnd = end;

          List<Sample> smpl = [];
          for (int i = start; i < end; i += reso) {
            smpl.add(Sample(DateTime.fromMillisecondsSinceEpoch(i), 0));
            print("${DateTime.fromMillisecondsSinceEpoch(i)}"); //TODO
          }

          yield smpl;
          for (int i = 0; i < 120; ++i) {
            //TODO 回数上限指定(破産防止)
            await Future.delayed(Duration(microseconds: 100));
            //TODO ディレイを入れる(破産防止)
            Query query1 = db //TODO logのtimeの多単位を仮に1secとしている
                .collectionGroup("logs")
                .where("time", isGreaterThanOrEqualTo: start ~/ 1000)
                .where("time", isLessThan: end ~/ 1000)
                .limit(peak);

            List<DocumentSnapshot> docs = (await query1.get()).docs;
            if (docs.length == 0) break;
            Map<String, dynamic> s = docs[0].data();
            int t = s["time"] as int;
            if (t < 1893456000) t = t * 1000;
            t = (t ~/ reso) * reso;

            QuerySnapshot levelSnapshot = await db
                .collectionGroup("logs")
                .where("time", isGreaterThanOrEqualTo: start ~/ 1000)
                .where("time", isLessThan: (start + reso) ~/ 1000)
                .limit(peak)
                .get();
            int level = levelSnapshot.docs.length;
            int idx = (t - leftEnd) ~/ reso;
            smpl[idx] = Sample(DateTime.fromMillisecondsSinceEpoch(t), level);
            yield smpl;
            print(
                "Yield: smpl[$idx]=Sample(${DateTime.fromMillisecondsSinceEpoch(t)},$level)"); //TODO

            start = t + reso;
          }
          print("Done:NoData "); //TOD0
        }
      } catch (ex) {
        print("ex: $ex"); //TODO
      }
    }

    Widget queryEditIcon(BuildContext context) => IconButton(
          icon: Icon(Icons.filter_list),
          onPressed: () => showDocumentEditorDialog(context, synchro),
        );

    return StreamBuilder(
        stream: sampler(),
        builder: (BuildContext context, AsyncSnapshot<List<Sample>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          return Scaffold(
            appBar: AppBar(
              title: Text(
                  "${DateTime.fromMillisecondsSinceEpoch(leftEnd)} ~ ${DateTime.fromMillisecondsSinceEpoch(rightEnd)} / ${reso ~/ 1000}[sec]"),
              actions: [queryEditIcon(context)],
            ),
            body: synchroScopeWidget(snapshot.data!),
          );
        });
  }
}

Widget synchroScopeWidget(List<Sample> samples) => charts.TimeSeriesChart(
      [
        common.Series<Sample, DateTime>(
          id: 'Level',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (Sample s, _) => s.time,
          measureFn: (Sample s, _) => s.value,
          data: samples,
        )
      ],
      animate: true,
      defaultRenderer: new charts.BarRendererConfig<DateTime>(),
      defaultInteractions: false,
      behaviors: [new charts.SelectNearest(), new charts.DomainHighlighter()],
    );
