// ----- STRINGS ------
import 'package:flutter/material.dart';

const baseURL = 'http://192.168.8.107:8080/api';

const loginURL = baseURL + '/login';
const registerURL = baseURL + '/register';
const OTPURL = baseURL + '/verify-otp';
const logoutURL = baseURL + '/logout';
const userURL = baseURL + '/user';

const customerDetailURL = baseURL + '/customerDetailURL';

const merchantDetailURL = baseURL + '/merchantDetailURL';

// ----- Errors -----
const serverError = 'Server error';
const unauthorized = 'Unauthorized';
const somethingWentWrong = 'Something went wrong, try again!';
