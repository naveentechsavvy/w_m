import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/colors.dart';
import '../../friends/controllers/friend_request_controller.dart';
import '../../friends/models/friend_request_model.dart';

/// Shows the list of joined participants for a meetup, resolving each
/// UID to a name/photo from the `users` collection, with an Add Friend
/// button reflecting the current request status.
///
/// Firestore's whereIn supports max 10 values per query, so for
/// meetups with more than 10 participants we chunk the requests.
class ParticipantsList extends StatefulWidget {
  final List<String> participantIds;

  const ParticipantsList({super.key, required this.participantIds});

  @override
  State<ParticipantsList> createState() => _ParticipantsListState();
}

class _ParticipantsListState extends State<ParticipantsList> {
  bool loading = true;
  List<Map<String, dynamic>> participants = [];

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    if (widget.participantIds.isEmpty) {
      setState(() => loading = false);
      return;
    }

    try {
      final List<Map<String, dynamic>> resolved = [];

      for (int i = 0; i < widget.participantIds.length; i += 10) {
        final chunk = widget.participantIds.sublist(
          i,
          i + 10 > widget.participantIds.length
              ? widget.participantIds.length
              : i + 10,
        );

        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          resolved.add({
            'uid': doc.id,
            'name': data['name'] ?? 'Unknown User',
            'photoUrl': data['photoUrl'],
          });
        }
      }

      if (!mounted) return;
      setState(() {
        participants = resolved;
        loading = false;
      });
    } catch (e) {
      debugPrint("[ParticipantsList] Failed to load participants: $e");
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Widget _friendButton(String otherUid) {
    final controller = Get.find<FriendRequestController>();

    return Obx(() {
      final status = controller.statusWithUser(otherUid);

      String label;
      VoidCallback? onTap;
      Color color;

      if (status == FriendRequestStatus.accepted) {
        label = "Friends";
        onTap = null;
        color = AppColors.textLight;
      } else if (status == FriendRequestStatus.pending) {
        label = "Requested";
        onTap = null;
        color = AppColors.textLight;
      } else {
        label = "Add Friend";
        onTap = () => controller.sendRequest(otherUid);
        color = AppColors.primary;
      }

      return TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (participants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          "No one has joined yet.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: participants.map((p) {
        final String uid = p['uid'] as String;
        final String name = p['name'] as String;
        final String? photoUrl = p['photoUrl'] as String?;
        final bool isMe = uid == _currentUid;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryTint,
                backgroundImage:
                    (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? const Icon(Icons.person,
                        color: AppColors.primary, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isMe ? "$name (You)" : name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (!isMe) _friendButton(uid),
            ],
          ),
        );
      }).toList(),
    );
  }
}