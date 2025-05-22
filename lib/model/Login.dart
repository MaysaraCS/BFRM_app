import 'package:flutter/material.dart';

class Login {
  // User authentication data
  String? username;
  String? email;
  String? authToken; // Add authentication token
  String? userId; // Add user ID
  String? userRole; // Add user role (merchant/customer)

  // Customer preferences
  List<String> cuisneType = [];
  List<String> couponType = [];

  // Business registration data (for merchants)
  String? restaurantname;
  List<String> PrimGoal = [];
  String? restaurantLocation;
  String? other_goal;
  String? restaurantLogo;
  String? restaurantPhoto;
  String? restaurantContact;

  // Constructor
  Login({
    this.username,
    this.email,
    this.authToken,
    this.userId,
    this.userRole,
  });

  // Method to clear business registration data after successful submission
  void clearBusinessData() {
    restaurantname = null;
    PrimGoal.clear();
    restaurantLocation = null;
    other_goal = null;
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
    cuisneType.clear();
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
    return restaurantname != null &&
        restaurantname!.isNotEmpty &&
        restaurantLocation != null &&
        restaurantLocation!.isNotEmpty &&
        restaurantLogo != null &&
        restaurantLogo!.isNotEmpty &&
        restaurantPhoto != null &&
        restaurantPhoto!.isNotEmpty &&
        PrimGoal.isNotEmpty;
  }

  // Method to get primary goals as string (for API submission)
  String getPrimaryGoalsAsString() {
    return PrimGoal.join(', ');
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
      'restaurant_name': restaurantname,
      'primary_goal': getPrimaryGoalsAsString(),
      'other_goal': other_goal ?? '',
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
    return 'Login{email: $email, role: $userRole, isAuthenticated: ${isAuthenticated()}}';
  }
}