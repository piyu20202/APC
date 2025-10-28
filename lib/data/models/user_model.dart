class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? areaCode;
  final String? landline;
  final String? unitApartmentNo;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zip;
  final int isTradeUser;
  final int specialUser;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.areaCode,
    this.landline,
    this.unitApartmentNo,
    this.address,
    this.city,
    this.state,
    this.country,
    this.zip,
    required this.isTradeUser,
    required this.specialUser,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      areaCode: json['area_code'] as String?,
      landline: json['landline'] as String?,
      unitApartmentNo: json['unit_apartmentno'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      zip: json['zip'] as String?,
      isTradeUser: json['is_trade_user'] as int,
      specialUser: json['special_user'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'area_code': areaCode,
      'landline': landline,
      'unit_apartmentno': unitApartmentNo,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zip': zip,
      'is_trade_user': isTradeUser,
      'special_user': specialUser,
    };
  }
}

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final UserModel user;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }
}
