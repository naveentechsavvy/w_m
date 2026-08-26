import '../datasources/friend_request_datasource.dart';
import '../models/friend_request_model.dart';

class FriendRequestRepository {
  final FriendRequestDatasource _datasource = FriendRequestDatasource();

  Future<void> sendRequest(String senderId, String receiverId) {
    return _datasource.sendRequest(senderId, receiverId);
  }

  Future<void> accept(String requestId) {
    return _datasource.updateStatus(requestId, FriendRequestStatus.accepted);
  }

  Future<void> reject(String requestId) {
    return _datasource.updateStatus(requestId, FriendRequestStatus.rejected);
  }

  Future<void> removeFriend(String requestId) {
    return _datasource.deleteRequest(requestId);
  }

  Stream<List<FriendRequest>> watchSentByMe(String uid) =>
      _datasource.watchSentByMe(uid);

  Stream<List<FriendRequest>> watchReceivedByMe(String uid) =>
      _datasource.watchReceivedByMe(uid);
}