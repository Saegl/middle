import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../intro/intro.dart';
import '../userdata.dart';

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
    name.text = widget.userData.snapshot['name'];
    surname.text = widget.userData.snapshot['surname'];
    image = CachedNetworkImage(
      imageUrl: widget.userData.snapshot['photo'],
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
          Padding(
            // "AppBar"
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
                    .document(widget.userData.snapshot.documentID)
                    .updateData({
                  "photo": urlString != null ? urlString : blankPictureUrl,
                  "name": name.text,
                  "surname": surname.text,
                });
                //widget.userData.reloadSnap();
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