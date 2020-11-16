import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riotagitator/ui/fsCollectionOperator.dart';
import 'package:riotagitator/ui/riotAgentMfpMib.dart';

Widget buildCellWidget(BuildContext context, QueryDocumentSnapshot snapshot) {
  Map<String, dynamic> data = snapshot.data();
  String type = data["type"];
  if (type == RiotAgentMfpMibAppWidget.type) {
    print("uuuuuu:$type"); // TODO
    return RiotAgentMfpMibAppWidget.makeCellWidget(context, snapshot);
  } else
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.black12,
      ),
      child: GestureDetector(
        child: Text(
            data["info"] != null
                ? (data["info"]["model"]) + "/" + (data["info"]["sn"])
                : snapshot.id,
            overflow: TextOverflow.ellipsis),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentPageWidget(snapshot.reference),
          ),
        ),
      ),
    );
}

// Common Styles
Decoration genericCellDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(5),
  color: Colors.black12,
);
