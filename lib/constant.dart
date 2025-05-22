// ----- STRINGS ------
import 'package:flutter/material.dart';

const baseURL = 'http://192.168.0.197:8080/api';
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

const discountURL = baseURL + '/discounts';

const favoriteURL = baseURL + '/favorites';




const userURL = baseURL + '/user';

const customerDetailURL = baseURL + '/customerDetailURL';

const merchantURL = baseURL + '/merchant';
const ProfileURL = baseURL + '/profile';



// ----- Errors -----
const serverError = 'Server error';
const unauthorized = 'Unauthorized';
const somethingWentWrong = 'Something went wrong, try again!';
