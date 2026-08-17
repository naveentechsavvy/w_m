import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads the single app-wide "is Premium enabled" switch from Firestore,
/// separate from any individual user's subscription status
/// (SubscriptionController). This is an admin-controlled kill switch:
/// flip `premiumEnabled` in Firestore Console at app_config/feature and
/// every user's app picks it up automatically, no rebuild required.
///
/// Uses a live snapshot stream (not a one-time get) so toggling the
/// flag in Firebase Console takes effect immediately for anyone with
/// the app open, not just on next cold start.
class AppConfigDataSource {
  final _doc =
      FirebaseFirestore.instance.collection('app_config').doc('feature');

  /// Defaults to `true` (Premium visible) if the doc/field doesn't
  /// exist yet — so nothing silently breaks before the
  /// app_config/feature document exists in Firestore Console. Once the
  /// doc exists, its actual value takes over.
  Stream<bool> streamPremiumEnabled() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists) return true;
      final data = snap.data();
      return data?['premiumEnabled'] as bool? ?? true;
    });
  }
}
