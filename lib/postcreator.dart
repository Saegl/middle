import 'package:flutter/material.dart';
import 'package:middle/userdata.dart';

import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';

class NewPost extends StatefulWidget {
  @override
  State createState() => NewPostState();
}

class NewPostState extends State<NewPost> {
  StorageUploadTask uploadTask;
  Image image;
  final text = TextEditingController();

  void _selectImage() async {
    final String uuid = Uuid().v1();
    var file = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }
    final StorageReference ref = FirebaseStorage.instance.ref().child('$uuid');
    uploadTask = ref.putFile(file);
    setState(() {
      image = Image.file(file);
    });
  }

  void _post() async {
    String userId = context.read<UserData>().id;
    String urlString;
    if (uploadTask != null) {
      var url = await (await uploadTask.onComplete).ref.getDownloadURL();
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
  }

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
            onTap: _selectImage,
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
              onPressed: _post,
              color: Colors.yellow,
            ),
          )
        ],
      ),
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
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
            color: Colors.grey[200], borderRadius: BorderRadius.circular(5.0)),
        child: Text("selectImage".tr()),
      ),
    );
  }
}
