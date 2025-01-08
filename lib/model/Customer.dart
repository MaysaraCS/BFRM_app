import 'package:bfrm_app_flutter/model/User.dart';

class Customer extends User {
  String? username;
  String? image;
  List<String>? cuisinePreferences;
  List<String>? interest;
  List<String>? diningPreferences;

  Customer({
    int? id,
    String? email,
    String? token,
    required this.username,
    this.image,
    this.cuisinePreferences = const [],
    this.interest = const [],
    this.diningPreferences = const [],
  }) : super(id: id, email: email, token: token);

  // Override the fromJson method to include specific properties
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      email: json['email'],
      token: json['token'],
      username: json['username'],
      image: json['image'],
      cuisinePreferences: List<String>.from(json['cuisine_preferences'] ?? []),
      interest: List<String>.from(json['interest'] ?? []),
      diningPreferences: List<String>.from(json['diningPreferences'] ?? []),
    );
  }
}
