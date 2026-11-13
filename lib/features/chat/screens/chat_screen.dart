import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/chat_controller.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  String _formatTime(DateTime dt) {
    final hour24 = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:$minute $period';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _showMessageActions(
    BuildContext context,
    ChatController controller,
    Message message,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined,
                    color: AppColors.textPrimary),
                title: const Text('Edit message'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  controller.startEdit(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title:
                    const Text('Delete message', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmDelete(context, controller, message);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Organizer-only sheet for someone else's message: remove it, or
  /// mute the person who sent it. Separate from _showMessageActions
  /// above so a regular member long-pressing someone else's message
  /// (canAct == false in that case) never sees this.
  void _showOrganizerActions(
    BuildContext context,
    ChatController controller,
    Message message,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove message',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmModerateDelete(context, controller, message);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.volume_off, color: AppColors.textPrimary),
                title: Text('Mute ${message.senderName}'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showMuteDurationPicker(context, controller, message.senderId,
                      message.senderName);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmModerateDelete(
    BuildContext context,
    ChatController controller,
    Message message,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove this message?'),
          content: const Text(
            'This removes it for everyone in the chat. This can\'t be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                controller.moderateDeleteMessage(message);
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    ChatController controller,
    Message message,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete message?'),
          content: const Text(
            'This can\'t be undone. The message will be removed for everyone in this chat.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                controller.deleteMessage(message);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showMuteDurationPicker(
    BuildContext context,
    ChatController controller,
    String userId,
    String userName,
  ) {
    final options = <String, Duration>{
      '15 minutes': const Duration(minutes: 15),
      '1 hour': const Duration(hours: 1),
      '24 hours': const Duration(hours: 24),
      '7 days': const Duration(days: 7),
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Mute $userName for...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...options.entries.map(
                (entry) => ListTile(
                  title: Text(entry.key),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    controller.muteMember(userId, entry.value);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final map = args is Map ? args : <String, dynamic>{};
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final roomId = ChatController.resolveRoomId(map, uid);
    final controller = Get.find<ChatController>(tag: roomId);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          controller.displayTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
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
                return EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: controller.chatType == ChatType.group
                      ? "No messages yet. Say hi to the group!"
                      : "No messages yet. Say hi!",
                );
              }

              _scrollToBottom();

              final showSenderLabel = controller.chatType == ChatType.group;

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final Message message = messages[index];
                  final bool isMine =
                      message.senderId == controller.currentUid;
                  final bool canAct =
                      !message.isDeleted && controller.canEditOrDelete(message);
                  // Organizer can act on anyone ELSE's message (their own
                  // is already covered by canAct above via the normal
                  // edit/delete sheet).
                  final bool canModerate = !isMine &&
                      !message.isDeleted &&
                      controller.isOrganizer;

                  final bubble = Container(
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
                        if (showSenderLabel)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message.senderName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color:
                                    isMine ? Colors.white70 : AppColors.primary,
                              ),
                            ),
                          ),
                        Text(
                          message.isDeleted
                              ? 'This message was deleted'
                              : message.text,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: message.isDeleted
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: message.isDeleted
                                ? (isMine
                                    ? Colors.white70
                                    : AppColors.textSecondary)
                                : (isMine
                                    ? Colors.white
                                    : AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (message.isEdited && !message.isDeleted) ...[
                                Text(
                                  'edited',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                    color: isMine
                                        ? Colors.white70
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                _formatTime(message.sentAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMine
                                      ? Colors.white70
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );

                  return Align(
                    alignment:
                        isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: canAct
                        ? GestureDetector(
                            onLongPress: () => _showMessageActions(
                              context,
                              controller,
                              message,
                            ),
                            child: bubble,
                          )
                        : (canModerate
                            ? GestureDetector(
                                onLongPress: () => _showOrganizerActions(
                                  context,
                                  controller,
                                  message,
                                ),
                                child: bubble,
                              )
                            : bubble),
                  );
                },
              );
            }),
          ),
          Obx(() {
            final editing = controller.editingMessage.value;
            if (editing == null) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              color: AppColors.primary.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Editing message',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: controller.cancelEdit,
                    child: const Icon(Icons.close,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }),
          Obx(() {
            final until = controller.mutedUntil.value;
            if (until == null || !until.isAfter(DateTime.now())) {
              return const SizedBox.shrink();
            }
            return Container(
              width: double.infinity,
              color: Colors.red.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.volume_off, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are muted until ${_formatTime(until)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Obx(() {
                final muted = controller.isMuted;
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.textController,
                        enabled: !muted,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => controller.send(),
                        decoration: InputDecoration(
                          hintText:
                              muted ? "You're muted" : "Type a message...",
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
                        color: muted ? Colors.grey : AppColors.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: (controller.isSending.value || muted)
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
                                : Icon(
                                    controller.editingMessage.value != null
                                        ? Icons.check
                                        : Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}