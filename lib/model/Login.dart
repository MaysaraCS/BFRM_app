import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Login {
  // User authentication data
  String? username;
  String? email;
  String? authToken;
  String? userId;
  String? userRole;

  // Customer preferences
  List<String> cuisineType = [];
  List<String> couponType = [];

  // Business registration data (for merchants)
  String? restaurantName;
  List<String> primGoal = [];
  String? restaurantLocation;
  String? otherGoal;
  String? restaurantLogo;
  String? restaurantPhoto;
  String? restaurantContact;
  final bool? isVerified;

  // Constructor
  Login({
    this.username,
    this.email,
    this.authToken,
    this.userId,
    this.userRole,
    this.cuisineType = const [],
    this.couponType = const [],
    this.restaurantName,
    this.primGoal = const [],
    this.restaurantLocation,
    this.otherGoal,
    this.restaurantLogo,
    this.restaurantPhoto,
    this.restaurantContact,
    this.isVerified,
  });

  // Add this method to fetch user ID by email after registration
  Future<bool> fetchUserIdByEmail(String baseURL) async {
    if (email == null || email!.isEmpty) {
      print('❌ Cannot fetch user ID: email is null or empty');
      return false;
    }

    try {
      // Create a request to get user info by email
      final response = await http.post(
        Uri.parse('$baseURL/api/user/by-email'), // You'll need this endpoint
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == true && responseData['data'] != null) {
          userId = responseData['data']['id']?.toString() ??
              responseData['data']['user_id']?.toString() ??
              responseData['data']['_id']?.toString();

          print('✅ User ID fetched successfully: $userId');
          return userId != null && userId!.isNotEmpty;
        }
      }

      print('❌ Failed to fetch user ID: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Error fetching user ID: $e');
      return false;
    }
  }

  factory Login.fromJson(Map<String, dynamic> json) {
    return Login(
      email: json['email'],
      userRole: json['role'],
      username: json['username'],
      // ✅ FIX: Handle different possible userId field names
      userId: json['id']?.toString() ??
          json['user_id']?.toString() ??
          json['_id']?.toString(),
      restaurantName: json['restaurant_name'],
      restaurantContact: json['phone_number'],
      restaurantLocation: json['location'],
      restaurantLogo: json['logo'],
      restaurantPhoto: json['photo'],
      otherGoal: json['other_goal'],
      cuisineType: List<String>.from(json['cuisine_type'] ?? []),
      couponType: List<String>.from(json['coupon_type'] ?? []),
      primGoal: List<String>.from(json['primary_goal'] ?? []),
      isVerified: json['is_verified'],
    );
  }

  // Method to clear business registration data after successful submission
  void clearBusinessData() {
    restaurantName = null;
    primGoal.clear();
    restaurantLocation = null;
    otherGoal = null;
    restaurantLogo = null;
    restaurantPhoto = null;
    restaurantContact = null;
  }

  // Method to clear all user data (for logout)
  void clearAllData() {
    username = null;
    email = null;
    authToken = null;
    userId = null;
    userRole = null;
    cuisineType.clear();
    couponType.clear();
    clearBusinessData();
  }

  // Method to check if user is merchant
  bool isMerchant() {
    return userRole?.toLowerCase() == 'merchant';
  }

  // Method to check if user is customer
  bool isCustomer() {
    return userRole?.toLowerCase() == 'customer';
  }

  // Method to check if user is authenticated
  bool isAuthenticated() {
    return authToken != null && authToken!.isNotEmpty;
  }

  // Method to validate business registration data
  bool isBusinessDataComplete() {
    return restaurantName != null &&
        restaurantName!.isNotEmpty &&
        restaurantLocation != null &&
        restaurantLocation!.isNotEmpty &&
        restaurantLogo != null &&
        restaurantLogo!.isNotEmpty &&
        restaurantPhoto != null &&
        restaurantPhoto!.isNotEmpty &&
        primGoal.isNotEmpty;
  }

  // Method to get primary goals as string (for API submission)
  String getPrimaryGoalsAsString() {
    return primGoal.join(', ');
  }

  // Method to set user data from login response
  void setUserData({
    required String email,
    required String token,
    required String role,
    String? id,
    String? name,
  }) {
    this.email = email;
    this.authToken = token;
    this.userRole = role;
    this.userId = id;
    this.username = name;
  }

  // Method to convert to JSON for API requests
  Map<String, dynamic> toBusinessRegistrationJson() {
    return {
      'email': email,
      'restaurant_name': restaurantName,
      'primary_goal': getPrimaryGoalsAsString(),
      'other_goal': otherGoal ?? '',
      'location': restaurantLocation,
      'logo': restaurantLogo,
      'photo': restaurantPhoto,
      'phone_number': restaurantContact,
    };
  }

  // Method to get authentication headers
  Map<String, String> getAuthHeaders() {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (isAuthenticated()) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  @override
  String toString() {
    return 'Login{email: $email, userId: $userId, role: $userRole, isAuthenticated: ${isAuthenticated()}}';
  }
}