class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String role;
  final String status;
  final String address;
  final String city;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
    required this.status,
    required this.address,
    required this.city,
  });

  // Supabase (JSON) සිට Model එකට මැප් කරගැනීමට
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? 'No Name',
      phone: json['phone'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      role: json['role'] ?? 'customer',
      status: json['status'] ?? 'pending',
      address: json['address'] ?? 'N/A',
      city: json['city'] ?? 'N/A',
    );
  }

  // Model එකේ සිට Database (JSON) එකට යැවීමට
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'role': role,
      'status': status,
      'address': address,
      'city': city,
    };
  }
}
