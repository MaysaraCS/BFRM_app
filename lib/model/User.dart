class User {
  int? id;
  String? email;
  String? role;
  String? token;

  User({this.id, this.email, this.token , this.role});

  // Factory constructor for shared fields
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      token: json['token'],
    );
  }
}
