class Merchant{
  int? id;
  String? logo;
  String? image;
  String? email;
  String? token;
  List<String>? PrimaryGoal;
  String? restaurantPhoto;
  String? contactInfo;
  String? Address;

  Merchant({
    this.id,
    this.logo,
    this.image,
    this.email,
    this.token,
    this.PrimaryGoal,
    this.restaurantPhoto,
    this.contactInfo,
    this.Address
  });

  factory Merchant.fromJson(Map<String, dynamic> json){
    return Merchant(
      id: json['id'],
      logo: json['logo'],
      image: json['image'],
      email: json['email'],
      token: json['token'],
      restaurantPhoto: json['restaurant_photo'],
      contactInfo: json['contact_info'],
      PrimaryGoal: List<String>.from(json['PrimaryGoal'] ?? []),
    );
  }
}