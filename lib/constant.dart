// ----- STRINGS ------
import 'package:flutter/material.dart';

const baseURL = 'http://192.168.8.112:8080/api';
// const baseURL = 'http://localhost:8080/api';

const loginURL = baseURL + '/login';
const registerURL = baseURL + '/register';
const OTPURL = baseURL + '/verify-otp';
const logoutURL = baseURL + '/logout';
const forgotPassURL = baseURL + '/forgot-password';
const resetPassURL = baseURL + '/reset-password';

const customerpreferenceURL = baseURL + '/customer-preference';
const businessRegistrationURL = baseURL + '/business-registration';

const couponURL = baseURL + '/coupons';



const userURL = baseURL + '/user';

const customerDetailURL = baseURL + '/customerDetailURL';

const merchantURL = baseURL + '/merchant';

// ----- Errors -----
const serverError = 'Server error';
const unauthorized = 'Unauthorized';
const somethingWentWrong = 'Something went wrong, try again!';
