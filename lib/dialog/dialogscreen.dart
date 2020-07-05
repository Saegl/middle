import 'package:flutter/material.dart';
import 'package:middle/userdata.dart';

import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubble/bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class DialogScreen extends StatelessWidget {
  DialogScreen({
    @required this.friendId,
    @required this.friendPhoto,
    @required this.friendFullName,
  });

  final String friendId;
  final String friendPhoto;
  final String friendFullName;

  @override
  Widget build(BuildContext context) {
    final userId = context.select((UserData u) => u.id);
    final ref =
        userId.compareTo(friendId) < 0 ? userId + friendId : friendId + userId;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0.0,
        title: AvatarRow(
          photo: this.friendPhoto,
          fullName: this.friendFullName,
        ),
      ),
      body: Column(
        children: <Widget>[
          //PhotoUploadingTask(),
          MessageList(ref),
          BottomActionRow(ref, friendId),
        ],
      ),
    );
  }
}

class AvatarRow extends StatelessWidget {
  AvatarRow({
    @required this.photo,
    @required this.fullName,
  });
  final String photo;
  final String fullName;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(photo),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(fullName),
        ),
      ],
    );
  }
}

class PhotoUploadingTask extends StatelessWidget {
  // TODO make this work
  PhotoUploadingTask(this.task);
  final StorageUploadTask task;
  @override
  Widget build(BuildContext context) {
    return Container(
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
      ),
    );
  }
}

class MessageList extends StatelessWidget {
  MessageList(this.ref);

  final String ref;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final dbRef = Firestore.instance
        .collection("messages")
        .where("ref", isEqualTo: ref)
        .orderBy("created", descending: true)
        .snapshots();
    final userId = context.select((UserData u) => u.id);
    return Expanded(
      child: Container(
        child: StreamBuilder(
          stream: dbRef,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Align(
                child: CircularProgressIndicator(),
              );
            }
            return ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: snapshot.data.documents.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot message = snapshot.data.documents[index];
                final me = userId == message['author'];
                if (!me && !message['viewed']) {
                  message.reference.updateData({
                    "viewed": true,
                  });
                }
                return Message(
                  date: message["created"].toDate(),
                  me: me,
                  text: message['text'],
                  viewed: message['viewed'],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class Message extends StatelessWidget {
  Message({
    @required this.date,
    @required this.me,
    @required this.text,
    @required this.viewed,
  });

  final DateTime date;
  final bool me;
  final String text;
  final bool viewed;

  @override
  Widget build(BuildContext context) {
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
    return Bubble(
      style: me ? styleMe : styleSomebody,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(text),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "${date.hour}:${date.minute} ",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12.0,
                ),
              ),
              if (!me && viewed)
              Icon(
                Icons.done_all,
                size: 12.0,
                color: Colors.blue,
              ),
              if (!me && !viewed)
              Icon(
                Icons.done,
                size: 12.0,
                color: Colors.black,
              )
            ],
          ),
        ],
      ),
    );
  }
}

class BottomActionRow extends StatelessWidget {
  BottomActionRow(this.ref, this.friendId);

  final String ref;
  final String friendId;
  final textEdit = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userId = context.select((UserData u) => u.id);
    return Row(
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.attach_file),
          onPressed: () async {
            final String uuid = Uuid().v1();
            var file = await ImagePicker.pickImage(source: ImageSource.gallery);
            final StorageReference ref =
                FirebaseStorage.instance.ref().child('$uuid');
            final StorageUploadTask uploadTask = ref.putFile(file);
            // setState(() {
            //   task = uploadTask;
            // });
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
            // TODO notification for all users
            if (friendId == '+77025387955') {
              Firestore.instance.collection("messages").add({
                "text": textEdit.text,
                "author": userId,
                "viewed": false,
                "created": Timestamp.now(),
                "ref": ref,
                "receiver":
                    "eEYv_vIizZM:APA91bEbhcUcI-UM4QJLx02I5alwu01nDvXVNDudJnNOVKCva6TCw6yUTpZuEXzHTh53Ag6O-fWZc5CQ4SkyDdIHSEmgqam9tascYsoqw-PokxNXaQMN8nWNzQLI64sxsbmrtt5Hyoj5",
              });
            } else if (friendId == "+77771780001")
              Firestore.instance.collection("messages").add({
                "text": textEdit.text,
                "author": userId,
                "viewed": false,
                "created": Timestamp.now(),
                "ref": ref,
                "receiver":
                    "dFS9Upk_-fg:APA91bFEbWw5vG1KboywkEp2mWQ9vnuNeOkbNtcTlNSq0YOKndhU0P3bZNCf_AoJsE5PiW5WTJiWUOFqcPndk29Sc596MzdjfR0lWmXnd_FOObIfQNptjaFIwfJWwSZMPd7b1qQKSlzU",
              });
            else {
              Firestore.instance.collection("messages").add({
                "text": textEdit.text,
                "author": userId,
                "viewed": false,
                "created": Timestamp.now(),
                "ref": ref,
              });
            }
            textEdit.clear();
          },
        )
      ],
    );
  }
}
