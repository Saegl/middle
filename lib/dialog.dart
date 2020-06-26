import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bubble/bubble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:middle/userdata.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DialogTile extends StatelessWidget {
  final String name;
  final String companionId;
  final String photo;
  final DocumentSnapshot companion;
  DialogTile(this.name, this.companionId, this.photo, this.companion);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: 16.0, top: 8.0, right: 16.0),
      leading: Container(
        height: 55,
        width: 55,
        child: CircleAvatar(
          radius: 50,
          backgroundImage: CachedNetworkImageProvider(photo),
        ),
      ),
      title: Text(this.name + " " + this.companion['surname']),
      subtitle: Text("online"),
      onTap: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String userId = prefs.getString("userId");
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    CustomDialog(userId, this.companionId, this.companion)));
      },
      // TODO unread message
      trailing: companion.documentID == "+77771234455" ? Icon(Icons.brightness_1, color: Colors.indigo,) : null,
    );
  }
}

class DialogList extends StatefulWidget {
  DialogList(this.userData);
  final UserData userData;
  @override
  State createState() => DialogListState();
}

class DialogListState extends State<DialogList> {
  Future<List<DialogTile>> downloadDialogs() async {
    // TODO cache downloaded?
    List<DialogTile> dialogTiles = [];
    var user = widget.userData.snapshot;
    for (var id in user['chats']) {
      var companion =
          await Firestore.instance.collection("user").document(id).get();
      dialogTiles.add(
          DialogTile(companion['name'], id, companion['photo'], companion));
    }
    return dialogTiles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("dialogs".tr()),
      ),
      body: FutureBuilder(
        future: downloadDialogs(),
        builder:
            (BuildContext context, AsyncSnapshot<List<DialogTile>> snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) => snapshot.data[index],
            );
          } else if (snapshot.hasError) {
            return Text("Error while dialog downloading");
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class Message extends StatelessWidget {
  final String text;
  final bool pos;
  Message(this.text, this.pos);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(5.0),
      ),
      margin: pos
          ? EdgeInsets.fromLTRB(50.0, 8.0, 8.0, 8.0)
          : EdgeInsets.fromLTRB(8.0, 8.0, 50.0, 8.0),
      child: Text(
        this.text,
        style: TextStyle(
          color: Colors.white,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}

class CustomDialog extends StatefulWidget {
  final String mylogin;
  final String friendlogin;
  final DocumentSnapshot companion;
  CustomDialog(this.mylogin, this.friendlogin, this.companion);
  @override
  State createState() => CustomDialogState();
}

class CustomDialogState extends State<CustomDialog> {
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
