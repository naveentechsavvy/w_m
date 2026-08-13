import '../datasources/notification_datasource.dart';
import '../models/app_notification_model.dart';

class NotificationRepository {
  final NotificationDataSource dataSource = NotificationDataSource();

  Future<void> create({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? relatedId,
  }) =>
      dataSource.create(
        userId: userId,
        type: type,
        title: title,
        body: body,
        relatedId: relatedId,
      );

  Future<List<AppNotification>> getForUser(String uid) =>
      dataSource.getForUser(uid);

  Future<void> markAsRead(String id) => dataSource.markAsRead(id);

  Future<void> markAllAsRead(String uid) => dataSource.markAllAsRead(uid);
}
