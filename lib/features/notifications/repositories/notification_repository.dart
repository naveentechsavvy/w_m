import '../datasources/notification_datasource.dart';
import '../models/app_notification_model.dart';

class NotificationRepository {
  final NotificationDataSource dataSource = NotificationDataSource();

  Future<List<AppNotification>> getForUser(String uid) =>
      dataSource.getForUser(uid);

  Future<void> markAsRead(String id) => dataSource.markAsRead(id);

  Future<void> markAllAsRead(String uid) => dataSource.markAllAsRead(uid);
}