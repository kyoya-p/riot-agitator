import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riotagitator/ui/riotOrganizer.dart';

import 'deviceOperator.dart';

/*
Firestore認証Widget
*/
class MyAuthPage extends StatefulWidget {
  @override
  _MyAuthPageState createState() => _MyAuthPageState();
}

class _MyAuthPageState extends State<MyAuthPage> {
  String loginUserEmail = "";
  String loginUserPassword = "";
  String debugMsg = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            children: <Widget>[
              Container(height: 32),
              TextFormField(
                decoration:
                    InputDecoration(labelText: "Login ID (Mail Address)"),
                onChanged: (String value) {
                  setState(() {
                    loginUserEmail = value;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
                onChanged: (String value) {
                  setState(() {
                    loginUserPassword = value;
                  });
                },
              ),
              RaisedButton(
                onPressed: () async {
                  try {
                    final FirebaseAuth auth = FirebaseAuth.instance;
                    final UserCredential result =
                        await auth.signInWithEmailAndPassword(
                      email: loginUserEmail,
                      password: loginUserPassword,
                    );
                    final User user = result.user;
                    setState(() {
                      debugMsg = "Success: ${user.email}";
                    });
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: "/home"),
                        builder: (context) => MyApp(),
                      ),
                    );
                  } catch (e) {
                    setState(() {
                      debugMsg = "Failed: ${e}";
                      print(debugMsg);
                    });
                  }
                },
                child: Text("Login"),
              ),
              Text(debugMsg),
            ],
          ),
        ),
      ),
    );
  }
}
