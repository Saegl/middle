import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:middle/profile/profile.dart';
import 'package:middle/userdata.dart';

class FriendTile extends StatelessWidget {
  FriendTile(this.name, this.data, this.userData);

  // TODO delete data and userData
  final String name;
  final DocumentSnapshot data;
  final UserData userData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 4.0),
      child: ListTile(
        leading: Container(
          height: 55,
          width: 55,
          child: CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(data['photo']),
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
      ),
    );
  }
}

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
              return FriendTile(
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

// Git test
