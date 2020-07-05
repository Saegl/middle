import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:middle/userdata.dart';

import 'dialogscreen.dart';

class DialogList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserData>();
    return Scaffold(
      appBar: AppBar(
        title: Text("dialogs".tr()),
      ),
      body: StreamBuilder(
        stream: Firestore.instance
            .collection("user")
            .document(userData.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          final List snap = snapshot.data['chats'];
          return ListView.builder(
            itemCount: snap.length,
            itemBuilder: (context, index) {
              final friendId = snap[index];
              return StreamBuilder(
                stream: Firestore.instance
                    .collection("user")
                    .document(friendId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return LinearProgressIndicator();
                  final friend = snapshot.data;

                  return DialogTile(
                    friendId: friend.documentID,
                    friendFullName: friend['name'] + " " + friend['surname'],
                    friendPhoto: friend['photo'],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class DialogTile extends StatelessWidget {
  DialogTile({
    this.friendId,
    this.friendFullName,
    this.friendPhoto,
  });

  final String friendId;
  final String friendFullName;
  final String friendPhoto;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(
        left: 16.0,
        top: 4.0,
        right: 16.0,
        bottom: 4.0,
      ),
      leading: Container(
        height: 55,
        width: 55,
        child: CircleAvatar(
          radius: 55,
          backgroundImage: CachedNetworkImageProvider(friendPhoto),
        ),
      ),
      title: Text(friendFullName),
      // TODO status
      subtitle: Text("online"),
      onTap: () async {
        // TODO slide page route
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DialogScreen(
              friendId: friendId,
              friendPhoto: friendPhoto,
              friendFullName: friendFullName,
            ),
          ),
        );
      },
      // TODO unread message
      trailing: friendId == "+77771234455"
          ? Icon(
              Icons.brightness_1,
              color: Colors.indigo,
            )
          : null,
    );
  }
}
