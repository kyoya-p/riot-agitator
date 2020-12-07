import 'package:cloud_firestore/cloud_firestore.dart';

Future<int> makeCountSummary(
  Query targetItems,
  CollectionReference summayCollection,
  String timeFiled,
  Timestamp time,
  int minResolutionInSecond,
) async {
  int timeOrg = 0; // Epoch

  List<CountSegment> currentCountSegments;
  makeSegmentList(time.seconds);
  return 0;
}

List<CountSegment> makeSegmentList(int time /*[sec]*/) {
  List<CountSegment> list = [
    for (int period = 1; period < time; period *= 2) CountSegment(0, period)
  ];

  return list;
}

class CountSegment {
  CountSegment(this.since, this.period);

  int since;
  int period;
}
