import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riotagitator/ui/riotOrganizer.dart';
import 'package:http/http.dart' as http;

import 'riotAgentMfpMib.dart';

/*
Firestore認証Widget
*/
class FbLoginPage extends StatefulWidget {
  @override
  _FbLoginPageState createState() => _FbLoginPageState();
}

class _FbLoginPageState extends State<FbLoginPage> {
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
                decoration: InputDecoration(
                    labelText: "Login ID (Mail Address / Device ID)"),
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
              Row(
                children: [
                  RaisedButton(
                    child: Text("Login"),
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
                  ),
                  Container(
                    padding: EdgeInsets.all(32.0),
                    child: RaisedButton(
                        child: Text("Login as Device"),
                        onPressed: () => loginAsDevice("", "")),
                  ),
                ],
              ),
              Text(debugMsg),
            ],
          ),
        ),
      ),
    );
  }

  loginAsUser(String mailAddr, String password) async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final UserCredential result = await auth.signInWithEmailAndPassword(
        email: loginUserEmail,
        password: loginUserPassword,
      );
      final User user = result.user;
      setState(() {
        debugMsg = "Success: ${user.email}";
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          //settings: const RouteSettings(name: "/home"),
          builder: (context) => MyApp(),
        ),
      );
    } catch (e) {
      setState(() {
        debugMsg = "Failed: ${e}";
        print(debugMsg);
      });
    }
  }

  loginAsDevice(String deviceId, String password) async {
    fetchCustomToken();

/*    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final UserCredential result = await auth.signInWithCustomToken();
      final User user = result.user;
      setState(() {
        debugMsg = "Success: ${user.email}";
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          //settings: const RouteSettings(name: "/home"),
          builder: (context) => MyApp(),
        ),
      );
    } catch (e) {
      setState(() {
        debugMsg = "Failed: ${e}";
        print(debugMsg);
      });
    }*/
  }

  void fetchCustomToken() async {
    const url = 'http://shokkaa.0t0.jp/customToken'; //TODO: this is Kawano's private service
    setState(() {
      debugMsg = "aaa";
    });

    http.get(url).then((response) {
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");
      setState(() {
        debugMsg = response.body;
      });
    });
  }
}
