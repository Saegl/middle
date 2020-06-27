import 'package:flutter/material.dart';

class TimeOutScreen extends StatelessWidget {
  // TODO user this screen for registration
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
