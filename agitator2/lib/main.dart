// @dart=2.9

import 'package:flutter/material.dart';
import 'package:riotagitator/ui/groupTreePage.dart';
import 'package:riotagitator/ui_v2/riotApp.dart';

import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(FirebaseSignInWidget(appBuilder: (context, snapshot) => RiotApp(snapshot.data),));
}

/*
  Cluster List Page (User Initial Page)
  - Move to Cluster Manager
  - Application Menu (Admin menus)
  - Login page
 */
class RiotApp extends StatelessWidget {
  RiotApp(User this.user);

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
      routes: <String, WidgetBuilder>{
        "/home": (BuildContext context) => FirebaseSignInWidget(
            appBuilder: (context, snapshot) => RiotApp(snapshot.data)),
        "/v2": (BuildContext context) => FirebaseSignInWidget(
            appBuilder: (context, snapshot) => RiotAppWide(snapshot.data)),
      },
    );
  }
}