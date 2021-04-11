import 'package:flutter/material.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';

class SynchroScopePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final User user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: StreamBuilder(
        stream:,
      ),
    );
  }
}

Widget synchroScopeWidget(Map<String, dynamic> params) {

}
