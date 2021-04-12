import 'package:flutter/material.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:charts_flutter/flutter.dart' as charts;

// ignore: import_of_legacy_library_into_null_safe
import 'package:charts_common/common.dart' as common;

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

/*    Future<List<Sample>> sampling() async {
      DocumentSnapshot querySs = await synchro.get();
      Map<String, dynamic> query;
      if (querySs.exists) {
        query = querySs.data();
      } else {
        int now = DateTime.now().microsecondsSinceEpoch;
        query = {
          "collectionGroup": "logs",
          "orderBy": [
            {"field": "time", "descending": false}
          ],
          "startTime": now - 24 * 3600 * 1000,
          "endTime": now,
          "resolution": 3600 * 1000,
        };
        synchro.set(query);
      }
      return List<Sample>(0);
    }
*/
    return StreamBuilder(
        stream: synchro.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          return Scaffold(
              appBar: AppBar(),
              body: charts.TimeSeriesChart(
                [
                  common.Series<Sample, DateTime>(
                    id: 'Sales',
                    colorFn: (_, __) =>
                        charts.MaterialPalette.blue.shadeDefault,
                    domainFn: (Sample s, _) => s.time,
                    measureFn: (Sample s, _) => s.value,
                    data: samples,
                  )
                ],
                animate: true,
                defaultRenderer: new charts.BarRendererConfig<DateTime>(),
                defaultInteractions: false,
                behaviors: [
                  new charts.SelectNearest(),
                  new charts.DomainHighlighter()
                ],
              ));
        });
  }
}
