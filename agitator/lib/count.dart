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
  Query targetItems = db.collection("tmp").orderBy("time");
  CollectionReference summaryCollection = db.collection("tmpCount");
  makeCountSummary(targetItems, summaryCollection, "time",
      Timestamp.fromMillisecondsSinceEpoch(15 * 1000), 1);
}

Future<int> makeCountSummary(
  Query targetItems,
  CollectionReference summaryCollection,
  String timeField,
  Timestamp time,
  int minResolutionInSecond,
) async {
  Map<int, CountSegment> currentCountSegments = {};

  listItems(targetItems, timeField, time, (e) {
    int t = e[timeField]; //TODO
    List<CountSegment> segs = makeSegments(t);
    String r = segs.map((e) => "${e.since}~${e.period}:${e.count}").join(",");
    print("$t: $r");

    for (e in segs) {
      if (currentCountSegments[e.period] == null) {}
    }
  });

  return 0;
}

listItems(Query targetItems, String timeField, Timestamp time,
    op(DocumentSnapshot)) async {
  QuerySnapshot logs =
      await targetItems.where(timeField, isLessThan: time.seconds).get();
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
  CountSegment(this.since, this.period);

  final int since;
  final int period;
  int count = 0;
}
