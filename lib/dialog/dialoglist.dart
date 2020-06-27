import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:middle/userdata.dart';

import 'dialogscreen.dart';

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
      contentPadding: EdgeInsets.only(
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

class DialogList extends StatelessWidget {
  Future<List<DialogTile>> downloadDialogs(
      BuildContext context, UserData userData) async {
    // TODO cache downloaded?
    List<DialogTile> dialogTiles = [];
    final user = userData.snapshot;
    for (var id in user['chats']) {
      var friend =
          await Firestore.instance.collection("user").document(id).get();
      dialogTiles.add(
        DialogTile(
          friendId: friend.documentID,
          friendFullName: friend['name'] + friend['surname'],
          friendPhoto: friend['photo'],
        ),
      );
    }
    return dialogTiles;
  }

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserData>();
    return Scaffold(
      appBar: AppBar(
        title: Text("dialogs".tr()),
      ),
      body: FutureBuilder(
        future: downloadDialogs(context, userData),
        builder:
            (BuildContext context, AsyncSnapshot<List<DialogTile>> snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) => snapshot.data[index],
            );
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return Text("Error while dialog downloading");
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
