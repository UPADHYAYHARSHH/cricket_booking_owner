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
      await _notificationRepository.markAsRead(notificationId);
      await fetchNotifications(userId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationRepository.markAllAsRead(userId);
      await fetchNotifications(userId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> deleteNotification(String notificationId, String userId) async {
    try {
      await _notificationRepository.deleteNotification(notificationId);
      await fetchNotifications(userId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _notificationRepository.deleteAllNotifications(userId);
      await fetchNotifications(userId);
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }
}
