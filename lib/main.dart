import 'package:flutter/material.dart';
import 'package:bfrm_app_flutter/screens/welcome_page.dart';
import 'package:bfrm_app_flutter/screens/OTP_Verify.dart';
import 'package:bfrm_app_flutter/screens/SuccessPage.dart';
import 'package:bfrm_app_flutter/screens/login.dart';
import 'package:bfrm_app_flutter/screens/SetPasswordPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BFRM',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WelcomePage(),
    );
  }
}
