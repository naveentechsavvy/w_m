import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/colors.dart';
import '../controllers/chat_controller.dart';
import '../models/message_model.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Obx(
          () => Text(
            controller.displayTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (!controller.isReady.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = controller.messages;

              if (messages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      controller.chatType == ChatType.group
                          ? "No messages yet. Say hi to the group!"
                          : "No messages yet. Say hi!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }

              // Sender name label above a bubble only makes sense in
              // group chat, where more than one other participant can
              // appear in the thread. In private/organizer chat there's
              // only ever one other person, so the label is redundant
              // clutter.
              final showSenderLabel = controller.chatType == ChatType.group;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final Message message = messages[index];
                  final bool isMine =
                      message.senderId == controller.currentUid;

                  return Align(
                    alignment:
                        isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isMine ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMine ? 16 : 4),
                          bottomRight: Radius.circular(isMine ? 4 : 16),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 6,
                            color: Colors.black12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isMine && showSenderLabel)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                message.senderName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          Text(
                            message.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: isMine
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.textController,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => controller.send(),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: controller.isSending.value
                            ? null
                            : controller.send,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: controller.isSending.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
