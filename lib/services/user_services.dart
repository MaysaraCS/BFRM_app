// User Service
import 'dart:convert';
import 'dart:io';
import 'package:bfrm_app_flutter/model/Merchant.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bfrm_app_flutter/api/api_response.dart';
import '../model/customer.dart';
import '../constant.dart';


// Register
Future<ApiResponse> register(String email, String password) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    final response = await http.post(
        Uri.parse(registerURL),
        headers: {'Accept': 'application/json'},
        body: {
          'email': email,
          'password': password,
        });

    switch (response.statusCode) {
      case 200:
        final data = jsonDecode(response.body);
        if (data['role'] == 'customer') {
          apiResponse.data = Customer.fromJson(data);
        } else if (data['role'] == 'merchant') {
          apiResponse.data = Merchant.fromJson(data);
        } else {
          apiResponse.error = 'Unknown user type';
        }
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        break;
      default:
        print(response.body); // Log for debugging
        apiResponse.error = somethingWentWrong;
        break;
    }
  } catch (e) {
    apiResponse.error = serverError;
  }
  return apiResponse;
}

// login
Future<ApiResponse> login (String email, String password) async {
  ApiResponse apiResponse = ApiResponse();
  try{
    final response = await http.post(
        Uri.parse(loginURL),
        headers: {'Accept': 'application/json'},
        body: {'email': email, 'password': password}
    );


    switch (response.statusCode) {
      case 200:
        final data = jsonDecode(response.body);
        if (data['role'] == 'customer') {
          apiResponse.data = Customer.fromJson(data);
        } else if (data['role'] == 'merchant') {
          apiResponse.data = Merchant.fromJson(data);
        } else {
          apiResponse.error = 'Unknown user type';
        }
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        break;
      case 404:
        apiResponse.error = jsonDecode(response.body)['message'];
        break;
      default:
        print(response.body); // Log for debugging
        apiResponse.error = somethingWentWrong;
        break;
    }
  } catch (e) {
    apiResponse.error = serverError;
  }
  return apiResponse;
}