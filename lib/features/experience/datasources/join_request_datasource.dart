import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/experience_model.dart';
import '../models/join_request_model.dart';
import '../../notifications/models/app_notification_model.dart';
import '../../notifications/repositories/notification_repository.dart';
import 'experience_datasource.dart';

class JoinRequestDataSource {
  final _col = FirebaseFirestore.instance.collection('join_requests');
  final ExperienceDataSource _experienceDataSource = ExperienceDataSource();
  final NotificationRepository _notificationRepository = NotificationRepository();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  /// Looks up the requester's real display name from their profile
  /// (users/{uid}.name) rather than relying on FirebaseAuth's
  /// displayName, which is frequently null (e.g. phone/OTP sign-in).
  Future<String> _getRequesterName(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data()?['name'] as String? ?? 'Someone';
  }

  Future<void> sendRequest(Experience meetup) async {
    final existing = await _col
        .where('meetupId', isEqualTo: meetup.id)
        .where('requesterId', isEqualTo: _uid)
        .get();
    if (existing.docs.isNotEmpty) return; // already requested

    final requesterName = await _getRequesterName(_uid);

    await _col.doc().set({
      'meetupId': meetup.id,
      'requesterId': _uid,
      'requesterName': requesterName,
      'status': 'pending',
      'requestedAt': Timestamp.now(),
    });
  }

  /// Approves a join request AND adds the requester to the meetup's
  /// `participants` array + increments `joined`, atomically.
  ///
  /// This has to be a single transaction, not two separate writes:
  /// - If the app crashed between "flip status" and "add participant",
  ///   you'd get a request marked "approved" with no matching
  ///   participant — the requester would be approved but still locked
  ///   out of the group chat, and the joined/seats counter would be
  ///   permanently wrong with no error anywhere to explain why.
  /// - Reading + checking status/capacity inside the transaction (rather
  ///   than before it) protects against two concurrent approvals (e.g.
  ///   a double-tap, or two organizer sessions) double-counting the
  ///   same requester or approving past capacity.
  ///
  /// Throws a [StateError] if the meetup is already full. Callers
  /// (JoinRequestsController) should catch this and surface it to the
  /// organizer rather than letting it fail silently.
  ///
  /// On success, sends a "request approved" notification to the
  /// requester. The notification write happens AFTER the transaction
  /// commits, not inside it — Firestore transactions can retry, and a
  /// notification is a side effect we only want to happen once, on
  /// confirmed success. It's a best-effort follow-up write: if it fails,
  /// the approval itself has already succeeded and isn't rolled back.
  Future<void> approve(String requestId) async {
    final requestRef = _col.doc(requestId);
    String? requesterId;
    String? meetupTitle;

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final requestSnap = await txn.get(requestRef);
      if (!requestSnap.exists) {
        throw StateError('Join request not found.');
      }

      final requestData = requestSnap.data()!;
      final currentStatus = requestData['status'] as String?;

      // Already handled (approved/rejected/cancelled) — do nothing.
      // Prevents double-increment if approve() is triggered twice for
      // the same request (double-tap, retry after a slow network, or
      // a race between two organizer sessions).
      if (currentStatus != 'pending') return;

      final meetupId = requestData['meetupId'] as String;
      requesterId = requestData['requesterId'] as String;
      final meetupRef = _experienceDataSource.meetupDocRef(meetupId);

      final meetupSnap = await txn.get(meetupRef);
      if (!meetupSnap.exists) {
        throw StateError('This meetup no longer exists.');
      }

      final meetupData = meetupSnap.data()!;
      meetupTitle = meetupData['title'] as String? ?? 'the meetup';
      final int seats = (meetupData['seats'] ?? 0) as int;
      final int joined = (meetupData['joined'] ?? 0) as int;
      final List participants =
          List.from(meetupData['participants'] ?? const []);

      if (participants.contains(requesterId)) {
        // Already a participant somehow (e.g. re-approving after a
        // previous partial failure) — just settle the status, don't
        // double add or double increment.
        txn.update(requestRef, {'status': 'approved'});
        return;
      }

      if (joined >= seats) {
        throw StateError('This meetup is already full.');
      }

      txn.update(requestRef, {'status': 'approved'});
      txn.update(meetupRef, {
        'participants': FieldValue.arrayUnion([requesterId]),
        'joined': joined + 1,
      });
    });

    if (requesterId != null) {
      await _notificationRepository.create(
        userId: requesterId!,
        type: NotificationType.requestApproved,
        title: 'Request approved 🎉',
        body: 'Your request to join "${meetupTitle ?? 'the meetup'}" was approved.',
        relatedId: requestId,
      );
    }
  }

  /// Rejects a join request and notifies the requester.
  Future<void> reject(String requestId) async {
    final requestSnap = await _col.doc(requestId).get();
    if (!requestSnap.exists) return;

    final requestData = requestSnap.data()!;
    final requesterId = requestData['requesterId'] as String?;
    final meetupId = requestData['meetupId'] as String?;

    await _col.doc(requestId).update({'status': 'rejected'});

    if (requesterId == null) return;

    String meetupTitle = 'the meetup';
    if (meetupId != null) {
      final meetup = await _experienceDataSource.getMeetupById(meetupId);
      if (meetup != null) meetupTitle = meetup.title;
    }

    await _notificationRepository.create(
      userId: requesterId,
      type: NotificationType.requestRejected,
      title: 'Request declined',
      body: 'Your request to join "$meetupTitle" was declined.',
      relatedId: requestId,
    );
  }

  Future<void> cancel(String requestId) =>
      _col.doc(requestId).update({'status': 'cancelled'});

  /// Requests I've personally sent (any meetup).
  Future<List<JoinRequest>> getMyRequests() async {
    final snap = await _col.where('requesterId', isEqualTo: _uid).get();
    final List<JoinRequest> results = [];
    for (final doc in snap.docs) {
      final data = doc.data();
      final meetup = await _experienceDataSource.getMeetupById(data['meetupId']);
      if (meetup == null) continue;
      results.add(JoinRequest.fromMap(doc.id, data, meetup, _uid));
    }
    return results;
  }

  /// All requests (any status) for one specific meetup — used to build
  /// the "incoming" side for meetups I created.
  Future<List<JoinRequest>> getRequestsForMeetup(Experience meetup) async {
    final snap = await _col.where('meetupId', isEqualTo: meetup.id).get();
    return snap.docs
        .map((d) => JoinRequest.fromMap(d.id, d.data(), meetup, _uid))
        .toList();
  }
}
