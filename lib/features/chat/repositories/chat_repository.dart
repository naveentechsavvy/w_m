import '../datasources/chat_datasource.dart';
import '../models/message_model.dart';

class ChatRepository {
  final ChatDataSource datasource = ChatDataSource();

  /// Deterministic room id for a 1:1 (private/organizer) thread.
  /// Exposed here so callers (controller) don't need to reach into the
  /// datasource layer directly.
  static String buildDirectRoomId({
    required String meetupId,
    required String uidA,
    required String uidB,
  }) =>
      ChatDataSource.buildDirectRoomId(
        meetupId: meetupId,
        uidA: uidA,
        uidB: uidB,
      );

  Stream<List<Message>> streamMessages({
    required String roomId,
    required ChatType chatType,
    required String currentUid,
  }) =>
      datasource.streamMessages(
        roomId: roomId,
        chatType: chatType,
        currentUid: currentUid,
      );

  Future<void> sendMessage({
    required String roomId,
    required String meetupId,
    required ChatType chatType,
    required String senderName,
    required String text,
    String? otherUserId,
  }) =>
      datasource.sendMessage(
        roomId: roomId,
        meetupId: meetupId,
        chatType: chatType,
        senderName: senderName,
        text: text,
        otherUserId: otherUserId,
      );

  Future<void> editMessage({
    required String messageId,
    required String newText,
  }) =>
      datasource.editMessage(messageId: messageId, newText: newText);

  Future<void> deleteMessage(String messageId) =>
      datasource.deleteMessage(messageId);
}