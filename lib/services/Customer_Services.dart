// Customer Service
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bfrm_app_flutter/api/api_response.dart';
import '../model/customer.dart';
import '../constant.dart';

// Get Customer Details
Future<ApiResponse> getCustomerDetail() async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    final response = await http.get(
      Uri.parse(customerDetailURL),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    switch (response.statusCode) {
      case 200:
        apiResponse.data = Customer.fromJson(jsonDecode(response.body));
        break;
      case 401:
        apiResponse.error = unauthorized;
        break;
      default:
        apiResponse.error = somethingWentWrong;
        break;
    }
  } catch (e) {
    apiResponse.error = serverError;
  }
  return apiResponse;
}

// Update Customer Preferences
Future<ApiResponse> updateCustomerPreferences({
  List<String>? cuisinePreferences,
  List<String>? interest,
  List<String>? diningPreferences,
}) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    final response = await http.put(
      Uri.parse(customerDetailURL),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: {
        'cuisine_preferences': jsonEncode(cuisinePreferences ?? []),
        'interest': jsonEncode(interest ?? []),
        'DiningPreferences': jsonEncode(diningPreferences ?? []),
      },
    );

    switch (response.statusCode) {
      case 200:
        apiResponse.data = jsonDecode(response.body)['message'];
        break;
      case 401:
        apiResponse.error = unauthorized;
        break;
      default:
        apiResponse.error = somethingWentWrong;
        break;
    }
  } catch (e) {
    apiResponse.error = serverError;
  }
  return apiResponse;
}

// Shared Utilities

// Get token
Future<String> getToken() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return pref.getString('token') ?? '';
}
