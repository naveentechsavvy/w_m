import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'experience_model.dart';

enum JoinRequestStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

extension JoinRequestStatusX on JoinRequestStatus {
  String get label {
    switch (this) {
      case JoinRequestStatus.pending:
        return "Pending";
      case JoinRequestStatus.approved:
        return "Approved";
      case JoinRequestStatus.rejected:
        return "Rejected";
      case JoinRequestStatus.cancelled:
        return "Cancelled";
    }
  }

  Color get color {
    switch (this) {
      case JoinRequestStatus.pending:
        return const Color(0xFFFFA000);
      case JoinRequestStatus.approved:
        return const Color(0xFF2E7D32);
      case JoinRequestStatus.rejected:
        return const Color(0xFFD32F2F);
      case JoinRequestStatus.cancelled:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Represents a single join request between a requester and a meetup.
///
/// [isMine] tells the UI which "side" this request should render on:
/// - true  -> a request YOU sent to join someone else's meetup
///            (shown under My Meetups -> Joined/Upcoming/Completed/Cancelled)
/// - false -> a request someone else sent to join YOUR meetup
///            (shown under Join Requests -> Pending, with Approve/Reject)
///
/// Backed by Firestore collection `join_requests`. Only `meetupId` is
/// stored on the document — the full [Experience] is reattached when
/// reading, via ExperienceDataSource, to avoid duplicated/stale data.
class JoinRequest {
  final String id;
  final Experience meetup;
  final String requesterId;
  final String requesterName;
  JoinRequestStatus status;
  final DateTime requestedAt;
  final bool isMine;

  JoinRequest({
    required this.id,
    required this.meetup,
    required this.requesterId,
    required this.requesterName,
    required this.status,
    required this.requestedAt,
    required this.isMine,
  });

  Map<String, dynamic> toMap() {
    return {
      'meetupId': meetup.id,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'status': status.name,
      'requestedAt': Timestamp.fromDate(requestedAt),
    };
  }

  factory JoinRequest.fromMap(
    String id,
    Map<String, dynamic> map,
    Experience meetup,
    String currentUid,
  ) {
    return JoinRequest(
      id: id,
      meetup: meetup,
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      status: JoinRequestStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => JoinRequestStatus.pending,
      ),
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      isMine: map['requesterId'] == currentUid,
    );
  }
}