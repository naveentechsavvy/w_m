import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/colors.dart';
import '../controllers/friend_request_controller.dart';
import '../models/friend_request_model.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late final FriendRequestController controller;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<FriendRequestController>()
        ? Get.find<FriendRequestController>()
        : Get.put(FriendRequestController());
    _load();
  }

  Future<void> _load() async {
    await controller.loadFriends();
    if (!mounted) return;
    setState(() => loading = false);
  }

  /// The other person's uid in a friend request — whichever of
  /// senderId/receiverId isn't the signed-in user, since either side
  /// could have sent the original request.
  String? _peerIdOf(FriendRequestWithSender f) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return null;
    final req = f.request;
    return req.senderId == myUid ? req.receiverId : req.senderId;
  }

  Future<void> _confirmRemove(String requestId, String name) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Remove Friend"),
        content: Text("Remove $name from your friends list?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              "Remove",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await controller.removeFriend(requestId);

    Get.snackbar(
      "Friend Removed",
      "$name has been removed from your friends.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Friends",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Obx(() {
              final allFriends = controller.friendsWithNames;

              if (allFriends.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          "No friends yet",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Add friends from a meetup's participants list!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final sorted = [...allFriends]
                ..sort((a, b) =>
                    a.senderName.toLowerCase().compareTo(b.senderName.toLowerCase()));

              return RefreshIndicator(
                onRefresh: controller.loadFriends,
                child: Column(
                  children: [
                    // ------------------------------------------------
                    // FRIEND COUNT
                    // ------------------------------------------------
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                      child: Row(
                        children: [
                          Text(
                            "${allFriends.length} friend${allFriends.length == 1 ? '' : 's'}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ------------------------------------------------
                    // LIST
                    // ------------------------------------------------
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          final f = sorted[index];
                          return _FriendTile(
                            name: f.senderName,
                            onChat: () {
                              final peerId = _peerIdOf(f);
                              if (peerId == null) return;
                              Get.toNamed(
                                AppRoutes.chat,
                                arguments: {
                                  'chatType': 'private',
                                  'meetupId': 'friends',
                                  'meetupTitle': '',
                                  'otherUserId': peerId,
                                  'otherUserName': f.senderName,
                                },
                              );
                            },
                            onRemove: () =>
                                _confirmRemove(f.request.id, f.senderName),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final String name;
  final VoidCallback onChat;
  final VoidCallback onRemove;

  const _FriendTile({
    required this.name,
    required this.onChat,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryTint,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "?",
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Primary action — filled circle, stands out as the main CTA
          _CircleIconButton(
            icon: Icons.chat_bubble_rounded,
            iconColor: Colors.white,
            backgroundColor: AppColors.primary,
            tooltip: "Message",
            onTap: onChat,
          ),
          const SizedBox(width: 10),
          // Secondary / destructive action — neutral outline, visually quieter
          _CircleIconButton(
            icon: Icons.person_remove_outlined,
            iconColor: Colors.grey.shade600,
            backgroundColor: Colors.grey.shade100,
            tooltip: "Remove Friend",
            onTap: onRemove,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ),
      ),
    );
  }
}