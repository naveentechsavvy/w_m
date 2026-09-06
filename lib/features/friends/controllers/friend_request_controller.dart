import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/friend_request_model.dart';
import '../repositories/friend_request_repository.dart';

enum FriendRelation {
  self,
  none,
  requestSentPending,
  requestReceivedPending,
  friends,
}

class FriendRequestController extends GetxController {
  final FriendRequestRepository _repo = FriendRequestRepository();

  final RxList<FriendRequest> sentRequests = <FriendRequest>[].obs;
  final RxList<FriendRequest> receivedRequests = <FriendRequest>[].obs;
  final RxList<FriendRequestWithSender> receivedWithSender =
      <FriendRequestWithSender>[].obs;
  final RxList<FriendRequestWithSender> friendsWithNames =
      <FriendRequestWithSender>[].obs;

  final Map<String, String> _nameCache = {};

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    if (_uid.isNotEmpty) {
      _repo.watchSentByMe(_uid).listen((list) => sentRequests.value = list);
      _repo.watchReceivedByMe(_uid).listen((list) async {
        receivedRequests.value = list;
        await _resolveSenderNames(list);
      });

      everAll([sentRequests, receivedRequests], (_) => loadFriends());
    }
  }

  Future<void> _resolveSenderNames(List<FriendRequest> requests) async {
    final pending = requests
        .where((r) => r.status == FriendRequestStatus.pending)
        .toList();

    final missing = pending
        .map((r) => r.senderId)
        .where((id) => !_nameCache.containsKey(id))
        .toSet()
        .toList();

    for (int i = 0; i < missing.length; i += 10) {
      final chunk = missing.sublist(
        i,
        i + 10 > missing.length ? missing.length : i + 10,
      );
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        _nameCache[doc.id] = (doc.data()['name'] ?? 'Unknown User') as String;
      }
    }

    receivedWithSender.value = pending
        .map((r) => FriendRequestWithSender(
              request: r,
              senderName: _nameCache[r.senderId] ?? 'Unknown User',
            ))
        .toList();
  }

  /// Accepted friends (from requests I sent OR received), resolved to names.
  Future<void> loadFriends() async {
    final accepted = [
      ...sentRequests.where((r) => r.status == FriendRequestStatus.accepted),
      ...receivedRequests.where((r) => r.status == FriendRequestStatus.accepted),
    ];

    final friendUids = accepted
        .map((r) => r.senderId == _uid ? r.receiverId : r.senderId)
        .toSet()
        .toList();

    if (friendUids.isEmpty) {
      friendsWithNames.value = [];
      return;
    }

    final List<FriendRequestWithSender> resolved = [];
    for (int i = 0; i < friendUids.length; i += 10) {
      final chunk = friendUids.sublist(
        i,
        i + 10 > friendUids.length ? friendUids.length : i + 10,
      );
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        final matchingRequest = accepted.firstWhere(
          (r) => r.senderId == doc.id || r.receiverId == doc.id,
        );
        resolved.add(FriendRequestWithSender(
          request: matchingRequest,
          senderName: (doc.data()['name'] ?? 'Unknown User') as String,
        ));
      }
    }
    friendsWithNames.value = resolved;
  }

  FriendRequestStatus? statusWithUser(String otherUid) {
    final match = sentRequests.firstWhereOrNull(
      (r) => r.receiverId == otherUid,
    );
    return match?.status;
  }

  /// Full two-way relationship state with another user — used by the
  /// Participants screen to decide which button/label to show (Add
  /// Friend, Request Sent, Accept Request, or Friends), unlike
  /// statusWithUser() which only ever looked at requests I sent.
  FriendRelation relationshipWith(String otherUid) {
    if (otherUid == _uid) return FriendRelation.self;

    final sent = sentRequests.firstWhereOrNull(
      (r) => r.receiverId == otherUid,
    );
    final received = receivedRequests.firstWhereOrNull(
      (r) => r.senderId == otherUid,
    );

    if (sent?.status == FriendRequestStatus.accepted ||
        received?.status == FriendRequestStatus.accepted) {
      return FriendRelation.friends;
    }
    if (received?.status == FriendRequestStatus.pending) {
      return FriendRelation.requestReceivedPending;
    }
    if (sent?.status == FriendRequestStatus.pending) {
      return FriendRelation.requestSentPending;
    }
    return FriendRelation.none;
  }

  Future<void> sendRequest(String receiverId) async {
    if (_uid.isEmpty || receiverId == _uid) return;
    await _repo.sendRequest(_uid, receiverId);
  }

  Future<void> accept(String requestId) => _repo.accept(requestId);
  Future<void> reject(String requestId) => _repo.reject(requestId);

  /// Unfriend — deletes the underlying accepted request document.
  /// The sentRequests/receivedRequests streams pick up the deletion
  /// automatically and everAll() re-runs loadFriends(), so
  /// friendsWithNames updates on its own without an extra manual
  /// refresh call here.
  Future<void> removeFriend(String requestId) => _repo.removeFriend(requestId);
}