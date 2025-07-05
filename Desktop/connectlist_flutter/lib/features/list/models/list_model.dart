class ListModel {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String createdBy;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPrivate;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByCurrentUser;
  final List<ListItem> items;
  final UserProfile? creatorProfile;

  ListModel({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.createdBy,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.isPrivate = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByCurrentUser = false,
    this.items = const [],
    this.creatorProfile,
  });

  factory ListModel.fromJson(Map<String, dynamic> json) {
    return ListModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      createdBy: json['created_by'] as String,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isPrivate: json['is_private'] as bool? ?? false,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLikedByCurrentUser: json['is_liked_by_current_user'] as bool? ?? false,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ListItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      creatorProfile: json['creator_profile'] != null
          ? UserProfile.fromJson(json['creator_profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'created_by': createdBy,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_private': isPrivate,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked_by_current_user': isLikedByCurrentUser,
      'items': items.map((item) => item.toJson()).toList(),
      'creator_profile': creatorProfile?.toJson(),
    };
  }
}

class ListItem {
  final String id;
  final String listId;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? externalUrl;
  final int position;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  ListItem({
    required this.id,
    required this.listId,
    required this.title,
    this.description,
    this.imageUrl,
    this.externalUrl,
    required this.position,
    required this.createdAt,
    this.metadata,
  });

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      id: json['id'] as String,
      listId: json['list_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      externalUrl: json['external_url'] as String?,
      position: json['position'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'external_url': externalUrl,
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class UserProfile {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
    };
  }
}