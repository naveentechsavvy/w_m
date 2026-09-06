import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_request_model.dart';

class FriendRequestDatasource {
  final _col = FirebaseFirestore.instance.collection('friend_requests');

  Future<void> sendRequest(String senderId, String receiverId) async {
    await _col.add({
      'senderId': senderId,
      'receiverId': receiverId,
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> updateStatus(String requestId, FriendRequestStatus status) async {
    await _col.doc(requestId).update({'status': status.name});
  }

  /// Deletes the underlying friend_requests document entirely — used
  /// for "Remove Friend". Deleting (rather than setting status back
  /// to e.g. "rejected") means if the two people become friends again
  /// later, sendRequest() creates a clean new document instead of a
  /// stale accepted-then-rejected one lingering around.
  Future<void> deleteRequest(String requestId) async {
    await _col.doc(requestId).delete();
  }

  Stream<List<FriendRequest>> watchSentByMe(String uid) {
    return _col
        .where('senderId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => FriendRequest.fromDoc(d)).toList());
  }

  /// Watches ALL requests received by this user, regardless of status.
  /// Do NOT filter by status here — loadFriends() in the controller
  /// needs to see accepted requests too (to build the friends list),
  /// and _resolveSenderNames() already filters for pending on its own.
  ///
  /// Previously this query included `.where('status', isEqualTo:
  /// 'pending')`. That meant the instant a received request was
  /// accepted, it stopped matching the query and silently disappeared
  /// from receivedRequests — so an accepted friendship could never be
  /// reconstructed on the receiving side, and that user's own Friends
  /// list would never show that friend (even though the sender's side
  /// worked fine, since sentRequests has no such filter).
  Stream<List<FriendRequest>> watchReceivedByMe(String uid) {
    return _col
        .where('receiverId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => FriendRequest.fromDoc(d)).toList());
  }
}
