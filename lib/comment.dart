import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WriteComment extends StatelessWidget {
  WriteComment(this.target);

  final String target;
  final _textController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TODO translate
        title: Text("Write a comment"),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                // TODO translate
                labelText: "text",
              ),
            ),
          ),
          Align(
            child: RaisedButton(
              // TODO translate
              child: Text("Send"),
              onPressed: () async {
                Firestore.instance.collection("comments").add({
                  "created": Timestamp.now(),
                  "target": target,
                  "text": _textController.text,
                });
                Navigator.pop(context);
              },
              color: Colors.yellow,
            ),
          ),
        ],
      ),
    );
  }
}
