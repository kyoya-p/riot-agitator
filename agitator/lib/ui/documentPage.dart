import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Common.dart';

// Document編集Widget
class DocumentPage extends StatelessWidget {
  DocumentPage(DocumentReference dRef, {this.isIdEditable = true})
      : setDocWidget = DocumentWidget(dRef, isIdEditable: isIdEditable);

  final bool isIdEditable;
  DocumentWidget setDocWidget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${setDocWidget.docPath.text} - Document")),
      body: setDocWidget,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () => setDocWidget.setDocument(context),
      ),
    );
  }
}

pushDocEditor(BuildContext context, DocumentReference docRef) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DocumentPage(docRef)),
    );

class DocumentWidget extends StatefulWidget {
  DocumentWidget(DocumentReference documentRef, {this.isIdEditable = false})
      : docPath = TextEditingController(text: documentRef.path);

  TextEditingController textDocBody = TextEditingController(text: "");
  TextEditingController docPath;
  final bool isIdEditable;

  setDocument(BuildContext context) {
    try {
      FirebaseFirestore.instance
          .doc(docPath.text)
          .set(JsonDecoder().convert(textDocBody.text))
          .then((_) {
//                  Navigator.pop(context);
      }).catchError((e) => showAlertDialog(context,
              "${e.message}\nReq:${docPath.text}\nBody: ${textDocBody.text}"));
    } catch (ex) {
      showAlertDialog(context, ex.toString());
    }
  }

  @override
  _DocumentWidgetState createState() => _DocumentWidgetState();
}

class _DocumentWidgetState extends State<DocumentWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.docPath,
          enabled: widget.isIdEditable,
          onSubmitted: widget.isIdEditable ? (v) => setState(() {}) : null,
          decoration: InputDecoration(
            icon: Icon(Icons.location_pin),
            hintText:
                'Document Path. CollectionId/DocumentId/CollectionId/DocumentId/...',
          ),
        ),
        StreamBuilder(
            stream:
                FirebaseFirestore.instance.doc(widget.docPath.text).snapshots(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());
              if (snapshot.data?.data() != null)
                widget.textDocBody.text =
                    JsonEncoder.withIndent("  ").convert(snapshot.data?.data());
              return Expanded(
                child: SingleChildScrollView(
                  child: TextField(
                    controller: widget.textDocBody,
                    decoration: InputDecoration(
                      icon: Icon(Icons.edit),
                      hintText: 'JSON format.',
                    ),
                    maxLines: null,
                  ),
                ),
              );
            }),
      ],
    );
  }
}
