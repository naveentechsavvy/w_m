import '../datasources/chat_datasource.dart';
import '../models/message_model.dart';
 
class ChatRepository {
  final ChatDataSource datasource = ChatDataSource();
 
  Stream<List<Message>> streamMessages(String meetupId) =>
      datasource.streamMessages(meetupId);
 
  Future<void> sendMessage({
    required String meetupId,
    required String senderName,
    required String text,
  }) =>
      datasource.sendMessage(
        meetupId: meetupId,
        senderName: senderName,
        text: text,
      );
}
 