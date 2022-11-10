// ignore: file_names
// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:uber_rider_app/screens/mainscreen.dart';

class AboutScreen extends StatefulWidget {
  static const String routeName = "AboutScreen";

  @override
  _MyAboutScreenState createState() => _MyAboutScreenState();
}

class _MyAboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: ListView(
          children: <Widget>[
            Container(
              height: 220,
              child: Center(
                child: Image.asset('assets/images/uberx.png'),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 24, right: 24),
              child: Column(
                children: const <Widget>[
                  Text(
                    'Taxi',
                    style: TextStyle(fontSize: 90, fontFamily: 'Signatra'),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'This app has been developed by Medhat Ahmed, '
                    'This app offer cheap rides at cheap rates, ',
                    style: TextStyle(fontFamily: "Brand-semibold"),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            FlatButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, MainScreen.routeName, (route) => false);
                },
                child: Text('Go Back',
                    style: TextStyle(fontSize: 18, color: Colors.yellow[700])),
                shape: RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(10.0))),
          ],
        ));
  }
}
