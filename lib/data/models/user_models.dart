// data/models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String password; // Added password field
  final String? phoneNumber;
  final String? profileImageUrl;
  final String homeAddress;
  final String municipalWard;
  final int reputationPoints;
  final double voteWeight;
  final String reputationTier;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.profileImageUrl,
    required this.homeAddress,
    required this.municipalWard,
    this.reputationPoints = 0,
    this.voteWeight = 1.0,
    this.reputationTier = 'Bronze',
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      phoneNumber: json['phoneNumber'],
      profileImageUrl: json['profileImageUrl'],
      homeAddress: json['homeAddress'],
      municipalWard: json['municipalWard'],
      reputationPoints: json['reputationPoints'] ?? 0,
      voteWeight: (json['voteWeight'] ?? 1.0).toDouble(),
      reputationTier: json['reputationTier'] ?? 'Bronze',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'homeAddress': homeAddress,
      'municipalWard': municipalWard,
      'reputationPoints': reputationPoints,
      'voteWeight': voteWeight,
      'reputationTier': reputationTier,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? password,
    String? phoneNumber,
    String? profileImageUrl,
    String? homeAddress,
    String? municipalWard,
    int? reputationPoints,
    double? voteWeight,
    String? reputationTier,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      homeAddress: homeAddress ?? this.homeAddress,
      municipalWard: municipalWard ?? this.municipalWard,
      reputationPoints: reputationPoints ?? this.reputationPoints,
      voteWeight: voteWeight ?? this.voteWeight,
      reputationTier: reputationTier ?? this.reputationTier,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
