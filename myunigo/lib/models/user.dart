class User {
  final String userId;
  final String userName;
  final String userEmail;
  final String userPassword;
  final String userPhone;
  final String userUniversity;
  final String userAddress;
  final String userDatereg;

  User({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPassword,
    required this.userPhone,
    required this.userUniversity,
    required this.userAddress,
    required this.userDatereg,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userEmail: json['user_email'] ?? '',
      userPassword: json['user_password'] ?? '',
      userPhone: json['user_phone'] ?? '',
      userUniversity: json['user_university'] ?? '',
      userAddress: json['user_address'] ?? '',
      userDatereg: json['user_datereg'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'user_password': userPassword,
      'user_phone': userPhone,
      'user_university': userUniversity,
      'user_address': userAddress,
      'user_datereg': userDatereg,
    };
  }
}
