import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/colors.dart';
import '../controllers/friend_request_controller.dart';

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
              final friends = controller.friendsWithNames;

              if (friends.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      "No friends yet. Add friends from a meetup's participants list!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadFriends,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final f = friends[index];
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
                              f.senderName.isNotEmpty
                                  ? f.senderName[0].toUpperCase()
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
                            child: Text(
                              f.senderName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _confirmRemove(f.request.id, f.senderName),
                            icon: const Icon(
                              Icons.person_remove_outlined,
                              color: Colors.red,
                            ),
                            tooltip: "Remove Friend",
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
    );
  }
}