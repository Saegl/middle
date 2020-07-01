import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

import 'profile/profile.dart';
import 'userdata.dart';

class FriendList extends StatelessWidget {
  FriendList(this.userData);

  // TODO delete userData
  final UserData userData;

  @override
  Widget build(BuildContext context) {
    var dbRef = Firestore.instance.collection("user").snapshots();
    return Scaffold(
      appBar: AppBar(
        title: Text("users".tr()),
      ),
      body: StreamBuilder(
        stream: dbRef,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return LinearProgressIndicator();
          return ListView.builder(
            itemCount: snapshot.data.documents.length,
            itemBuilder: (context, index) {
              return UserTile(
                snapshot.data.documents[index]['name'] +
                    " " +
                    snapshot.data.documents[index]['surname'],
                snapshot.data.documents[index],
                this.userData,
              );
            },
          );
        },
      ),
    );
  }
}

class UserTile extends StatelessWidget {
  UserTile(this.name, this.data, this.userData);

  // TODO delete data and userData
  final String name;
  final DocumentSnapshot data;
  final UserData userData;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(
        left: 16.0,
        top: 8.0,
        right: 16.0,
        bottom: 8.0,
      ),
      leading: Container(
        height: 55,
        width: 55,
        child: CircleAvatar(
          radius: 50,
          backgroundImage: CachedNetworkImageProvider(data['photo']),
        ),
      ),
      title: Text(this.name),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Profile(-1, data),
          ),
        );
      },
    );
  }
}
