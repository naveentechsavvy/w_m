import '../../experience/models/join_request_model.dart';
import '../../friends/models/friend_request_model.dart';
import 'app_notification_model.dart';

class NotificationFeedItem {
  final JoinRequest? joinRequest;
  final AppNotification? notification;
  final FriendRequestWithSender? friendRequest;

  NotificationFeedItem.request(JoinRequest request)
      : joinRequest = request,
        notification = null,
        friendRequest = null;

  NotificationFeedItem.info(AppNotification info)
      : joinRequest = null,
        notification = info,
        friendRequest = null;

  NotificationFeedItem.friend(FriendRequestWithSender request)
      : joinRequest = null,
        notification = null,
        friendRequest = request;

  bool get isJoinRequest => joinRequest != null;
  bool get isFriendRequest => friendRequest != null;

  DateTime get time {
    if (isJoinRequest) return joinRequest!.requestedAt;
    if (isFriendRequest) return friendRequest!.request.createdAt;
    return notification!.createdAt;
  }
}