import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'posts.dart';
import 'comment.dart';
import 'userdata.dart';

final avatar =
    "https://firebasestorage.googleapis.com/v0/b/middle-5983a.appspot.com/o/7cb24580-b2ee-11ea-c1aa-5d0044f255a9?alt=media&token=a545b743-4982-4c94-8d7c-2519af38b419";
final image =
    "https://firebasestorage.googleapis.com/v0/b/middle-5983a.appspot.com/o/63ee7040-b2ef-11ea-d024-b1b4654b7205?alt=media&token=54b62253-81bd-4a46-9030-a9f709f5b875";

class PostView extends StatelessWidget {
  PostView(this.postSnapshot);

  final DocumentSnapshot postSnapshot;

  @override
  Widget build(BuildContext context) {
    final userId = context.select((UserData u) => u.id);
    return Scaffold(
      appBar: AppBar(
        title: Text("Post Details"),
      ),
      body: ListView(
        children: [
          AuthorTile(0, postSnapshot['author'], false),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                CachedNetworkImage(
                  imageUrl: postSnapshot['photo'],
                  height: 400.0,
                  fit: BoxFit.cover,
                ),
                SizedBox(height: 8.0),
                PostDescription(postSnapshot),
              ],
            ),
          ),
          Divider(),
          CommentsSection(postSnapshot.documentID),
        ],
      ),
    );
  }
}

class Like extends StatelessWidget {
  Like(this.target);
  final String target;
  @override
  Widget build(BuildContext context) {
    final userId = context.select((UserData u) => u.id);
    return StreamBuilder(
      stream: Firestore.instance
          .collection("likes")
          .document(target + userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final DocumentSnapshot like = snapshot.data;
          if (!like.exists) {
            return IconButton(
              icon: Icon(
                Icons.favorite_border,
                color: Colors.grey,
              ),
              onPressed: () async {
                await Firestore.instance
                    .collection("likes")
                    .document(target + userId)
                    .setData({
                  "post": target,
                  "author": userId,
                });
              },
            );
          } else {
            return IconButton(
              icon: Icon(
                Icons.favorite,
                color: Colors.red,
              ),
              onPressed: () async {
                await like.reference.delete();
              },
            );
          }
        } else {
          return IconButton(
            icon: Icon(
              Icons.favorite,
              color: Colors.grey,
            ),
            onPressed: () {},
          );
        }
      },
    );
  }
}

class PostDescription extends StatelessWidget {
  PostDescription(this.postSnapshot);

  final DocumentSnapshot postSnapshot;

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Like(postSnapshot.documentID),
      SizedBox(
        width: 8.0,
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StreamBuilder(
            stream: Firestore.instance
                .collection('likes')
                .where('post', isEqualTo: postSnapshot.documentID)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Text("inf likes");

              final QuerySnapshot q = snapshot.data;

              return Text("${q.documents.length} likes");
            },
          ),
          Text(postSnapshot['text'], style: TextStyle(fontSize: 16.0)),
        ],
      ),
    ]);
  }
}

class CommentsSection extends StatelessWidget {
  CommentsSection(this.target);

  final String target;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          // TODO translate
          title: Text("Comments: ", style: TextStyle(fontSize: 16)),
          trailing: IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => WriteComment(target)));
            },
          ),
        ),
        StreamBuilder(
          stream: Firestore.instance
              .collection('comments')
              .where('target', isEqualTo: target)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasData) {
              final data = snapshot.data.documents;
              return ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: data.length,
                itemBuilder: (context, index) => Comment(data[index]['text']),
              );
            } else {
              return LinearProgressIndicator();
            }
          },
        ),
      ],
    );
  }
}

class Comment extends StatelessWidget {
  Comment(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(16.0),
      leading: Container(
        width: 55,
        height: 55,
        child: CircleAvatar(
          radius: 50,
          backgroundImage: CachedNetworkImageProvider(avatar),
        ),
      ),
      // trailing: IconButton(
      //   icon: Icon(Icons.create),
      //   onPressed: () {},
      // ),
      title: Text(text),
      subtitle: Text("one hour ago, 3 responses"),
      onTap: () {},
    );
  }
}
