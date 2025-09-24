import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String? phoneNumber;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.phoneNumber,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create UserProfile from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserProfile(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      phoneNumber: data['phoneNumber'],
      bio: data['bio'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert UserProfile to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy of UserProfile with updated fields
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    String? phoneNumber,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if profile has a profile image
  bool get hasProfileImage =>
      profileImageUrl != null && profileImageUrl!.isNotEmpty;

  // Get initials for display when no profile image
  String get initials {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'U';

    List<String> nameParts = trimmedName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return 'U';
  }
}
