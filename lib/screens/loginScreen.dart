// ignore_for_file: file_names

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:uber_rider_app/screens/registrationScreen.dart';
import 'package:uber_rider_app/widgets/progressDialog.dart';

import '../main.dart';
import 'mainscreen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/loginScreen';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  TextEditingController emailTextEditingController = TextEditingController();

  TextEditingController passwordTextEditingController = TextEditingController();

  FocusNode emailFocusNode = FocusNode();

  FocusNode passwordFocusNode = FocusNode();

  bool obscureText = true;

  void loginAndAuthennticateUser(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(message: 'Authenticating, Please  wait...');
        });

    final User firebaseUser = (await _firebaseAuth
            .signInWithEmailAndPassword(
                email: emailTextEditingController.text.trim(),
                password: passwordTextEditingController.text.trim())
            .catchError(
      (errorMessage) {
        Navigator.pop(context);
        displayToastMessage(
          'Error: ' + errorMessage.toString(),
        );
      },
    ))
        .user;

    if (firebaseUser != null) {
      userRef
          .child(firebaseUser.uid)
          //.once()=>Listens for a single value event and then stops listening.
          .once() //to check if the user data exist in the datbase or not for that specific user
          .then((DataSnapshot snap) {
        if (snap.value != null) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(MainScreen.routeName, (route) => false);
          displayToastMessage('You are logged in');
        } else {
          Navigator.pop(context);
          _firebaseAuth.signOut();
          displayToastMessage(
              'No record exists for this user. Please create a new account');
        }
      });
    } else {
      Navigator.pop(context);
      displayToastMessage('Error occured');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(
              height: 50.0,
            ),
            const Image(
              image: AssetImage('assets/images/logo.png'),
              width: 150,
              height: 150,
              alignment: Alignment.center,
            ),
            const SizedBox(
              height: 1.0,
            ),
            const SizedBox(
              height: 1.0,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(
                    height: 1.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: emailTextEditingController,
                      onTap: () {
                        setState(() {});
                      },
                      focusNode: emailFocusNode,
                      style: const TextStyle(color: Colors.black),
                      cursorColor: Colors.black,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.email,
                          color: emailFocusNode.hasFocus
                              ? Theme.of(context).primaryColor
                              : Colors.grey[700],
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10.0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10.0),
                          ),
                        ),
                        labelText: 'Email',
                        labelStyle: TextStyle(
                          color: emailFocusNode.hasFocus
                              ? Theme.of(context).primaryColor
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  //Password TextField
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: passwordTextEditingController,
                      obscureText: obscureText,
                      onTap: () {
                        setState(() {});
                      },
                      focusNode: passwordFocusNode,
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                      cursorColor: Colors.black,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.lock,
                          color: passwordFocusNode.hasFocus
                              ? Theme.of(context).primaryColor
                              : Colors.grey[700],
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.remove_red_eye_outlined),
                          onPressed: () {
                            setState(() {
                              obscureText = !obscureText;
                            });
                          },
                          color: passwordFocusNode.hasFocus
                              ? Theme.of(context).primaryColor
                              : Colors.grey[700],
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10.0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10.0),
                          ),
                        ),
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: passwordFocusNode.hasFocus
                              ? Theme.of(context).primaryColor
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 50.0,
                  ),
                  RaisedButton(
                    textColor: Colors.black,
                    color: Colors.yellow[700],
                    onPressed: () {
                      if (!emailTextEditingController.text.contains('@')) {
                        displayToastMessage('Email address is not Valid.');
                      } else if (passwordTextEditingController.text.length <
                          6) {
                        displayToastMessage(
                            'Password must be atleast 6 Characters.');
                      } else {
                        loginAndAuthennticateUser(context);
                      }
                    },
                    child: Container(
                      height: 50.0,
                      child: const Center(
                        child: Text(
                          'Login',
                          style: TextStyle(
                              fontSize: 18.0, fontFamily: 'Brand-semibold'),
                        ),
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0)),
                  ),
                ],
              ),
            ),
            Expanded(child: Container()),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account? ',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.grey[600]),
                  ),
                  FlatButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pushReplacementNamed(RegistrationScreen.routeName);
                    },
                    child: Text(
                      'Sign up',
                      style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Theme.of(context).primaryColor),
                    ),
                    splashColor: Colors.white,
                    highlightColor: Colors.white,
                    disabledColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
