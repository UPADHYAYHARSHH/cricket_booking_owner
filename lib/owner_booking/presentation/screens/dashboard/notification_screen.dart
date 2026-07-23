import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  IconData _iconForType(String? type) {
    switch (type) {
      case 'location_approved':
        return Icons.check_circle_outline;
      case 'location_rejected':
        return Icons.cancel_outlined;
      case 'booking_checked_in':
        return Icons.qr_code_scanner;
      case 'booking_confirmed':
        return Icons.event_available_outlined;
      case 'booking_cancelled':
        return Icons.event_busy_outlined;
      case 'payment_received':
        return Icons.payments_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'location_approved':
        return AppColors.primaryDarkGreen;
      case 'location_rejected':
        return Colors.red;
      case 'booking_checked_in':
        return Colors.blue;
      case 'booking_confirmed':
        return AppColors.primaryDarkGreen;
      case 'booking_cancelled':
        return Colors.red;
      case 'payment_received':
        return AppColors.goldenYellow;
      default:
        return AppColors.textSecondaryLight;
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
          TextButton(
            onPressed: () {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                context.read<NotificationCubit>().markAllAsRead(userId);
              }
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(color: AppColors.white, fontSize: 13),
            ),
          ),
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
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId != null) {
                        context.read<NotificationCubit>().markAsRead(
                          notification['id'].toString(),
                          userId,
                        );
                      }
                      return false;
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isRead
                            ? AppColors.white
                            : AppColors.primaryDarkGreen.withValues(alpha:0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRead
                              ? AppColors.borderLight
                              : AppColors.primaryDarkGreen.withValues(alpha:0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _colorForType(type).withValues(alpha:0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _iconForType(type),
                              size: 20,
                              color: _colorForType(type),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppText(
                                        text: notification['title'] ?? 'Notification',
                                        size: 14,
                                        weight: isRead ? FontWeight.w500 : FontWeight.w700,
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryDarkGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                AppText(
                                  text: notification['message'] ?? '',
                                  size: 13,
                                  color: AppColors.textSecondaryLight,
                                ),
                                if (createdAt != null) ...[
                                  const SizedBox(height: 6),
                                  AppText(
                                    text: _formatTime(createdAt),
                                    size: 11,
                                    color: AppColors.textSecondaryLight.withValues(alpha:0.7),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
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
}
