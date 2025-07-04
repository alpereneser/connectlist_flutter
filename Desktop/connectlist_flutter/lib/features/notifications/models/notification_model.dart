import 'package:connectlist/features/auth/models/user_model.dart';

enum NotificationType {
  like,
  comment,
  follow,
  share,
  listTrending,
  listCollaboration,
  mention,
  system,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final String? senderId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? sender;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.senderId,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.sender,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      type: _parseNotificationType(json['type']),
      title: json['title'],
      message: json['message'],
      data: json['data'] as Map<String, dynamic>?,
      senderId: json['sender_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      sender: json['sender'] != null ? UserModel.fromJson(json['sender']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'data': data,
      'sender_id': senderId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'share':
        return NotificationType.share;
      case 'list_trending':
        return NotificationType.listTrending;
      case 'list_collaboration':
        return NotificationType.listCollaboration;
      case 'mention':
        return NotificationType.mention;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    String? senderId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? sender,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      senderId: senderId ?? this.senderId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sender: sender ?? this.sender,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get displayTitle {
    if (sender != null) {
      switch (type) {
        case NotificationType.like:
          return '${sender!.fullName ?? sender!.username} liked your list';
        case NotificationType.comment:
          return '${sender!.fullName ?? sender!.username} commented on your list';
        case NotificationType.follow:
          return '${sender!.fullName ?? sender!.username} started following you';
        case NotificationType.share:
          return '${sender!.fullName ?? sender!.username} shared your list';
        case NotificationType.listCollaboration:
          return '${sender!.fullName ?? sender!.username} invited you to collaborate';
        case NotificationType.mention:
          return '${sender!.fullName ?? sender!.username} mentioned you';
        default:
          return title;
      }
    }
    return title;
  }
}

class NotificationLogModel {
  final String id;
  final String notificationId;
  final String userId;
  final String status;
  final DateTime sentAt;
  final String? errorMessage;
  final DateTime createdAt;

  NotificationLogModel({
    required this.id,
    required this.notificationId,
    required this.userId,
    required this.status,
    required this.sentAt,
    this.errorMessage,
    required this.createdAt,
  });

  factory NotificationLogModel.fromJson(Map<String, dynamic> json) {
    return NotificationLogModel(
      id: json['id'],
      notificationId: json['notification_id'],
      userId: json['user_id'],
      status: json['status'],
      sentAt: DateTime.parse(json['sent_at']),
      errorMessage: json['error_message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notification_id': notificationId,
      'user_id': userId,
      'status': status,
      'sent_at': sentAt.toIso8601String(),
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }
}