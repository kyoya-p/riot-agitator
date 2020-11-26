import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:cloud_firestore/cloud_firestore.dart';

class LogCountBarChartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: LogCountBarChart(),
      );
}

/*
 logを集約
  /logCount/{
    srcLog: CollectionRef //サマリ生成対象(通常はdeviceId)
    summaryLog: CollectionRef //サマリ生成対象(通常はdeviceId)
    since: Int  // サマリ対象開始期間(この時刻を含む)
    until: Int  // サマリ対象終了期間(この時刻を含まない)
    period: Int, // サマリ分解能: 1(1s)/60(1m)/3600(1h)/86400(1d)
    count: Int, // ログ数
  }
 */
class SummaryLog {
  SummaryLog(int this.since, int this.until, int this.period, int this.count);

  String type = "type=log:summary";
  int since; //millisecond
  int until;
  int period; //millisecond
  int count;
}

Function summarizeLogs(CollectionReference srcLog,
    CollectionReference summaryLog, int since, int period) {
  srcLog
      .where("time", isGreaterThanOrEqualTo: since)
      .where("time", isLessThan: since + period)
      .get()
      .then((data) {
    int count = data.size;
    SummaryLog slog = SummaryLog(since, since + period, period, count);
    summaryLog.doc().set(slog as Map<String,dynamic>);
  });
}

/*
 https://pub.dev/packages/charts_flutter

 コレクショングループに対してインデクスを参照するQuery(orderBy等)を実行する場合、
 コンソールからコレクショングループに対するインデクスを有効にする必要がある
 [CollectionGroup] [Cart]
 */

class LogCountBarChart extends StatelessWidget {
  LogCountBarChart();

  List<charts.Series<LogCountValue, String>> seriesList(
          List<LogCountValue> data) =>
      [
        charts.Series<LogCountValue, String>(
          id: 'Sales',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (LogCountValue sales, _) => sales.label,
          measureFn: (LogCountValue sales, _) => sales.value,
          data: data,
        )
      ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup(
                "logs") // collection group query //サブコレクションを含むすべてのlogsコレクションをcollect
            //.where("type", isNull: true)
            //.where("value", isGreaterThanOrEqualTo: -1)
            //.where("value", isLessThanOrEqualTo: 1) // valueとtimeの複数のフィールを参照するクエリの場合は
            .where("value", whereIn: [1, -1])
            .orderBy("time", descending: true) // コンソールで複合キーを設定しなければならない
            .limit(30)
            .snapshots(),
        builder: (context, snapshots) {
          if (!snapshots.hasData)
            return Center(
              child: Column(children: [
                CircularProgressIndicator(),
                SelectableText(snapshots.toString())
              ]),
            );
          return Table(
            children: snapshots.data.docs
                .map((e) => TableRow(children: [
                      TableCell(
                          child: Text(DateTime.fromMillisecondsSinceEpoch(
                                  e.data()["time"],
                                  isUtc: false)
                              .toString())),
                      TableCell(
                        child: Text(e.data()["value"].toString()),
                      )
                    ]))
                .toList(),
          );
        });
  }

  /// Create one series with sample hard coded data.
  /// TODO
  static List<charts.Series<LogCountValue, String>> _createSampleData() {
    final data = [];

    return [
      charts.Series<LogCountValue, String>(
        id: 'Sales',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (LogCountValue sales, _) => sales.label,
        measureFn: (LogCountValue sales, _) => sales.value,
        data: data,
      )
    ];
  }
}

class LogCountValue {
  final String label;
  final int value;

  LogCountValue(this.value, this.label);
}
