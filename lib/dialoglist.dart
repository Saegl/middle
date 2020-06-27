import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:middle/userdata.dart';

import 'dialogscreen.dart';

class DialogTile extends StatelessWidget {
  DialogTile(
    this.name,
    this.companionId,
    this.photo,
    this.companion,
  );

  final String name;
  final String companionId;
  final String photo;
  final DocumentSnapshot companion;

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserData>();
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
          backgroundImage: CachedNetworkImageProvider(photo),
        ),
      ),
      title: Text(this.name + " " + this.companion['surname']),
      // TODO status
      subtitle: Text("online"),
      onTap: () async {
        String userId = userData.id;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DialogScreen(userId, this.companionId, this.companion),
          ),
        );
      },
      // TODO unread message
      trailing: companion.documentID == "+77771234455"
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
      var companion =
          await Firestore.instance.collection("user").document(id).get();
      dialogTiles.add(
          DialogTile(companion['name'], id, companion['photo'], companion));
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
