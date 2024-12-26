class Customer{
  int? id;
  String? username;
  String? image;
  String? email;
  String? token;
  List<String>? cuisinePreferences;
  List<String>? interest;
  List<String>? DiningPreferences;

  Customer({
    this.id,
    this.username,
    this.image,
    this.email,
    this.token,
    this.cuisinePreferences,
    this.interest,
    this.DiningPreferences
  });

  factory Customer.fromJson(Map<String, dynamic> json){
    return Customer(
        id: json['id'],
        username: json['username'],
        image: json['image'],
        email: json['email'],
        token: json['token'],
      cuisinePreferences: List<String>.from(json['cuisine_preferences'] ?? []),
      interest: List<String>.from(json['interest'] ?? []),
      DiningPreferences: List<String>.from(json['DiningPreferences'] ?? []),
    );
  }
}