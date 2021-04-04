import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

/* TODO
class CountViewPage extends StatelessWidget {
  CountViewPage({
    required this.queryFilter,
    required this.queryCountField,
  });

  final DocumentReference queryFilter;
  final DocumentReference queryCountField;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: queryFilter.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());
        return ;
      },
    );
  }
}
*/