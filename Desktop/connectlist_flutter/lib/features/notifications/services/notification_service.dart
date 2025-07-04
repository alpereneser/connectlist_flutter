import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationService {
  final SupabaseClient _supabase;
  final Ref _ref;

  NotificationService(this._supabase, this._ref);

  // Get notifications for current user
  Future<List<NotificationModel>> getNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final queryBuilder = _supabase
          .from('notifications')
          .select('''
            *,
            sender:users_profiles!notifications_sender_id_fkey(
              id,
              username,
              full_name,
              avatar_url
            )
          ''')
          .eq('user_id', currentUser.id);

      if (unreadOnly) {
        queryBuilder.eq('is_read', false);
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return response.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', currentUser.id)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return 0;
      }

      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', currentUser.id)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Create notification
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? senderId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': type.name,
        'title': title,
        'message': message,
        'data': data ?? {},
        'sender_id': senderId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Subscribe to real-time notifications
  Stream<List<NotificationModel>> subscribeToNotifications() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser.id)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => NotificationModel.fromJson(json)).toList());
  }

  // Notification creation helpers for different events
  Future<void> createLikeNotification({
    required String listOwnerId,
    required String listId,
    required String listTitle,
    required String likerId,
  }) async {
    // Don't notify if user likes their own list
    if (listOwnerId == likerId) return;

    await createNotification(
      userId: listOwnerId,
      type: NotificationType.like,
      title: 'New like on your list',
      message: 'Someone liked your list "$listTitle"',
      data: {
        'list_id': listId,
        'list_title': listTitle,
        'action_type': 'like',
      },
      senderId: likerId,
    );
  }

  Future<void> createCommentNotification({
    required String listOwnerId,
    required String listId,
    required String listTitle,
    required String commenterId,
    required String commentContent,
  }) async {
    // Don't notify if user comments on their own list
    if (listOwnerId == commenterId) return;

    await createNotification(
      userId: listOwnerId,
      type: NotificationType.comment,
      title: 'New comment on your list',
      message: 'Someone commented on your list "$listTitle"',
      data: {
        'list_id': listId,
        'list_title': listTitle,
        'comment_content': commentContent,
        'action_type': 'comment',
      },
      senderId: commenterId,
    );
  }

  Future<void> createFollowNotification({
    required String followedUserId,
    required String followerId,
  }) async {
    // Don't notify if user follows themselves
    if (followedUserId == followerId) return;

    await createNotification(
      userId: followedUserId,
      type: NotificationType.follow,
      title: 'New follower',
      message: 'Someone started following you',
      data: {
        'action_type': 'follow',
      },
      senderId: followerId,
    );
  }

  Future<void> createListTrendingNotification({
    required String listOwnerId,
    required String listId,
    required String listTitle,
    required int viewCount,
  }) async {
    await createNotification(
      userId: listOwnerId,
      type: NotificationType.listTrending,
      title: 'Your list is trending!',
      message: 'Your list "$listTitle" reached $viewCount views',
      data: {
        'list_id': listId,
        'list_title': listTitle,
        'view_count': viewCount,
        'action_type': 'trending',
      },
    );
  }

  Future<void> createSystemNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.system,
      title: title,
      message: message,
      data: data,
    );
  }
}

// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final supabase = ref.read(supabaseProvider);
  return NotificationService(supabase, ref);
});