import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/owner_booking/data/repositories/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationCubit(this._notificationRepository) : super(NotificationInitial());

  Future<void> fetchNotifications(String userId) async {
    emit(NotificationLoading());
    try {
      final notifications = await _notificationRepository.getNotifications(userId);
      final unreadCount = await _notificationRepository.getUnreadCount(userId);
      emit(NotificationLoaded(notifications: notifications, unreadCount: unreadCount));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        final updated = currentState.notifications.map((n) {
          if (n['id'].toString() == notificationId) {
            return {...n, 'is_read': true};
          }
          return n;
        }).toList();
        emit(NotificationLoaded(notifications: updated, unreadCount: currentState.unreadCount));
      }
      await _notificationRepository.markAsRead(notificationId);
      await _fetchNotificationsSilently(userId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        final updated = currentState.notifications.map((n) => {...n, 'is_read': true}).toList();
        emit(NotificationLoaded(notifications: updated, unreadCount: 0));
      }
      await _notificationRepository.markAllAsRead(userId);
      await _fetchNotificationsSilently(userId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> deleteNotification(String notificationId, String userId) async {
    try {
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        final updated = currentState.notifications.where((n) => n['id'].toString() != notificationId).toList();
        emit(NotificationLoaded(notifications: updated, unreadCount: currentState.unreadCount));
      }
      await _notificationRepository.deleteNotification(notificationId);
      await _fetchNotificationsSilently(userId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> deleteAllNotifications(String userId) async {
    try {
      emit(NotificationLoaded(notifications: const [], unreadCount: 0));
      await _notificationRepository.deleteAllNotifications(userId);
      await _fetchNotificationsSilently(userId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _fetchNotificationsSilently(String userId) async {
    try {
      final notifications = await _notificationRepository.getNotifications(userId);
      final unreadCount = await _notificationRepository.getUnreadCount(userId);
      emit(NotificationLoaded(notifications: notifications, unreadCount: unreadCount));
    } catch (e) {
      // Don't emit error state on silent fetch failure to avoid disrupting the UI
    }
  }
}
