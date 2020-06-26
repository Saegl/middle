import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'intro.dart';
import 'profile.dart';
import 'friends.dart';
import 'dialog.dart';
import 'settings.dart';
import 'userdata.dart';


class Burger extends StatelessWidget {
  final UserData userData;
  Burger(this.userData);
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.all(0.0),
        children: <Widget>[
          DrawerHeader(
            child: Container(),
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: CachedNetworkImageProvider(
                    userData.snapshot['photo'],
                  ),
                  fit: BoxFit.cover),
            ),
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('profile'.tr()),
            onTap: () async {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          Profile(userData.snapshot, this.userData)));
            },
          ),
          ListTile(
            leading: Icon(Icons.group),
            title: Text('users'.tr()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FriendList(userData)));
            },
          ),
          ListTile(
            leading: Icon(Icons.bubble_chart),
            title: Text('dialogs'.tr()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DialogList(this.userData)));
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('settings'.tr()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Settings(this.userData)));
            },
          ),
        ],
      ),
    );
  }
}

class Post extends StatefulWidget {
  Post(this.photo, this.likes, this.author, this.text, this.clickable,
      this.userData,
      {Key key})
      : super(key: key);
  final String photo;
  final int likes;
  final String author;
  final String text;
  final bool clickable;
  final UserData userData;
  @override
  State createState() => PostState();
}

class PostState extends State<Post> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FutureBuilder(
          future: Firestore.instance
              .collection("user")
              .document(widget.author)
              .get(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasData) {
              final author = snapshot.data;
              return Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 4.0),
                child: ListTile(
                  leading: Container(
                    height: 55,
                    width: 55,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          CachedNetworkImageProvider(author['photo']),
                    ),
                  ),
                  title: Text(author['name']),
                  onTap: () {
                    if (widget.clickable)
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  Profile(author, widget.userData)));
                  },
                ),
              );
            } else if (snapshot.hasError) {
              return Text("Error while author downloading");
            } else {
              return Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 4.0),
                child: ListTile(
                  leading: Container(
                    height: 55,
                    width: 55,
                    child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            AssetImage("images/blank-profile-picture.png")),
                  ),
                  title: Text("..."),
                ),
              );
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  CachedNetworkImage(
                    imageUrl: widget.photo,
                    height: 400.0,
                    fit: BoxFit.cover,
                  ),
                  ListTile(
                    title: Text(widget.text),
                    leading: Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}

class ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.0,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("images/placeholder.png"),
          fit: BoxFit.cover,
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(5.0)
        ),
        child: Text("selectImage".tr()),
      ),
    );
  }
}

class NewPost extends StatefulWidget {
  @override
  State createState() => NewPostState();
}

class NewPostState extends State<NewPost> {
  StorageUploadTask uploadTask;
  Image image;
  final text = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("newPost".tr()),
      ),
      body: ListView(
        children: <Widget>[
          GestureDetector(
            child: Container(
              child: image == null ? ImagePlaceholder() : image,
            ),
            onTap: () async {
              final String uuid = Uuid().v1();
              var file =
                  await ImagePicker.pickImage(source: ImageSource.gallery);
              if (file == null) {
                return;
              }
              final StorageReference ref =
                  FirebaseStorage.instance.ref().child('$uuid');
              uploadTask = ref.putFile(file);
              setState(() {
                image = Image.file(file);
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              controller: text,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "postText".tr(),
              ),
            ),
          ),
          Align(
            child: RaisedButton(
              child: Text("post".tr()),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String userId = prefs.getString("userId");
                String urlString;
                if (uploadTask != null) {
                  var url =
                      await (await uploadTask.onComplete).ref.getDownloadURL();
                  urlString = url.toString();
                } else {
                  return;
                }

                final lentaRef = Firestore.instance.collection("lenta");
                lentaRef.add({
                  "author": userId,
                  "likes": 0,
                  "photo": urlString,
                  "text": text.text,
                });
                Navigator.pop(context);
              },
              color: Colors.yellow,
            ),
          )
        ],
      ),
    );
  }
}

class LentaBody extends StatelessWidget {
  final UserData userData;
  LentaBody(this.userData);
  @override
  Widget build(BuildContext context) {
    var dbRef = Firestore.instance.collection("lenta").snapshots();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("news".tr()),
      ),
      drawer: Burger(userData),
      body: StreamBuilder(
        stream: dbRef,
        builder: (BuildContext context, snapshot) {
          if (!snapshot.hasData) return LinearProgressIndicator();
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: snapshot.data.documents.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot post = snapshot.data.documents[index];
              return Post(post['photo'], post['likes'], post['author'],
                  post['text'], true, userData,
                  key: ValueKey(post.documentID));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => NewPost()));
        },
      ),
    );
  }
}

class Lenta extends StatelessWidget {
  Lenta(this.userData);

  UserData userData;

  @override
  Widget build(BuildContext context) {
    if (userData.authLoaded) {
      if (userData.auth) {
        return LentaBody(userData);
      } else {
        return IntroScreen(userData.prefs);
      }
    } else {
      return Scaffold();
    }
  }
}
