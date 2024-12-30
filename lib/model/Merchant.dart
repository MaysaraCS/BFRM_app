import 'package:bfrm_app_flutter/model/User.dart';

class Merchant extends User {
  String? logo;
  String? image;
  List<String>? primaryGoal;
  String? restaurantPhoto;
  String? contactInfo;
  String? address;

  Merchant({
    int? id,
    String? email,
    String? token,
    this.logo,
    this.image,
    this.primaryGoal,
    this.restaurantPhoto,
    this.contactInfo,
    this.address,
  }) : super(id: id, email: email, token: token);

  // Override the fromJson method to include specific properties
  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'],
      email: json['email'],
      token: json['token'],
      logo: json['logo'],
      image: json['image'],
      restaurantPhoto: json['restaurant_photo'],
      contactInfo: json['contact_info'],
      address: json['address'],
      primaryGoal: List<String>.from(json['PrimaryGoal'] ?? []),
    );
  }
}
