import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus { pending, accepted, rejected }

class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FriendRequest.fromMap(String id, Map<String, dynamic> map) {
    return FriendRequest(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory FriendRequest.fromDoc(DocumentSnapshot doc) {
    return FriendRequest.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}

/// Pairs a FriendRequest with the resolved display name of the sender,
/// so the Notifications feed can show it without a separate lookup.
class FriendRequestWithSender {
  final FriendRequest request;
  final String senderName;

  FriendRequestWithSender({required this.request, required this.senderName});
}