class UserPayload {
  final String? name;
  final String? email;
  final String? phone;
  final List<String>? interests;
  final String? profileImage;
  final bool? profileComplete;
  final String? role;
  const UserPayload({
    this.name,
    this.email,
    this.phone,
    this.interests,
    this.profileImage,
    this.profileComplete,
    this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "email": email,
      "phone": phone,
      "interests": interests,
      "profileImage": profileImage,
      "profileComplete": profileComplete,
      "role": role,
    };
  }

  UserPayload copyWith({
    String? name,
    String? email,
    String? phone,
    List<String>? interests,
    String? profileImage,
    bool? profileComplete,
    String? role,
  }) {
    return UserPayload(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      interests: interests ?? this.interests,
      profileImage: profileImage ?? this.profileImage,
      profileComplete: profileComplete ?? this.profileComplete,
      role: role ?? this.role,
    );
  }
}
