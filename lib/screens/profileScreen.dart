// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:uber_rider_app/configMaps.dart';
import 'package:uber_rider_app/screens/mainscreen.dart';

class ProfileScreen extends StatelessWidget {
  static String routeName = '/ProfileTabPage';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              userCurrentInfo.name,
              style: const TextStyle(
                fontSize: 65.0,
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Signatra',
              ),
            ),
            SizedBox(
              height: 20,
              width: 200,
              child: Divider(
                color: Colors.yellow[700],
              ),
            ),
            const SizedBox(
              height: 40.0,
            ),
            InfoCard(
              text: userCurrentInfo.phone,
              icon: Icons.phone,
            ),
            InfoCard(
              text: userCurrentInfo.email,
              icon: Icons.email,
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
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String text;
  final IconData icon;
  Function onPressed;

  InfoCard({
    this.text,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
        child: ListTile(
          leading: Icon(
            icon,
            color: Colors.black87,
          ),
          title: Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16.0,
              fontFamily: 'Brand Bold',
            ),
          ),
        ),
      ),
    );
  }
}
