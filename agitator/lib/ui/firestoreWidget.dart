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

/*
 QuerySnapshotに対応した項目を動的にGrid表示するパターンWidget
 - 指定されたDocumentSnapshotに対応する項目を削除
 */
class FsGridWidget extends StatelessWidget {
  CollectionReference query;

  Widget Function(BuildContext context, int index, List<QueryDocumentSnapshot>)
      itemBuilder;

  Function(BuildContext context, int index, List<QueryDocumentSnapshot>) onTap;

  Stream<QuerySnapshot> _dbSnapshot;

  FsGridWidget({this.query, this.itemBuilder, this.onTap}) {
    _dbSnapshot = query.snapshots();
    if (itemBuilder == null) {
      itemBuilder = (context, index, docs) => Text(docs[index].id);
    }
    if (onTap == null) {
      onTap = (context, index, docs) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ObjectOperatorWidget(docRef: query.doc(docs[index].id)),
            ));
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return StreamBuilder(
        stream: _dbSnapshot,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (w / 160).toInt(),
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 2.0),
            itemCount: snapshot.data.size,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                child: GestureDetector(
                  onTap: () {
                    onTap(context, index, snapshot.data.docs);
                  },
                  child: Dismissible(
                    key: Key(snapshot.data.docs[index].id),
                    child: itemBuilder(context, index, snapshot.data.docs),
                    onDismissed: (direction) {
                      query.doc(snapshot.data.docs[index].id).delete();
                    },
                  ),
                ),
              );
            },
          );
        });
  }
}
