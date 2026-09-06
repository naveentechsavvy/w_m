import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments;
    final map = args is Map ? args : <String, dynamic>{};
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final roomId = ChatController.resolveRoomId(map, uid);

    // fenix: true means Get recreates the controller if this tag was
    // previously disposed (e.g. user left and reopened the same chat),
    // instead of throwing "controller not found".
    Get.lazyPut<ChatController>(
      () => ChatController(),
      tag: roomId,
      fenix: true,
    );
  }
}