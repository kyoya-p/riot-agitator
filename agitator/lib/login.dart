import 'dart:html';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'ui/firestoreWidget.dart';

/* Landing page
  - Authentication Check
 */
class FirebaseSignInWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'RIOT Sign In', home: _getLandingPage());
  }

  Widget _getLandingPage() {
    return StreamBuilder<User>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          User user = snapshot.data!;
          return RiotApp(user);
        } else {
          return FbLoginPage();
        }
      },
    );
  }
}

IconButton loginButton(BuildContext context) => IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FbLoginPage()),
        );
      },
      icon: Icon(Icons.account_circle),
    );
