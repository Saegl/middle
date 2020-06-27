import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../posts.dart';
import '../dialog/dialogscreen.dart';
import '../userdata.dart';
import 'changeprofile.dart';

class ProfileActionsRow extends StatelessWidget {
  ProfileActionsRow({
    @required this.me,
    @required this.ownerId,
    @required this.ownerFullName,
    @required this.ownerPhoto,
  });

  final bool me;
  final String ownerId;
  final String ownerFullName;
  final String ownerPhoto;

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserData>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 4.0, 8.0),
            child: RaisedButton(
              color: Colors.black,
              child: Text(
                me ? "changeProfile".tr() : "add".tr(),
                style: TextStyle(color: Colors.yellow),
              ),
              onPressed: () async {
                if (me) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ChangeProfile(userData)));
                } else {
                  Firestore.instance
                      .collection("user")
                      .document(userData.id)
                      .updateData({
                    "chats": FieldValue.arrayUnion([ownerId]),
                  });
                  await userData.load();
                }
              },
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4.0, 8.0, 8.0, 8.0),
            child: RaisedButton(
              color: Colors.yellow,
              child: Text("write".tr()),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String userId = prefs.getString("userId");
                Firestore.instance
                    .collection("user")
                    .document(userId)
                    .updateData({
                  "chats": FieldValue.arrayUnion([ownerId]),
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DialogScreen(
                      friendId: ownerId,
                      friendFullName: ownerFullName,
                      friendPhoto: ownerPhoto,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class Profile extends StatefulWidget {
  Profile(this.data);

  final DocumentSnapshot data;

  @override
  State createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    // TODO remove userData
    final userData = context.watch<UserData>();
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            iconTheme: IconThemeData(color: Colors.white),
            backgroundColor: Colors.orange[400],
            pinned: true,
            floating: false,
            snap: false,
            expandedHeight: 200.0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.data['name'],
                style: TextStyle(color: Colors.white),
              ),
              background: CachedNetworkImage(
                  imageUrl: widget.data['photo'], fit: BoxFit.cover),
            ),
          ),
          StreamBuilder(
            stream: Firestore.instance
                .collection("lenta")
                .where("author", isEqualTo: widget.data.documentID)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return SliverList(
                  delegate: SliverChildListDelegate([
                    ProfileActionsRow(
                      me: userData.snapshot.documentID ==
                          widget.data.documentID,
                      ownerId: widget.data['photo'],
                      ownerFullName:
                          widget.data['name'] + widget.data['surname'],
                      ownerPhoto: widget.data['photo'],
                    )
                  ]),
                );
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return ProfileActionsRow(
                        me: userData.snapshot.documentID ==
                            widget.data.documentID,
                        ownerId: widget.data['photo'],
                        ownerFullName:
                            widget.data['name'] + widget.data['surname'],
                        ownerPhoto: widget.data['photo'],
                      );
                    }
                    final DocumentSnapshot postSnapshot =
                        snapshot.data.documents[index - 1];
                    return Post(postSnapshot,
                        clickable: false,
                        key: ValueKey(postSnapshot.documentID));
                  },
                  childCount: 1 + snapshot.data.documents.length,
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
