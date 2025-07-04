import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

// State for notifications list
class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int unreadCount;

  NotificationsState({
    required this.notifications,
    required this.isLoading,
    this.error,
    required this.hasMore,
    required this.unreadCount,
  });

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? unreadCount,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// Notifications provider with pagination and real-time updates
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationService _notificationService;
  static const int _pageSize = 20;

  NotificationsNotifier(this._notificationService) : super(
    NotificationsState(
      notifications: [],
      isLoading: false,
      hasMore: true,
      unreadCount: 0,
    ),
  ) {
    _init();
  }

  void _init() {
    loadNotifications();
    loadUnreadCount();
  }

  // Load notifications with pagination
  Future<void> loadNotifications({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(
        notifications: [],
        isLoading: true,
        error: null,
        hasMore: true,
      );
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final offset = refresh ? 0 : state.notifications.length;
      final newNotifications = await _notificationService.getNotifications(
        limit: _pageSize,
        offset: offset,
      );

      if (refresh) {
        state = state.copyWith(
          notifications: newNotifications,
          isLoading: false,
          hasMore: newNotifications.length == _pageSize,
        );
      } else {
        state = state.copyWith(
          notifications: [...state.notifications, ...newNotifications],
          isLoading: false,
          hasMore: newNotifications.length == _pageSize,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Load more notifications for pagination
  Future<void> loadMoreNotifications() async {
    if (!state.hasMore || state.isLoading) return;
    await loadNotifications();
  }

  // Refresh notifications
  Future<void> refreshNotifications() async {
    await loadNotifications(refresh: true);
    await loadUnreadCount();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      
      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      
      // Update local state
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();

      final deletedNotification = state.notifications
          .firstWhere((notification) => notification.id == notificationId);

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: deletedNotification.isRead 
            ? state.unreadCount 
            : state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Load unread count
  Future<void> loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      // Don't update error state for unread count failures
    }
  }

  // Add new notification (for real-time updates)
  void addNotification(NotificationModel notification) {
    state = state.copyWith(
      notifications: [notification, ...state.notifications],
      unreadCount: notification.isRead ? state.unreadCount : state.unreadCount + 1,
    );
  }

  // Update notification (for real-time updates)
  void updateNotification(NotificationModel notification) {
    final updatedNotifications = state.notifications.map((n) {
      return n.id == notification.id ? notification : n;
    }).toList();

    state = state.copyWith(notifications: updatedNotifications);
  }

  // Remove notification (for real-time updates)
  void removeNotification(String notificationId) {
    final updatedNotifications = state.notifications
        .where((n) => n.id != notificationId)
        .toList();

    state = state.copyWith(notifications: updatedNotifications);
  }
}

// Main notifications provider
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  return NotificationsNotifier(notificationService);
});

// Unread count provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsState = ref.watch(notificationsProvider);
  return notificationsState.unreadCount;
});

// Filtered notifications providers
final unreadNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final notificationsState = ref.watch(notificationsProvider);
  return notificationsState.notifications.where((n) => !n.isRead).toList();
});

final readNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final notificationsState = ref.watch(notificationsProvider);
  return notificationsState.notifications.where((n) => n.isRead).toList();
});

// Notifications grouped by date
final groupedNotificationsProvider = Provider<Map<String, List<NotificationModel>>>((ref) {
  final notificationsState = ref.watch(notificationsProvider);
  final notifications = notificationsState.notifications;
  
  final Map<String, List<NotificationModel>> grouped = {};
  final now = DateTime.now();
  
  for (final notification in notifications) {
    final difference = now.difference(notification.createdAt);
    String groupKey;
    
    if (difference.inDays == 0) {
      groupKey = 'Today';
    } else if (difference.inDays == 1) {
      groupKey = 'Yesterday';
    } else if (difference.inDays <= 7) {
      groupKey = 'This Week';
    } else if (difference.inDays <= 30) {
      groupKey = 'This Month';
    } else {
      groupKey = 'Earlier';
    }
    
    grouped.putIfAbsent(groupKey, () => []).add(notification);
  }
  
  return grouped;
});

// Real-time notifications stream provider
final realtimeNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final notificationService = ref.read(notificationServiceProvider);
  return notificationService.subscribeToNotifications();
});

// Listen to real-time updates and update the main provider
final notificationsRealtimeListenerProvider = Provider<void>((ref) {
  final realtimeNotifications = ref.watch(realtimeNotificationsProvider);
  final notificationsNotifier = ref.read(notificationsProvider.notifier);
  
  realtimeNotifications.whenData((notifications) {
    // This will be called when real-time updates are received
    // You can implement more sophisticated logic here to merge updates
    if (notifications.isNotEmpty) {
      notificationsNotifier.loadUnreadCount();
    }
  });
  
  return null;
});