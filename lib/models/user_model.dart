class UserModel {
  final String userId;
  final String name;
  final String email;
  final String role;           // 'patient' or 'doctor'
  final String fcmToken;

  // ── Patient-specific fields ──
  final double height;
  final double weight;
  final String bloodGroup;
  final int age;
  final String address;

  // ── Doctor-specific fields ──
  final String specialty;
  final String hospital;
  final String hospitalAddress;
  final String pmdcNumber;
  final int experience;
  final String aboutMe;
  final List<String> availableSlots;
  final String image;
  final double rating;
  final int reviews;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.role = 'patient',
    this.fcmToken = '',
    this.height = 0.0,
    this.weight = 0.0,
    this.bloodGroup = '',
    this.age = 0,
    this.address = '',
    this.specialty = '',
    this.hospital = '',
    this.hospitalAddress = '',
    this.pmdcNumber = '',
    this.experience = 0,
    this.aboutMe = '',
    this.availableSlots = const [],
    this.image = '',
    this.rating = 0.0,
    this.reviews = 0,
  });

  bool get isDoctor => role == 'doctor';
  bool get isPatient => role == 'patient';
  String get hospitalName => hospital;

  /// First initial (or two-letter initials) for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // ── Firestore → Dart (from JSON map) ──
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'patient',
      fcmToken: json['fcmToken'] ?? '',
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      bloodGroup: json['bloodGroup'] ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      address: json['address'] ?? '',
      specialty: json['specialty'] ?? '',
      hospital: json['hospital'] ?? json['hospitalName'] ?? '',
      hospitalAddress: json['hospitalAddress'] ?? '',
      pmdcNumber: json['pmdcNumber'] ?? '',
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      aboutMe: json['aboutMe'] ?? '',
      availableSlots: List<String>.from(json['availableSlots'] ?? []),
      image: json['image'] ?? json['imageUrl'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
    );
  }

  /// Legacy factory (used by firebase_service.dart getAllDoctors)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    final model = UserModel.fromJson(map);
    return UserModel(
      userId: id,
      name: model.name,
      email: model.email,
      role: model.role,
      fcmToken: model.fcmToken,
      height: model.height,
      weight: model.weight,
      bloodGroup: model.bloodGroup,
      age: model.age,
      address: model.address,
      specialty: model.specialty,
      hospital: model.hospital,
      hospitalAddress: model.hospitalAddress,
      pmdcNumber: model.pmdcNumber,
      experience: model.experience,
      aboutMe: model.aboutMe,
      availableSlots: model.availableSlots,
      image: model.image,
      rating: model.rating,
      reviews: model.reviews,
    );
  }

  // ── Dart → Firestore ──
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'fcmToken': fcmToken,
      'height': height,
      'weight': weight,
      'bloodGroup': bloodGroup,
      'age': age,
      'address': address,
      'specialty': specialty,
      'hospital': hospital,
      'hospitalName': hospital, // sync both schemas
      'hospitalAddress': hospitalAddress,
      'pmdcNumber': pmdcNumber,
      'experience': experience,
      'aboutMe': aboutMe,
      'availableSlots': availableSlots,
      'image': image,
      'rating': rating,
      'reviews': reviews,
    };
  }

  @override
  String toString() =>
      'UserModel(id: $userId, name: $name, role: $role)';
}
