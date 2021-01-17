library v2;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:riotagitator/login.dart';
import 'package:riotagitator/ui/groupTreePage.dart';


void main() {
  runApp(FirebaseSignInWidget(
    appBuilder: (context, snapshot) => RiotAppWide(snapshot.data!),
  ));
}

/*
  Cluster List Page (User Initial Page)
  - Move to Cluster Manager
  - Application Menu (Admin menus)
  - Login page
 */
class RiotAppWide extends StatelessWidget {
  RiotAppWide(User this.user);

  final User user;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIOT HQ',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: GroupTreePage(user: user),
    );
  }
}
