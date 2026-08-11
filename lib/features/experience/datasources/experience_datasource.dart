import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/experience_model.dart';

class ExperienceDataSource {
  final _col = FirebaseFirestore.instance.collection('meetups');

  /// Exposes a doc reference for the 'meetups' collection so other
  /// datasources (e.g. JoinRequestDataSource) can include a meetup doc
  /// in a Firestore transaction without duplicating the collection name
  /// as a raw string in a second place.
  DocumentReference<Map<String, dynamic>> meetupDocRef(String id) =>
      _col.doc(id);

  Future<String> createMeetup(Experience experience) async {
    final docRef = _col.doc();
    await docRef.set(experience.toMap());
    return docRef.id;
  }

  Future<List<Experience>> getAllMeetups() async {
    final snap = await _col.orderBy('date').get();
    return snap.docs.map((d) => Experience.fromDoc(d)).toList();
  }

  Future<List<Experience>> getMeetupsByCreator(String uid) async {
    final snap = await _col.where('createdBy', isEqualTo: uid).get();
    return snap.docs.map((d) => Experience.fromDoc(d)).toList();
  }

  Future<Experience?> getMeetupById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Experience.fromDoc(doc);
  }

  /// Deletes a meetup doc outright. Only meant to be called for a
  /// meetup with zero joined participants (see cancelMeetup in the
  /// repository/controller for the guard) — for a meetup that already
  /// has participants, a soft "cancelled" status should be used instead
  /// so their join history isn't wiped. Not needed yet per current scope.
  Future<void> deleteMeetup(String id) async {
    await _col.doc(id).delete();
  }
}