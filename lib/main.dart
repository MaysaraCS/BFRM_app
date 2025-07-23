import 'package:bfrm_app_flutter/screens/MerchantHomePage.dart';
import 'package:bfrm_app_flutter/screens/UsernamePage.dart';
import 'package:bfrm_app_flutter/services/user_services.dart';
import 'package:flutter/material.dart';
import 'package:bfrm_app_flutter/screens/welcome_page.dart';
import 'package:bfrm_app_flutter/screens/OTP_Verify.dart';
import 'package:bfrm_app_flutter/screens/SuccessPage.dart';
import 'package:bfrm_app_flutter/screens/login.dart';
import 'package:bfrm_app_flutter/screens/SetPasswordPage.dart';
import 'package:bfrm_app_flutter/screens/Password_Recovery.dart';

import 'package:bfrm_app_flutter/screens/cuisine_preferences_page.dart';
import 'package:bfrm_app_flutter/screens/CouponPreferencePage.dart';
import 'package:bfrm_app_flutter/screens/DiningPreferencesPage.dart';
import 'package:bfrm_app_flutter/screens/RestaurantName.dart';
import 'package:bfrm_app_flutter/screens/CustomerHomePage.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'model/Login.dart';
import 'package:bfrm_app_flutter/services/ble_service.dart';



Future<void> initServices() async {
  await Get.putAsync(() => BleService().init());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServices();  // <--- this is new
  runApp(MyApp());
}

// void main() {
//   runApp(MyApp());
// }

class MyApp extends StatelessWidget {
  //Login user = Login()..email = "mohamed16@gmail.com";
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BFRM',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:WelcomePage(),
    );
  }
}
