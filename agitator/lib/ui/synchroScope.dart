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

    List<Sample> samples = [
      Sample(DateTime(2021, 1, 1), 1),
      Sample(DateTime(2021, 1, 3), 3),
      Sample(DateTime(2021, 1, 4), 2),
      Sample(DateTime(2021, 1, 5, 10, 0), 3),
      Sample(DateTime(2021, 1, 5, 10, 30), 2),
      Sample(DateTime(2021, 1, 5, 12), 0),
    ];

    common.Series<Sample, DateTime>(
      id: 'Sales',
      colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      domainFn: (Sample s, _) => s.time,
      measureFn: (Sample s, _) => s.value,
      data: samples,
    );

    Stream<List<Sample>> sampler() async* {
      try {
        int now = DateTime.now().millisecondsSinceEpoch;
        DocumentSnapshot querySs = await synchro.get();
        Map<String, dynamic> queryData;
        if (querySs.exists) {
          queryData = querySs.data();
        } else {
          queryData = {
            "collectionGroup": "logs",
            "orderBy": [
              {"field": "time", "descending": false}
            ],
            "startTime": now - 24 * 3600 * 1000,
            "endTime": now,
            "resolution": 3600 * 1000,
            //"peak": 1,
          };
          synchro.set(queryData);
        }
        Query? query = QueryBuilder(queryData).build();
        if (query == null) return;

        List<Sample> smpl = [];
        int res = queryData["resolution"] ?? 3600;
        int start = queryData["startTime"] ?? now - 24 * 3600 * 1000;
        start = (start ~/ res) * res;
        int end = queryData["endTime"] ?? now;
        end = (end ~/ res) * res;
        //int peak = queryData["peak"] ?? 1;

        yield smpl;
        for (int i = 0; i < 100; ++i) {          //TODO 安全が確認されるまでmax100(破産防止)
          await Future.delayed(Duration(microseconds: 100)); //TODO 安全が確認されるまでディレイを入れる(破産防止)

          res = 60;
          start = (now ~/ 1000 - 3600) ~/ res * res;
          end = now ~/ 1000 ~/ res * res;
          print("start-end: $start-$end"); //TODO

          Query query1 = db //TODO logのtimeの多単位を仮に1secとしている
              .collectionGroup("logs")
              .where("time", isGreaterThanOrEqualTo: start)
              .where("time", isLessThan: end)
              .limit(1);

          List<DocumentSnapshot> docs = (await query1.get()).docs;
          if (docs.length == 0) break;
          Map<String, dynamic> s = docs[0].data();
          int t = s["time"] as int;
          if (t < 1893456000) t = t * 1000;
          t = (t ~/ res) * res;

          if (smpl.length >= 1 &&
              smpl.last.time.millisecondsSinceEpoch == t * 1000) {
//          smpl.last = Sample(DateTime.fromMillisecondsSinceEpoch(t*1000), 1);
          } else {
            smpl.add(Sample(DateTime.fromMillisecondsSinceEpoch(t * 1000), 1));
            yield smpl;
            print("Yield: smpl[${smpl.length}]"); //TODO
          }

          start = t + res ;
        }
        print("Done:NoData "); //TOD
      } catch (ex) {
        print("ex: $ex"); //TODO
      }
    }

    return StreamBuilder(
        stream: sampler(),
        builder: (BuildContext context, AsyncSnapshot<List<Sample>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          return Scaffold(
            appBar: AppBar(),
            body: synchroScopeWidget(snapshot.data!),
          );
        });
  }
}

Widget synchroScopeWidget(List<Sample> samples) => charts.TimeSeriesChart(
      [
        common.Series<Sample, DateTime>(
          id: 'Sales',
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
