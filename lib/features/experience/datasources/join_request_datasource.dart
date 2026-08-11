import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/experience_model.dart';
import '../models/join_request_model.dart';
import 'experience_datasource.dart';

class JoinRequestDataSource {
  final _col = FirebaseFirestore.instance.collection('join_requests');
  final ExperienceDataSource _experienceDataSource = ExperienceDataSource();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> sendRequest(Experience meetup) async {
    final existing = await _col
        .where('meetupId', isEqualTo: meetup.id)
        .where('requesterId', isEqualTo: _uid)
        .get();
    if (existing.docs.isNotEmpty) return; // already requested

    await _col.doc().set({
      'meetupId': meetup.id,
      'requesterId': _uid,
      'requesterName': FirebaseAuth.instance.currentUser?.displayName ?? 'You',
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
  Future<void> approve(String requestId) async {
    final requestRef = _col.doc(requestId);

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
      final requesterId = requestData['requesterId'] as String;
      final meetupRef = _experienceDataSource.meetupDocRef(meetupId);

      final meetupSnap = await txn.get(meetupRef);
      if (!meetupSnap.exists) {
        throw StateError('This meetup no longer exists.');
      }

      final meetupData = meetupSnap.data()!;
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
  }

  Future<void> reject(String requestId) =>
      _col.doc(requestId).update({'status': 'rejected'});

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
