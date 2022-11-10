// ignore_for_file: file_names

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uber_rider_app/main.dart';
import 'package:uber_rider_app/screens/loginScreen.dart';
import 'package:uber_rider_app/screens/mainscreen.dart';
import 'package:uber_rider_app/widgets/progressDialog.dart';

class RegistrationScreen extends StatefulWidget {
  static const routeName = '/registrationScreen';

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  TextEditingController nameTextEditingController = TextEditingController();

  TextEditingController emailTextEditingController = TextEditingController();

  TextEditingController passwordTextEditingController = TextEditingController();

  TextEditingController phoneTextEditingController = TextEditingController();

  TextEditingController confirmPasswordTextEditingController =
      TextEditingController();

  FocusNode emailFocusNode = FocusNode();

  FocusNode nameFocusNode = FocusNode();

  FocusNode passwordFocusNode = FocusNode();

  FocusNode confirmPasswordFocusNode = FocusNode();

  FocusNode phoneFocusNode = FocusNode();

  bool passwordObscureText = true;

  bool confirmPasswordObscureText = true;

  void _registerNewUser(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(message: 'Registering, Please  wait...');
        });
    final User firebaseUser = (await _firebaseAuth
            .createUserWithEmailAndPassword(
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
      //svae user info to database
      Map userDataMap = {
        "name": nameTextEditingController.text.trim(),
        "email": emailTextEditingController.text.trim(),
        "phone": phoneTextEditingController.text.trim(),
      };
      userRef.child(firebaseUser.uid).set(userDataMap);
      Navigator.of(context)
          .pushNamedAndRemoveUntil(MainScreen.routeName, (route) => false);
    } else {
      //error occured - display error msg
      Navigator.pop(context);
      displayToastMessage('New user account has not been created.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(
                height: 35.0,
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
              const Text(
                'Register as a Rider',
                style: TextStyle(fontSize: 24.0, fontFamily: 'Brand-semibold'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 20,
              ),

              //User Name
              Padding(
                padding: const EdgeInsets.all(14),
                child: TextField(
                  onTap: () {
                    setState(() {});
                  },
                  controller: nameTextEditingController,
                  focusNode: nameFocusNode,
                  style: const TextStyle(color: Colors.black),
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.person,
                      color: nameFocusNode.hasFocus
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
                    labelText: 'Name',
                    labelStyle: TextStyle(
                      color: nameFocusNode.hasFocus
                          ? Theme.of(context).primaryColor
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ),

              //Phone
              Padding(
                padding: const EdgeInsets.all(14),
                child: TextField(
                  keyboardType: TextInputType.phone,
                  onTap: () {
                    setState(() {});
                  },
                  controller: phoneTextEditingController,
                  focusNode: phoneFocusNode,
                  style: const TextStyle(color: Colors.black),
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.phone,
                      color: phoneFocusNode.hasFocus
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
                    labelText: 'Phone',
                    labelStyle: TextStyle(
                      color: phoneFocusNode.hasFocus
                          ? Theme.of(context).primaryColor
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ),

              //Email

              Padding(
                padding: const EdgeInsets.all(14),
                child: TextField(
                  onTap: () {
                    setState(() {});
                  },
                  controller: emailTextEditingController,
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

              //Password
              Padding(
                padding: const EdgeInsets.all(14),
                child: TextField(
                  obscureText: passwordObscureText,
                  onTap: () {
                    setState(() {});
                  },
                  controller: passwordTextEditingController,
                  focusNode: passwordFocusNode,
                  style: const TextStyle(color: Colors.black),
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
                          passwordObscureText = !passwordObscureText;
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

              //Confirm Password
              Padding(
                padding: const EdgeInsets.all(14),
                child: TextField(
                  obscureText: confirmPasswordObscureText,
                  onTap: () {
                    setState(() {});
                  },
                  controller: confirmPasswordTextEditingController,
                  focusNode: confirmPasswordFocusNode,
                  style: const TextStyle(color: Colors.black),
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.lock,
                      color: confirmPasswordFocusNode.hasFocus
                          ? Theme.of(context).primaryColor
                          : Colors.grey[700],
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.remove_red_eye_outlined),
                      onPressed: () {
                        setState(() {
                          confirmPasswordObscureText =
                              !confirmPasswordObscureText;
                        });
                      },
                      color: confirmPasswordFocusNode.hasFocus
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
                      color: confirmPasswordFocusNode.hasFocus
                          ? Theme.of(context).primaryColor
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 40,
              ),

              RaisedButton(
                textColor: Colors.black,
                color: Colors.yellow[700],
                onPressed: () {
                  if (nameTextEditingController.text.length < 3) {
                    displayToastMessage('name must be at leat 3 Characters.');
                    return;
                  }
                  if (!emailTextEditingController.text.contains('@')) {
                    displayToastMessage('Email address is not Valid.');
                    return;
                  }
                  if (phoneTextEditingController.text.isEmpty) {
                    displayToastMessage('Phone Number is mandatory.');
                    return;
                  }
                  if (passwordTextEditingController.text.length < 6) {
                    displayToastMessage(
                        'Password must be atleast 6 Characters.');
                    return;
                  }

                  if (passwordTextEditingController.text !=
                      confirmPasswordTextEditingController.text) {
                    displayToastMessage('Passwords do not match');
                    return;
                  }

                  _registerNewUser(context);
                },
                child: Container(
                  height: 50.0,
                  child: const Center(
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                          fontSize: 18.0, fontFamily: 'Brand-semibold'),
                    ),
                  ),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0)),
              ),

              const SizedBox(
                height: 40,
              ),

              Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an Account?',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.grey[600]),
                    ),
                    FlatButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushReplacementNamed(LoginScreen.routeName);
                      },
                      child: Text(
                        'Login Here',
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
      ),
    );
  }
}

displayToastMessage(String message) {
  Fluttertoast.showToast(msg: message);
}
