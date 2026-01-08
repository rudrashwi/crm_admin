import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:crm_admin/logic/providers/notification_provider.dart';
import 'package:crm_admin/data/models/notification/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    log('[NOTIF_SCREEN] initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      log('[NOTIF_SCREEN] Post frame callback - fetching notifications');
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM dd, yyyy').format(dateTime);
      }
    } catch (e) {
      log('[NOTIF_SCREEN] Error formatting date: $e');
      return dateTimeStr;
    }
  }

  Color _getNotificationTypeColor(String type) {
    switch (type) {
      case 'REPORT_READY':
        return Colors.green;
      case 'REPORT_PROCESSING':
        return Colors.orange;
      case 'REPORT_FAILED':
        return Colors.red;
      case 'BROADCAST':
        return Colors.blue;
      case 'LEAD_ASSIGNED':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationTypeIcon(String type) {
    switch (type) {
      case 'REPORT_READY':
        return Icons.download_done;
      case 'REPORT_PROCESSING':
        return Icons.hourglass_empty;
      case 'REPORT_FAILED':
        return Icons.error_outline;
      case 'BROADCAST':
        return Icons.campaign;
      case 'LEAD_ASSIGNED':
        return Icons.assignment_ind;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _handleNotificationTap(
    NotificationModel notification,
    NotificationProvider provider,
  ) async {
    log('[NOTIF_SCREEN] Notification tapped: ${notification.id}');
    log('[NOTIF_SCREEN] Is read: ${notification.isRead}');
    log('[NOTIF_SCREEN] Type: ${notification.type}');

    if (!notification.isRead) {
      log('[NOTIF_SCREEN] Marking notification as read...');
      final success = await provider.markAsRead(notification.id);
      
      if (success) {
        log('[NOTIF_SCREEN] Successfully marked as read');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification marked as read'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        log('[NOTIF_SCREEN] Failed to mark as read');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark as read'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      log('[NOTIF_SCREEN] Notification already read');
    }
  }

  Future<void> _handleMarkAllAsRead(NotificationProvider provider) async {
    log('[NOTIF_SCREEN] Mark all as read tapped');
    log('[NOTIF_SCREEN] Unread count: ${provider.unreadCount}');

    if (provider.unreadCount == 0) {
      log('[NOTIF_SCREEN] No unread notifications');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No unread notifications'),
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark All as Read'),
        content: Text(
          'Mark ${provider.unreadCount} notifications as read?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              log('[NOTIF_SCREEN] Mark all cancelled');
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              log('[NOTIF_SCREEN] Mark all confirmed');
              Navigator.of(context).pop(true);
            },
            child: const Text('Mark All'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      log('[NOTIF_SCREEN] Executing mark all as read...');
      await provider.markAllAsRead();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    log('[NOTIF_SCREEN] Building NotificationsScreen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () => _handleMarkAllAsRead(provider),
                  icon: const Icon(Icons.done_all, color: Colors.white),
                  label: const Text(
                    'Mark All Read',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              log('[NOTIF_SCREEN] Refresh button tapped');
              context.read<NotificationProvider>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          log('[NOTIF_SCREEN] Consumer rebuilding. isLoading: ${provider.isLoading}, notifications: ${provider.totalCount}');

          if (provider.isLoading) {
            log('[NOTIF_SCREEN] Showing loading indicator');
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            log('[NOTIF_SCREEN] Showing error: ${provider.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      log('[NOTIF_SCREEN] Retry button tapped');
                      provider.fetchNotifications();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            log('[NOTIF_SCREEN] No notifications to display');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          log('[NOTIF_SCREEN] Displaying ${provider.notifications.length} notifications');

          return Column(
            children: [
              // Stats header
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      'Total',
                      provider.totalCount.toString(),
                      Icons.notifications,
                      Colors.blue,
                    ),
                    _buildStatItem(
                      context,
                      'Unread',
                      provider.unreadCount.toString(),
                      Icons.mark_email_unread,
                      Colors.orange,
                    ),
                    _buildStatItem(
                      context,
                      'Read',
                      provider.readCount.toString(),
                      Icons.mark_email_read,
                      Colors.green,
                    ),
                  ],
                ),
              ),
              
              // Notifications list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () {
                    log('[NOTIF_SCREEN] Pull to refresh triggered');
                    return provider.refresh();
                  },
                  child: ListView.separated(
                    itemCount: provider.notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = provider.notifications[index];
                      log('[NOTIF_SCREEN] Building notification item $index: ${notification.id}');

                      return Dismissible(
                        key: Key(notification.id),
                        direction: notification.isRead
                            ? DismissDirection.none
                            : DismissDirection.endToStart,
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          log('[NOTIF_SCREEN] Swipe to mark as read: ${notification.id}');
                          final success = await provider.markAsRead(notification.id);
                          return false; // Don't actually dismiss
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getNotificationTypeColor(notification.type)
                                .withOpacity(0.2),
                            child: Icon(
                              _getNotificationTypeIcon(notification.type),
                              color: _getNotificationTypeColor(notification.type),
                            ),
                          ),
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                notification.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDateTime(notification.createdAt),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                          trailing: notification.isRead
                              ? Icon(
                                  Icons.check_circle,
                                  color: Colors.green[300],
                                  size: 20,
                                )
                              : Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                          tileColor: notification.isRead
                              ? null
                              : Theme.of(context).primaryColor.withOpacity(0.05),
                          onTap: () => _handleNotificationTap(notification, provider),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
