import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/colors.dart';
import '../../friends/controllers/friend_request_controller.dart';
import '../models/experience_model.dart';
import '../repositories/experience_repository.dart';

class _ParticipantInfo {
  final String uid;
  final String name;
  _ParticipantInfo({required this.uid, required this.name});
}

class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({super.key});

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  late final FriendRequestController friendController;
  final ExperienceRepository _experienceRepository = ExperienceRepository();
  late Experience experience;

  bool loading = true;
  List<_ParticipantInfo> participants = [];

  @override
  void initState() {
    super.initState();
    experience = Get.arguments as Experience;
    friendController = Get.isRegistered<FriendRequestController>()
        ? Get.find<FriendRequestController>()
        : Get.put(FriendRequestController());
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    final fresh = await _experienceRepository.getMeetupById(experience.id);
    if (fresh != null) {
      experience = fresh;
    }

    // The organizer doesn't always end up inside experience.participants
    // (they created the meetup, they didn't "join" it) — so we merge
    // createdBy in here explicitly. Without this, an organizer who never
    // separately joined their own meetup simply never appears in the
    // list, no matter what the sort logic below does.
    final uids = {
      experience.createdBy,
      ...experience.participants,
    }.toList();

    if (uids.isEmpty) {
      if (!mounted) return;
      setState(() {
        participants = [];
        loading = false;
      });
      return;
    }

    final List<_ParticipantInfo> resolved = [];
    for (int i = 0; i < uids.length; i += 10) {
      final chunk = uids.sublist(
        i,
        i + 10 > uids.length ? uids.length : i + 10,
      );
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        resolved.add(_ParticipantInfo(
          uid: doc.id,
          name: (doc.data()['name'] ?? 'Unknown User') as String,
        ));
      }
    }

    // Organizer always shows first, everyone else keeps their
    // original (Firestore query) order after that.
    resolved.sort((a, b) {
      final aIsOrganizer = a.uid == experience.createdBy;
      final bIsOrganizer = b.uid == experience.createdBy;
      if (aIsOrganizer && !bIsOrganizer) return -1;
      if (!aIsOrganizer && bIsOrganizer) return 1;
      return 0;
    });

    if (!mounted) return;
    setState(() {
      participants = resolved;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Participants",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : participants.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      "No one has joined yet.",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final p = participants[index];
                    final isSelf = p.uid == myUid;
                    final isOrganizer = p.uid == experience.createdBy;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 6,
                            color: Colors.black12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryTint,
                            child: Text(
                              p.name.isNotEmpty
                                  ? p.name[0].toUpperCase()
                                  : "?",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (isOrganizer) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      "Organizer",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Own row never needs the Obx wrapper (see
                          // note in _relationAction below), but still
                          // renders normally otherwise — including
                          // for the organizer, who gets both the
                          // badge above and an Add Friend button here
                          // when someone else views this list.
                          if (isSelf)
                            const SizedBox.shrink()
                          else
                            Obx(() => _relationAction(
                                  relation: friendController
                                      .relationshipWith(p.uid),
                                  onSendRequest: () =>
                                      friendController.sendRequest(p.uid),
                                )),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _relationAction({
    required FriendRelation relation,
    required VoidCallback onSendRequest,
  }) {
    switch (relation) {
      case FriendRelation.self:
        return const SizedBox.shrink();

      case FriendRelation.friends:
        return const Chip(
          label: Text("Friends", style: TextStyle(fontSize: 12)),
          backgroundColor: AppColors.primaryTint,
          visualDensity: VisualDensity.compact,
        );

      case FriendRelation.requestSentPending:
        return const Chip(
          label: Text("Request Sent", style: TextStyle(fontSize: 12)),
          backgroundColor: Color(0xFFF0F0F0),
          visualDensity: VisualDensity.compact,
        );

      case FriendRelation.requestReceivedPending:
        return const Chip(
          label: Text("Respond in Notifications",
              style: TextStyle(fontSize: 11)),
          backgroundColor: Color(0xFFFFE9DC),
          visualDensity: VisualDensity.compact,
        );

      case FriendRelation.none:
        return OutlinedButton(
          onPressed: onSendRequest,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text("Add Friend", style: TextStyle(fontSize: 12)),
        );
    }
  }
}
