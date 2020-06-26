import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:uuid/uuid.dart';

import 'lenta.dart';
import 'dialog.dart';
import 'userdata.dart';
import 'intro.dart';

class ChangeProfile extends StatefulWidget {
  final UserData userData;
  ChangeProfile(this.userData);
  @override
  State createState() => ChangeProfileState();
}

class ChangeProfileState extends State<ChangeProfile> {
  StorageUploadTask uploadTask;
  Widget image;
  final name = TextEditingController();
  final surname = TextEditingController();

  @override
  void initState() {
    super.initState();
    name.text = widget.userData.firestoreSnap['name'];
    surname.text = widget.userData.firestoreSnap['surname'];
    image = CachedNetworkImage(
      imageUrl: widget.userData.firestoreSnap['photo'],
      height: 200.0,
      width: 200.0,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final styleTitle = TextStyle(
      fontSize: 26.0,
    );
    return Scaffold(
      body: ListView(
        children: <Widget>[
          Padding( // "AppBar"
            padding: EdgeInsets.only(top: 16.0),
            child: Center(
              child: Text("changeProfile".tr(), style: styleTitle),
            ),
          ),
          GestureDetector(
            child: Container(
              padding: EdgeInsets.all(32.0),
              child: Align(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100.0),
                  child: image,
                ),
              ),
            ),
            onTap: () async {
              final String uuid = Uuid().v1();
              var file =
                  await ImagePicker.pickImage(source: ImageSource.gallery);
              if (file == null) return;

              final StorageReference ref =
                  FirebaseStorage.instance.ref().child('$uuid');
              uploadTask = ref.putFile(file);
              setState(() {
                image = Image.file(
                  file,
                  width: 200.0,
                  height: 200.0,
                  fit: BoxFit.cover,
                );
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: name,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "enterName".tr(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: surname,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "enterSurname".tr(),
              ),
            ),
          ),
          Align(
            child: RaisedButton(
              child: Text("changeBtn".tr()),
              onPressed: () async {
                String urlString;
                if (uploadTask != null) {
                  var url =
                      await (await uploadTask.onComplete).ref.getDownloadURL();
                  urlString = url.toString();
                }

                final userRef = Firestore.instance.collection("user");
                await userRef
                    .document(widget.userData.firestoreSnap.documentID)
                    .updateData({
                  "photo": urlString != null ? urlString : blank_picture_url,
                  "name": name.text,
                  "surname": surname.text,
                });
                widget.userData.reloadSnap();
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

class ProfileActionsRow extends StatelessWidget {
  ProfileActionsRow(this.data, this.userData);

  final DocumentSnapshot data;
  final UserData userData;

  @override
  Widget build(BuildContext context) {
    bool me = userData.firestoreSnap.documentID == data.documentID;
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
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  String userId = prefs.getString("userId");
                  Firestore.instance
                      .collection("user")
                      .document(userId)
                      .updateData({
                    "chats": FieldValue.arrayUnion([data.documentID]),
                  });
                  userData.reloadSnap();
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
                  "chats": FieldValue.arrayUnion([data.documentID]),
                });
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            CustomDialog(userId, data.documentID, data)));
              },
            ),
          ),
        ),
      ],
    );
  }
}

class Profile extends StatefulWidget {
  Profile(this.data, this.userData);

  final DocumentSnapshot data;
  final UserData userData;

  @override
  State createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
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
                  delegate: SliverChildListDelegate(
                      [ProfileActionsRow(widget.data, widget.userData)]),
                );
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return ProfileActionsRow(widget.data, widget.userData);
                    }
                    final DocumentSnapshot post =
                        snapshot.data.documents[index - 1];
                    return Post(post['photo'], post['likes'], post['author'],
                        post['text'], false, widget.userData,
                        key: ValueKey(post.documentID));
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
