import '../datasources/chat_datasource.dart';
import '../models/message_model.dart';

class ChatRepository {
  final ChatDataSource datasource = ChatDataSource();

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

  Future<void> muteUser({
    required String roomId,
    required String userId,
    required DateTime mutedUntil,
    required String mutedBy,
  }) =>
      datasource.muteUser(
        roomId: roomId,
        userId: userId,
        mutedUntil: mutedUntil,
        mutedBy: mutedBy,
      );

  Future<void> unmuteUser({
    required String roomId,
    required String userId,
  }) =>
      datasource.unmuteUser(roomId: roomId, userId: userId);

  Stream<DateTime?> streamMuteStatus({
    required String roomId,
    required String userId,
  }) =>
      datasource.streamMuteStatus(roomId: roomId, userId: userId);
}