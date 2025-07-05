class UserModel {
  final String id;
  final String username;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final String? website;
  final String? location;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? followersCount;
  final int? followingCount;
  final int? listsCount;

  UserModel({
    required this.id,
    required this.username,
    this.fullName,
    this.bio,
    this.avatarUrl,
    this.website,
    this.location,
    this.phoneNumber,
    required this.createdAt,
    this.updatedAt,
    this.followersCount,
    this.followingCount,
    this.listsCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      website: json['website'] as String?,
      location: json['location'] as String?,
      phoneNumber: json['phone_number'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      followersCount: json['followers_count'] as int?,
      followingCount: json['following_count'] as int?,
      listsCount: json['lists_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'website': website,
      'location': location,
      'phone_number': phoneNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'followers_count': followersCount,
      'following_count': followingCount,
      'lists_count': listsCount,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? website,
    String? location,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? followersCount,
    int? followingCount,
    int? listsCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      website: website ?? this.website,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      listsCount: listsCount ?? this.listsCount,
    );
  }
}