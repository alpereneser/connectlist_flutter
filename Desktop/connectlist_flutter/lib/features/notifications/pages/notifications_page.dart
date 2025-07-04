import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../shared/widgets/bottom_menu.dart';
import '../../../shared/utils/navigation_helper.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_item.dart';
import '../models/notification_model.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  int _currentIndex = 3; // Notifications index
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Initialize notifications and real-time listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).loadNotifications(refresh: true);
      ref.read(notificationsRealtimeListenerProvider);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(notificationsProvider.notifier).loadMoreNotifications();
    }
  }

  void _onBottomMenuTap(int index) {
    context.navigateToBottomMenuTab(index, _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final unreadCount = ref.watch(unreadNotificationsCountProvider);
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'mark_all_read') {
                    await ref.read(notificationsProvider.notifier).markAllAsRead();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    enabled: unreadCount > 0,
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.checks(), size: 16),
                        const SizedBox(width: 8),
                        const Text('Mark all as read'),
                      ],
                    ),
                  ),
                ],
                child: Icon(PhosphorIcons.dotsThree()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationsProvider.notifier).refreshNotifications(),
        child: Consumer(
          builder: (context, ref, child) {
            final notificationsState = ref.watch(notificationsProvider);
            final groupedNotifications = ref.watch(groupedNotificationsProvider);

            if (notificationsState.isLoading && notificationsState.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (notificationsState.error != null && notificationsState.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.wifiSlash(),
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading notifications',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ref.read(notificationsProvider.notifier).refreshNotifications();
                      },
                      child: Text(
                        'Retry',
                        style: GoogleFonts.inter(
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (notificationsState.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.bell(),
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You\'ll see notifications here when you get them',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: _getItemCount(groupedNotifications, notificationsState),
              itemBuilder: (context, index) {
                return _buildItem(context, ref, groupedNotifications, notificationsState, index);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BottomMenu(
        currentIndex: _currentIndex,
        onTap: _onBottomMenuTap,
      ),
    );
  }

  int _getItemCount(Map<String, List<NotificationModel>> groupedNotifications, NotificationsState state) {
    int count = 0;
    for (final entry in groupedNotifications.entries) {
      count += 1; // Section header
      count += entry.value.length; // Notifications in section
    }
    if (state.isLoading && state.notifications.isNotEmpty) {
      count += 1; // Loading indicator
    }
    count += 1; // Bottom spacing
    return count;
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, Map<String, List<NotificationModel>> groupedNotifications, NotificationsState state, int index) {
    int currentIndex = 0;
    
    for (final entry in groupedNotifications.entries) {
      // Section header
      if (index == currentIndex) {
        return _buildSectionHeader(entry.key, entry.value.length);
      }
      currentIndex++;
      
      // Notifications in this section
      for (final notification in entry.value) {
        if (index == currentIndex) {
          return NotificationItem(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onMarkAsRead: () => ref.read(notificationsProvider.notifier).markAsRead(notification.id),
            onDelete: () => ref.read(notificationsProvider.notifier).deleteNotification(notification.id),
          );
        }
        currentIndex++;
      }
    }
    
    // Loading indicator
    if (state.isLoading && state.notifications.isNotEmpty && index == currentIndex) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    currentIndex++;
    
    // Bottom spacing
    if (index == currentIndex) {
      return const SizedBox(height: 100);
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Handle navigation based on notification type and data
    final data = notification.data;
    if (data != null) {
      if (data['list_id'] != null) {
        // Navigate to list details
        // Navigator.push(context, MaterialPageRoute(builder: (context) => ListDetailsPage(listId: data['list_id'])));
      } else if (data['user_id'] != null) {
        // Navigate to user profile
        // Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfilePage(userId: data['user_id'])));
      }
    }
  }
}