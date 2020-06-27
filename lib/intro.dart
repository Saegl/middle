import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:intro_slider/slide_object.dart';
import 'package:middle/userdata.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'register.dart';

class TimeOutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final styleTitle = TextStyle(
      fontSize: 26.0,
    );
    final styleSubtitle = TextStyle(
      fontSize: 20.0,
    );
    return Scaffold(
      body: Container(
        margin: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Center(child: Text("Время истекло", style: styleTitle)),
            Text(
              "\nВремя ввода кода истекло. Если сообщение так и не пришло попробуйте использовать другой номер телефона или повторите попытку позже\n",
              style: styleSubtitle,
              textAlign: TextAlign.center,
            ),
            RaisedButton(
              child: Text("Попробовать снова"),
              onPressed: () {
                Navigator.pop(context);
              },
              color: Colors.yellow,
            )
          ],
        ),
      ),
    );
  }
}

String blankPictureUrl =
    "https://firebasestorage.googleapis.com/v0/b/middle-5983a.appspot.com/o/blank-profile-picture.png?alt=media&token=96d03c62-f202-4012-bbd8-123bcaf1eaea";

class Registration extends StatefulWidget {
  final String userId;
  Registration(this.userId);
  @override
  State createState() => RegistrationState();
}

class RegistrationState extends State<Registration> {
  StorageUploadTask uploadTask;
  Image image;
  final name = TextEditingController();
  final surname = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final styleTitle = TextStyle(
      fontSize: 26.0,
    );
    final styleSubtitle = TextStyle(
      fontSize: 20.0,
    );
    return Scaffold(
      body: ListView(
        children: <Widget>[
          Center(child: Text("\nРегистрация", style: styleTitle)),
          GestureDetector(
            child: Container(
              padding: EdgeInsets.all(58.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: image == null
                  ? Image.asset("images/blank-profile-picture.png")
                  : image,
            ),
            onTap: () async {
              final String uuid = Uuid().v1();
              var file =
                  await ImagePicker.pickImage(source: ImageSource.gallery);
              final StorageReference ref =
                  FirebaseStorage.instance.ref().child('$uuid');
              uploadTask = ref.putFile(file);
              setState(() {
                image = Image.file(file);
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: name,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Введите имя",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: surname,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Введите фамилию",
              ),
            ),
          ),
          RaisedButton(
            child: Text(""),
            onPressed: () async {
              String urlString;
              if (uploadTask != null) {
                var url =
                    await (await uploadTask.onComplete).ref.getDownloadURL();
                urlString = url.toString();
              }
              final userRef = Firestore.instance.collection("user");
              await userRef.document(widget.userId).setData({
                "photo": urlString != null ? urlString : blankPictureUrl,
                "name": name.text,
                "surname": surname.text,
                "chats": [widget.userId],
              });
              Navigator.pushReplacementNamed(context, "/");
            },
            color: Colors.yellow,
          )
        ],
      ),
    );
  }
}

onAuthenticationSuccessful(
    String userId, SharedPreferences prefs, BuildContext context) async {
  final userRef = Firestore.instance.collection("user");
  final user = await userRef.document(userId).get();
  await prefs.setString("userId", userId);
  if (user == null || !user.exists) {
    await userRef.document(userId).setData({
      "photo": blankPictureUrl,
      "name": '',
      "surname": '',
      "chats": [],
    });
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => Registration(userId)));
  } else {
    final userData = context.read<UserData>();
    await userData.load();
    Navigator.pushReplacementNamed(context, '/');
  }
}

class IntroScreen extends StatefulWidget {
  final SharedPreferences prefs;
  IntroScreen(this.prefs, {Key key}) : super(key: key);

  @override
  IntroScreenState createState() => new IntroScreenState();
}

class IntroScreenState extends State<IntroScreen> {
  List<Slide> slides = new List();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String phoneNo;
  String userId;

  Future<void> signIn() async {
    if (phoneNo == "") return;
    var firebaseAuth = FirebaseAuth.instance;
    // TODO move this functions to methods
    final PhoneCodeSent codeSent =
        (String verificationId, [int forceResendingToken]) async {
      // TODO create screen for code sent
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  SMScodeScreen(verificationId, userId, widget.prefs)));
      print("CALL codeSent");
      print("verificationId: $verificationId");
    };

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      // TODO create screen for timeout
      print("CALL codeAutoRetrievalTimeout");
      print("Time out");
    };

    final PhoneVerificationFailed verificationFailed =
        (AuthException authException) {
      // TODO create screen for verification Failed
      print("verificationFailed");
      var status = '${authException.message}';

      print("Error message: " + status);
      if (authException.message.contains('not authorized'))
        status = 'Something has gone wrong, please try later';
      else if (authException.message.contains('Network'))
        status = 'Please check your internet connection and try again';
      else
        status = 'Something has gone wrong, please try later';
      print(status);
    };

    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential auth) {
      print("verificationCompleted");
      var status = 'Auto retrieving verification code';
      var _authCredential = auth;

      firebaseAuth
          .signInWithCredential(_authCredential)
          .then((AuthResult value) {
        if (value.user != null) {
          status = 'Authentication successful';
          print("USER != NULL");
          onAuthenticationSuccessful(userId, widget.prefs, context);
          auth.toString();
        } else {
          status = 'Invalid code/invalid authentication';
        }
      }).catchError((error) {
        print(error);
        status = 'Something has gone wrong, please try later';
      });
      print(status);
    };

    firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNo,
      timeout: Duration(seconds: 120),
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
    userId = phoneNo;
  }

  @override
  void initState() {
    super.initState();
    slides.add(
      new Slide(
        title: "phoneNumber".tr(),
        styleTitle: TextStyle(
            color: Colors.black,
            fontSize: 30.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'RobotoMono'),
        colorBegin: Colors.white,
        colorEnd: Colors.white,
        directionColorBegin: Alignment.topCenter,
        directionColorEnd: Alignment.bottomCenter,
        maxLineTextDescription: 3,
        centerWidget: Container(
          margin: EdgeInsets.all(40.0),
          child: Column(
            children: <Widget>[
              Form(
                key: formKey,
                child: InternationalPhoneNumberInput(
                  hintText: "phoneNumber".tr(),
                  initialValue: PhoneNumber(isoCode: "KZ"),
                  formatInput: false,
                  autoValidate: false,
                  selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                  onInputChanged: (PhoneNumber phoneNumber) {
                    phoneNo = phoneNumber.phoneNumber;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 50.0),
                child: Text("phoneDescr".tr()),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget renderNextBtn() {
    return Icon(
      Icons.navigate_next,
      color: Colors.white,
      size: 35.0,
    );
  }

  Widget renderDoneBtn() {
    return Icon(
      Icons.done,
      color: Colors.white,
    );
  }

  Widget renderSkipBtn() {
    return Icon(
      Icons.skip_next,
      color: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      slides: this.slides,

      // Skip button
      renderSkipBtn: this.renderSkipBtn(),
      colorSkipBtn: Color(0x33000000),
      highlightColorSkipBtn: Color(0xff000000),

      // Next button
      renderNextBtn: this.renderNextBtn(),

      // Done button
      renderDoneBtn: this.renderDoneBtn(),
      onDonePress: this.signIn,
      colorDoneBtn: Color(0x33000000),
      highlightColorDoneBtn: Color(0xff000000),

      // Dot indicator
      colorDot: Colors.black87,
      colorActiveDot: Colors.yellow,
      sizeDot: 13.0,

      // Show or hide status bar
      shouldHideStatusBar: false,
      backgroundColorAllSlides: Colors.grey,
    );
  }
}
