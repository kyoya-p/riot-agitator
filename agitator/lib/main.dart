// @dart=2.9

import 'package:flutter/material.dart';
import 'package:riotagitator/ui/Common.dart';
import 'package:riotagitator/ui/ListenEvent.dart';
import 'package:riotagitator/ui/groupTreePage.dart';

//import 'trial/main_test_firestore.dart' as test_firestore;
//import 'trial/main_test_adduser.dart' as test_adduser;
//import 'trial/main_test_login.dart' as test_login;
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() {
  runApp(FirebaseSignInWidget());
  //runApp(test_firestore.MyApp()); //test用コード
  //runApp(test_adduser.MyApp()); //test用コード
  //runApp(test_login.MyApp()); //test用コード
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
        "/home": (BuildContext context) => FirebaseSignInWidget(),
        "/wide": (BuildContext context) => FirebaseSignInWidget(), //TODO
        "/float": (BuildContext context) =>
            naviPush(context, (_) => FloatSample()), //TODO
      },
    );
  }
}
