import '../../experience/models/join_request_model.dart';
import 'app_notification_model.dart';

class NotificationFeedItem {
  final JoinRequest? joinRequest;
  final AppNotification? notification;

  NotificationFeedItem.request(JoinRequest request)
      : joinRequest = request,
        notification = null;

  NotificationFeedItem.info(AppNotification info)
      : joinRequest = null,
        notification = info;

  bool get isJoinRequest => joinRequest != null;

  DateTime get time => isJoinRequest ? joinRequest!.requestedAt : notification!.createdAt;
}