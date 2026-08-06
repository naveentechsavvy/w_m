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

  Future<void> approve(String requestId) =>
      _col.doc(requestId).update({'status': 'approved'});

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