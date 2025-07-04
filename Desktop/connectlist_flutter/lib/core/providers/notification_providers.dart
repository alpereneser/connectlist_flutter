import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notifications/services/notification_service.dart';
import '../../features/notifications/models/notification_model.dart';
import '../../features/notifications/providers/notifications_provider.dart';

// Global notification helpers that can be used throughout the app
class NotificationHelpers {
  static final _provider = Provider<NotificationHelpers>((ref) {
    return NotificationHelpers._(ref);
  });

  static NotificationHelpers read(WidgetRef ref) => ref.read(_provider);

  final Ref _ref;

  NotificationHelpers._(this._ref);

  NotificationService get _notificationService => _ref.read(notificationServiceProvider);

  // Helper to create like notification
  Future<void> notifyListLike({
    required String listId,
    required String listTitle,
    required String listOwnerId,
    required String likerId,
  }) async {
    try {
      await _notificationService.createLikeNotification(
        listOwnerId: listOwnerId,
        listId: listId,
        listTitle: listTitle,
        likerId: likerId,
      );
    } catch (e) {
      // Log error but don't throw to avoid disrupting user flow
      print('Failed to create like notification: $e');
    }
  }

  // Helper to create comment notification
  Future<void> notifyListComment({
    required String listId,
    required String listTitle,
    required String listOwnerId,
    required String commenterId,
    required String commentContent,
  }) async {
    try {
      await _notificationService.createCommentNotification(
        listOwnerId: listOwnerId,
        listId: listId,
        listTitle: listTitle,
        commenterId: commenterId,
        commentContent: commentContent,
      );
    } catch (e) {
      print('Failed to create comment notification: $e');
    }
  }

  // Helper to create follow notification
  Future<void> notifyUserFollow({
    required String followedUserId,
    required String followerId,
  }) async {
    try {
      await _notificationService.createFollowNotification(
        followedUserId: followedUserId,
        followerId: followerId,
      );
    } catch (e) {
      print('Failed to create follow notification: $e');
    }
  }

  // Helper to create list trending notification
  Future<void> notifyListTrending({
    required String listId,
    required String listTitle,
    required String listOwnerId,
    required int viewCount,
  }) async {
    try {
      await _notificationService.createListTrendingNotification(
        listOwnerId: listOwnerId,
        listId: listId,
        listTitle: listTitle,
        viewCount: viewCount,
      );
    } catch (e) {
      print('Failed to create trending notification: $e');
    }
  }

  // Helper to create system notifications
  Future<void> notifySystem({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _notificationService.createSystemNotification(
        userId: userId,
        title: title,
        message: message,
        data: data,
      );
    } catch (e) {
      print('Failed to create system notification: $e');
    }
  }

  // Batch notification creation for multiple users
  Future<void> notifyMultipleUsers({
    required List<String> userIds,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String? senderId,
  }) async {
    try {
      final futures = userIds.map((userId) => 
        _notificationService.createNotification(
          userId: userId,
          type: type,
          title: title,
          message: message,
          data: data,
          senderId: senderId,
        )
      );
      
      await Future.wait(futures);
    } catch (e) {
      print('Failed to create batch notifications: $e');
    }
  }

  // Notification for list collaboration invitation
  Future<void> notifyListCollaboration({
    required String listId,
    required String listTitle,
    required String invitedUserId,
    required String inviterId,
  }) async {
    try {
      await _notificationService.createNotification(
        userId: invitedUserId,
        type: NotificationType.listCollaboration,
        title: 'Collaboration invitation',
        message: 'You\'ve been invited to collaborate on "$listTitle"',
        data: {
          'list_id': listId,
          'list_title': listTitle,
          'action_type': 'collaboration_invite',
        },
        senderId: inviterId,
      );
    } catch (e) {
      print('Failed to create collaboration notification: $e');
    }
  }

  // Notification for mentions in comments
  Future<void> notifyMention({
    required String mentionedUserId,
    required String mentionerId,
    required String listId,
    required String listTitle,
    required String commentContent,
  }) async {
    try {
      await _notificationService.createNotification(
        userId: mentionedUserId,
        type: NotificationType.mention,
        title: 'You were mentioned',
        message: 'You were mentioned in a comment on "$listTitle"',
        data: {
          'list_id': listId,
          'list_title': listTitle,
          'comment_content': commentContent,
          'action_type': 'mention',
        },
        senderId: mentionerId,
      );
    } catch (e) {
      print('Failed to create mention notification: $e');
    }
  }

  // Helper to check if user has push notifications enabled
  Future<bool> isPushNotificationEnabled(String userId) async {
    try {
      // This would check the user's notification preferences
      // For now, we'll assume all users have notifications enabled
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Provider for notification helpers
final notificationHelpersProvider = Provider<NotificationHelpers>((ref) {
  return NotificationHelpers._(ref);
});

// Provider for checking if there are unread notifications
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final unreadCount = ref.watch(unreadNotificationsCountProvider);
  return unreadCount > 0;
});

// Provider for notification sound/vibration preferences
final notificationPreferencesProvider = StateProvider<Map<String, bool>>((ref) {
  return {
    'sound_enabled': true,
    'vibration_enabled': true,
    'push_notifications_enabled': true,
    'in_app_notifications_enabled': true,
  };
});