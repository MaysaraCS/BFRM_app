// Merchant Service

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bfrm_app_flutter/api/api_response.dart';
import '../model/merchant.dart';
import '../constant.dart';

// Get Merchant Details
Future<ApiResponse> getMerchantDetail() async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    final response = await http.get(
      Uri.parse(merchantDetailURL),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    switch (response.statusCode) {
      case 200:
        apiResponse.data = Merchant.fromJson(jsonDecode(response.body));
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

// Update Merchant Details
Future<ApiResponse> updateMerchantDetails({
  String? logo,
  String? restaurantPhoto,
  String? contactInfo,
  String? address,
  List<String>? primaryGoal,
}) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    final response = await http.put(
      Uri.parse(merchantDetailURL),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: {
        'logo': logo,
        'restaurant_photo': restaurantPhoto,
        'contact_info': contactInfo,
        'address': address,
        'PrimaryGoal': jsonEncode(primaryGoal ?? []),
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


// get user id
Future<int> getUserId() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return pref.getInt('userId') ?? 0;
}

// logout
Future<bool> logout() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  return await pref.remove('token');
}

// Get base64 encoded image
String? getStringImage(File? file) {
  if (file == null) return null ;
  return base64Encode(file.readAsBytesSync());
}