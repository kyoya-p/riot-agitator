import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/*
 ドキュメント数をカウントし、サマリを保存する
 logCount/segment=
 {
   since: Timestamp
   period: int //in sec
   count: int
 }
*/

void countTest() async {
  Firebase.initializeApp();
  await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: "kyoya.p4@gmail.com", password: "kyoyap4");

  User user = FirebaseAuth.instance.currentUser;
  //print(user); //TODO
  FirebaseFirestore db = FirebaseFirestore.instance;
  Query targetItems = db.collection("device/KK1/logs").orderBy("time");
  CollectionReference summaryCollection = db.collection("tmpCount");
  makeCountSummary(
    targetItems,
    summaryCollection,
    "time",
    DateTime.now().toUtc().millisecondsSinceEpoch,
    1000,
  );
}

makeCountSummary(
  Query targetItems,
  CollectionReference summaryCollection,
  String timeField,
  int time,
  int resolutionInSecond,
) async {
  int totalCount = 0;
  int lastTotalCount = 0;
  int lastTime = 0;

  await listItems(targetItems, timeField, time, (e) {
    int t = e[timeField] ~/ resolutionInSecond * resolutionInSecond;
    if (t != lastTime) {
      //Count Fix
      CountSegment seg = CountSegment(lastTime, t - lastTime,
          totalCount: totalCount, count: totalCount - lastTotalCount);
      lastTotalCount = totalCount;
      print(seg);
      summaryCollection.doc("${seg.since}:${seg.period}").set(seg.toMap());
      lastTime = t;
    } else {
      print(totalCount);
    }
    totalCount = totalCount + 1;
  });
  if (time ~/ resolutionInSecond != lastTime) {
    print(CountSegment(
        lastTime, (time ~/ resolutionInSecond * resolutionInSecond) - lastTime,
        totalCount: totalCount, count: totalCount - lastTotalCount));
  }
}

/*Future<int> makeCountSummary_X1(
  Query targetItems,
  CollectionReference summaryCollection,
  String timeField,
  int time,
  int minResolutionInSecond,
) async {
  List<CountSegment> currentCountSegs = List.from([], growable: true);

  listItems(targetItems, timeField, time, (e) {
    int t = e[timeField]; //TODO
    List<CountSegment> newCountSegs = makeSegments(t);

    for (int i = 0; i < newCountSegs.length; ++i) {
      if (currentCountSegs.length <= i) currentCountSegs.add(newCountSegs[i]);
      if (currentCountSegs[i].since == newCountSegs[i].since) {
        currentCountSegs[i].totalCount = currentCountSegs[i].totalCount + 1;
      } else {
        var e = currentCountSegs[i];
        print("[${e.since}~${e.period}:${e.totalCount}]");
        currentCountSegs[i] = newCountSegs[i]..totalCount = 1;
      }
    }
    String r = currentCountSegs
        .map((e) => "${e.since}~${e.period}:${e.totalCount}")
        .join(",");
    print("$t: $r");
  });

  return 0;
}

 */

listItems(
    Query targetItems, String timeField, int time, op(DocumentSnapshot)) async {
  QuerySnapshot logs =
      await targetItems.where(timeField, isLessThan: time).get();
  for (DocumentSnapshot e in logs.docs) {
    op(e);
  }
}

List<CountSegment> makeSegments(int time /*[sec]*/) {
  List<CountSegment> list = [
    for (int period = 1; period <= time; period *= 2)
      CountSegment(time ~/ period * period, period)
  ];
  return list;
}

class CountSegment {
  CountSegment(this.since, this.period, {this.totalCount = 0, this.count = 0});

  final int since;
  final int period;
  final int totalCount;
  final int count;

  String toString() => "${since}~${period}:${totalCount}(+$count)";

  Map<String, dynamic> toMap() => {
        "since": since,
        "period": period,
        "totalCount": totalCount,
        "count": count,
        "type": "test",
      };
}
