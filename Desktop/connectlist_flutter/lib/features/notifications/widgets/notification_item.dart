import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/notification_model.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (!notification.isRead && onMarkAsRead != null) {
          onMarkAsRead!();
        }
        onTap?.call();
      },
      child: Container(
        color: notification.isRead 
            ? Colors.white 
            : Colors.orange.shade50.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.displayTitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: notification.isRead 
                                ? FontWeight.w500 
                                : FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      Text(
                        notification.timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.sender?.avatarUrl != null) ...[
                    const SizedBox(height: 8),
                    _buildSenderInfo(),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8, top: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (onDelete != null)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete!();
                      } else if (value == 'mark_read' && onMarkAsRead != null) {
                        onMarkAsRead!();
                      }
                    },
                    itemBuilder: (context) => [
                      if (!notification.isRead)
                        PopupMenuItem(
                          value: 'mark_read',
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.check(), size: 16),
                              const SizedBox(width: 8),
                              const Text('Mark as read'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(PhosphorIcons.trash(), size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      PhosphorIcons.dotsThreeVertical(),
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.like:
        icon = PhosphorIcons.heart(PhosphorIconsStyle.fill);
        iconColor = Colors.red;
        break;
      case NotificationType.comment:
        icon = PhosphorIcons.chatCircle(PhosphorIconsStyle.fill);
        iconColor = Colors.green;
        break;
      case NotificationType.follow:
        icon = PhosphorIcons.userPlus(PhosphorIconsStyle.fill);
        iconColor = Colors.blue;
        break;
      case NotificationType.share:
        icon = PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill);
        iconColor = Colors.orange;
        break;
      case NotificationType.listTrending:
        icon = PhosphorIcons.star(PhosphorIconsStyle.fill);
        iconColor = Colors.amber;
        break;
      case NotificationType.listCollaboration:
        icon = PhosphorIcons.users(PhosphorIconsStyle.fill);
        iconColor = Colors.purple;
        break;
      case NotificationType.mention:
        icon = PhosphorIcons.at(PhosphorIconsStyle.fill);
        iconColor = Colors.indigo;
        break;
      case NotificationType.system:
        icon = PhosphorIcons.info(PhosphorIconsStyle.fill);
        iconColor = Colors.grey;
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: iconColor,
      ),
    );
  }

  Widget _buildSenderInfo() {
    if (notification.sender == null) return const SizedBox.shrink();

    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundImage: notification.sender!.avatarUrl != null
              ? NetworkImage(notification.sender!.avatarUrl!)
              : null,
          child: notification.sender!.avatarUrl == null
              ? Text(
                  notification.sender!.username[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          notification.sender!.fullName ?? notification.sender!.username,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}