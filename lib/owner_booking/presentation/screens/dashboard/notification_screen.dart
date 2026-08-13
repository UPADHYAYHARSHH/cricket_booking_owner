import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/notification/notification_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/notification/notification_state.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      context.read<NotificationCubit>().fetchNotifications(userId);
    }
  }

  _NotificationConfig _getNotificationConfig(String? type) {
    switch (type) {
      case 'location_approved':
        return _NotificationConfig(
          icon: HugeIcons.strokeRoundedCheckmarkBadge01,
          color: AppColors.primaryDarkGreen,
        );
      case 'location_rejected':
        return _NotificationConfig(
          icon: HugeIcons.strokeRoundedCancel01,
          color: Colors.red,
        );
      case 'booking_checked_in':
        return _NotificationConfig(
          icon: HugeIcons.strokeRoundedQrCode01,
          color: Colors.blue,
        );
      case 'booking_confirmed':
        return _NotificationConfig(
          icon: HugeIcons.strokeRoundedCalendar01,
          color: AppColors.primaryDarkGreen,
        );
      case 'booking_cancelled':
        return _NotificationConfig(
          icon: HugeIcons.strokeRoundedCalendar01,
          color: Colors.red,
        );
      case 'payment_received':
        return _NotificationConfig(
          icon: HugeIcons.strokeRoundedCreditCard,
          color: AppColors.goldenYellow,
        );
      case 'announcement':
      case 'promotion':
        return _NotificationConfig(
          icon: HugeIcons.strokeRoundedMegaphone01,
          color: Colors.purple.shade600,
        );
      default:
        return _NotificationConfig(
          icon: HugeIcons.strokeRoundedNotification01,
          color: AppColors.primaryDarkGreen,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDarkGreen,
        title: const AppText(
          text: 'Notifications',
          color: AppColors.white,
          size: 20,
          weight: FontWeight.w600,
        ),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state is! NotificationLoaded || state.notifications.isEmpty) {
                return const SizedBox();
              }

              return PopupMenuButton<String>(
                onSelected: (value) {
                  final userId = FirebaseAuth.instance.currentUser?.uid;
                  if (userId != null) {
                    if (value == 'mark_read') {
                      context.read<NotificationCubit>().markAllAsRead(userId);
                    } else if (value == 'clear_all') {
                      context.read<NotificationCubit>().deleteAllNotifications(userId);
                    }
                  }
                },
                icon: const Icon(Icons.more_vert, color: AppColors.white),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 20),
                        SizedBox(width: 12),
                        Text("Mark all as read"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep,
                            size: 20, color: AppColors.error),
                        SizedBox(width: 12),
                        Text("Clear all",
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationError) {
            return Center(child: Text(state.message));
          }
          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: AppColors.textSecondaryLight.withValues(alpha:0.4),
                    ),
                    const SizedBox(height: 16),
                    const AppText(
                      text: 'No notifications yet',
                      size: 16,
                      color: AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadNotifications(),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSizes.md),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  final isRead = notification['is_read'] == true;
                  final type = notification['type'] as String?;
                  final createdAt = DateTime.tryParse(notification['created_at'] ?? '');

                  return Dismissible(
                    key: Key(notification['id'].toString()),
                    direction: DismissDirection.horizontal,
                    background: _buildSwipeBackground(context,
                        alignment: Alignment.centerLeft,
                        color: AppColors.primaryDarkGreen,
                        icon: Icons.done,
                        label: "Read"),
                    secondaryBackground: _buildSwipeBackground(context,
                        alignment: Alignment.centerRight,
                        color: AppColors.error,
                        icon: Icons.delete_outline,
                        label: "Delete"),
                    confirmDismiss: (direction) async {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId != null) {
                        if (direction == DismissDirection.startToEnd) {
                          context.read<NotificationCubit>().markAsRead(
                                notification['id'].toString(),
                                userId,
                              );
                          return false; // Don't actually dismiss the item, let Cubit refresh it
                        } else if (direction == DismissDirection.endToStart) {
                          context.read<NotificationCubit>().deleteNotification(
                                notification['id'].toString(),
                                userId,
                              );
                          return true;
                        }
                      }
                      return false;
                    },
                    child: Builder(
                      builder: (context) {
                        final config = _getNotificationConfig(type);
                        final theme = Theme.of(context);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: !isRead
                                ? config.color.withOpacity(
                                    theme.brightness == Brightness.dark ? 0.15 : 0.08)
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: !isRead
                                  ? config.color.withOpacity(0.2)
                                  : theme.dividerColor.withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              if (isRead)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: config.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: HugeIcon(
                                  icon: config.icon,
                                  color: config.color,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: AppText(
                                            text: notification['title'] ?? 'Notification',
                                            size: 15,
                                            weight: !isRead ? FontWeight.w800 : FontWeight.w600,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        if (createdAt != null)
                                          AppText(
                                            text: _formatTime(createdAt),
                                            size: 11,
                                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    AppText(
                                      text: notification['message'] ?? '',
                                      size: 13,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(!isRead ? 0.9 : 0.6),
                                      weight: !isRead ? FontWeight.w500 : FontWeight.w400,
                                    ),
                                  ],
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  margin: const EdgeInsets.only(left: 12, top: 4),
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: config.color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: config.color.withOpacity(0.4),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      }
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  Widget _buildSwipeBackground(BuildContext context,
      {required Alignment alignment,
      required Color color,
      required IconData icon,
      required String label}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _NotificationConfig {
  final dynamic icon;
  final Color color;

  _NotificationConfig({required this.icon, required this.color});
}
