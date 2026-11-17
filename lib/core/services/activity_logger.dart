import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Allowed values for `activities.type` (read by the admin website).
abstract class ActivityType {
  static const meetupJoined = 'meetup_joined';
  static const eventJoined = 'event_joined';
  static const foodOrdered = 'food_ordered';
  static const profileUpdated = 'profile_updated';
  static const other = 'other';

  static const all = {meetupJoined, eventJoined, foodOrdered, profileUpdated, other};
}

/// Best-effort write to the `activities` collection for the admin
/// website. Fire-and-forget: returns immediately, never throws, never
/// blocks the UI. Any failure (rules, network) is only logged.
///
/// Fields written: userId, userName, type, title, meetupId (only if
/// set), timestamp (server time). Nothing else.
void logActivity({
  required String userId,
  required String userName,
  required String type,
  required String title,
  String? meetupId,
}) {
  if (userId.isEmpty) return;
  final safeType = ActivityType.all.contains(type) ? type : ActivityType.other;
  final safeTitle = title.length > 200 ? title.substring(0, 200) : title;

  final data = <String, dynamic>{
    'userId': userId,
    'userName': userName,
    'type': safeType,
    'title': safeTitle,
    if (meetupId != null && meetupId.isNotEmpty) 'meetupId': meetupId,
    'timestamp': FieldValue.serverTimestamp(),
  };

  try {
    FirebaseFirestore.instance
        .collection('activities')
        .add(data)
        .catchError((Object e) {
      debugPrint('[Activity] Could not log "$safeType": $e');
      return FirebaseFirestore.instance.collection('activities').doc();
    });
  } catch (e) {
    debugPrint('[Activity] Could not log "$safeType": $e');
  }
}

/// Looks up users/{uid}.name for activity logs; falls back to
/// [fallback] on any error. Used only where the name isn't already known.
Future<String> activityUserName(String uid, {String fallback = 'User'}) async {
  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final name = doc.data()?['name'];
    return (name is String && name.trim().isNotEmpty) ? name.trim() : fallback;
  } catch (_) {
    return fallback;
  }
}
