import 'package:flutter/material.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubble/bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class DialogScreen extends StatefulWidget {
  final String mylogin;
  final String friendlogin;
  final DocumentSnapshot companion;
  DialogScreen(this.mylogin, this.friendlogin, this.companion);
  @override
  State createState() => DialogScreenState();
}

class DialogScreenState extends State<DialogScreen> {
  final textEdit = TextEditingController();
  ScrollController _scrollController = ScrollController();
  StorageUploadTask task;
  String user1;
  String user2;

  @override
  Widget build(BuildContext context) {
    if (widget.mylogin.compareTo(widget.friendlogin) < 0) {
      user1 = widget.mylogin;
      user2 = widget.friendlogin;
    } else {
      user1 = widget.friendlogin;
      user2 = widget.mylogin;
    }
    final dbRef = Firestore.instance
        .collection("messages")
        .where("ref", isEqualTo: user1 + user2)
        .orderBy("created", descending: true)
        .snapshots();

    // TODO Move this stuff to message widget
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    double px = 1 / pixelRatio;

    BubbleStyle styleSomebody = BubbleStyle(
      nip: BubbleNip.leftTop,
      color: Colors.white,
      elevation: 1 * px,
      margin: BubbleEdges.only(top: 8.0, right: 50.0),
      alignment: Alignment.topLeft,
    );
    BubbleStyle styleMe = BubbleStyle(
      nip: BubbleNip.rightTop,
      color: Colors.orange[100],
      elevation: 1 * px,
      margin: BubbleEdges.only(top: 8.0, left: 50.0),
      alignment: Alignment.topRight,
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0.0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.companion['photo']),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  widget.companion['name'] + " " + widget.companion['surname']),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          if (task != null)
            Container(
                child: StreamBuilder(
              stream: task.events,
              builder: (context, snapshot) {
                Text subtitle;
                if (snapshot.hasData) {
                  final StorageTaskEvent event = snapshot.data;
                  final StorageTaskSnapshot taskSnapshot = event.snapshot;
                  String result;
                  if (task.isComplete) {
                    if (task.isSuccessful) {
                      result = 'Complete';
                    } else if (task.isCanceled) {
                      result = 'Canceled';
                    } else {
                      result = 'Failed ERROR: ${task.lastSnapshot.error}';
                    }
                  } else if (task.isInProgress) {
                    result = 'Uploading';
                  } else if (task.isPaused) {
                    result = 'Paused';
                  }
                  subtitle = Text(
                      "$result: ${taskSnapshot.totalByteCount} / ${taskSnapshot.bytesTransferred}");
                } else {
                  subtitle = Text("Starting...");
                }
                return ListTile(
                  title: Text("Photo Upload"),
                  subtitle: subtitle,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Offstage(
                        offstage: !task.isInProgress,
                        child: IconButton(
                          icon: const Icon(Icons.pause),
                          onPressed: () => task.pause(),
                        ),
                      ),
                      Offstage(
                        offstage: !task.isPaused,
                        child: IconButton(
                          icon: const Icon(Icons.file_upload),
                          onPressed: () => task.resume(),
                        ),
                      ),
                      Offstage(
                        offstage: task.isComplete,
                        child: IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: () => task.cancel(),
                        ),
                      ),
                      // Offstage(
                      //   offstage: !(task.isComplete && task.isSuccessful),
                      //   child: IconButton(
                      //     icon: const Icon(Icons.file_download),
                      //     onPressed: onDownload,
                      //   ),
                      // ),
                    ],
                  ),
                );
              },
            )),
          if (task != null) Divider(),
          Expanded(
            child: Container(
              child: StreamBuilder(
                stream: dbRef,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: snapshot.data.documents.length,
                    itemBuilder: (context, index) {
                      var message = snapshot.data.documents[index];
                      textEdit.clear();
                      DateTime date = message["created"].toDate();
                      return Bubble(
                        style: widget.mylogin == message['author']
                            ? styleMe
                            : styleSomebody,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(message['text']),
                            Text(
                              "${date.hour}:${date.minute}",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.attach_file),
                onPressed: () async {
                  final String uuid = Uuid().v1();
                  var file =
                      await ImagePicker.pickImage(source: ImageSource.gallery);
                  final StorageReference ref =
                      FirebaseStorage.instance.ref().child('$uuid');
                  final StorageUploadTask uploadTask = ref.putFile(file);
                  setState(() {
                    task = uploadTask;
                  });
                },
              ),
              Expanded(
                child: TextField(
                  controller: textEdit,
                  decoration: InputDecoration(
                      border: InputBorder.none, hintText: 'Напишите сообщение'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios),
                onPressed: () async {
                  Firestore.instance.collection("messages").add({
                    "text": textEdit.text,
                    "author": widget.mylogin,
                    "viewed": false,
                    "created": Timestamp.now(),
                    "ref": user1 + user2,
                  });
                  textEdit.clear();
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}
