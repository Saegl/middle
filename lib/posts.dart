import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:middle/appdrawer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'intro/intro.dart';
import 'profile/profile.dart';
import 'userdata.dart';
import 'postcreator.dart';
import 'postview.dart';

const blankProfilePicture = AssetImage("images/blank-profile-picture.png");

class UserLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserData>();
    if (!userData.loaded) return Scaffold();
    if (userData.auth) {
      // If user is authenticated show posts
      return Posts();
    } else {
      // Else show intro and login page
      return IntroScreen(userData.prefs);
    }
  }
}

class Posts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var dbRef = Firestore.instance
        .collection("lenta")
        // .where("author", whereIn: [
        //   "+77771780001",
        //   "+77771234455",
        // ])
        .snapshots();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("news".tr()),
      ),
      drawer: AppDrawer(),
      body: StreamBuilder(
        stream: dbRef,
        builder: (BuildContext context, snapshot) {
          if (!snapshot.hasData) return LinearProgressIndicator();
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: snapshot.data.documents.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot postSnapshot =
                  snapshot.data.documents[index];
              return Post(
                index,
                postSnapshot,
                clickable: true,
                key: ValueKey(postSnapshot.documentID),
              );
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

class Post extends StatelessWidget {
  Post(
    this.index,
    this.postSnapshot, {
    @required this.clickable,
    Key key,
  })  : this.photo = postSnapshot['photo'],
        this.likes = postSnapshot['likes'],
        this.author = postSnapshot['author'],
        this.text = postSnapshot['text'],
        super(key: key);

  final int index;
  final DocumentSnapshot postSnapshot;
  // AuthorTile data
  final String author;
  final bool clickable;

  final String photo;
  final String text;
  final int likes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AuthorTile(index, author, clickable),
        Card(
          child: InkWell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  CachedNetworkImage(
                    imageUrl: photo,
                    height: 400.0,
                    fit: BoxFit.cover,
                  ),
                  PostDescription(postSnapshot),
                ],
              ),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PostView(postSnapshot)));
            },
          ),
        )
      ],
    );
  }
}

class AuthorTile extends StatelessWidget {
  AuthorTile(this.index, this.author, this.clickable);

  final int index;
  final String author;
  final bool clickable;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // TODO user caching
      future: Firestore.instance.collection("user").document(author).get(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasData) {
          final author = snapshot.data;
          return ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: Container(
              height: 55,
              width: 55,
              child: clickable
                  ? Hero(
                      tag: index,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: CachedNetworkImageProvider(
                          author['photo'],
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundImage: CachedNetworkImageProvider(
                        author['photo'],
                      ),
                    ),
            ),
            title: Text(author['name']),
            onTap: () {
              if (clickable)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Profile(index, author),
                  ),
                );
            },
          );
        } else if (snapshot.hasError) {
          return Text("Error while author downloading");
        } else {
          return ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: Container(
              height: 55,
              width: 55,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: blankProfilePicture,
              ),
            ),
            title: Text("..."),
          );
        }
      },
    );
  }
}
