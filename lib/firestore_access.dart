import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

Future<DocumentSnapshot> getDevSettings(String name) {
  return firestore.collection('devSettings').doc(name).get();
}

Future<void> setDevSettings(String name, Map<String, dynamic> params) {
  DocumentReference dbDev = firestore.collection('devSettings').doc(name);
  return dbDev.set(params);
}
