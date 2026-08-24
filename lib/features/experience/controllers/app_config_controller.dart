import 'dart:async';

import 'package:get/get.dart';

import '../repositories/app_config_repository.dart';

class AppConfigController extends GetxController {
  final AppConfigRepository repository = AppConfigRepository();

  final RxBool premiumEnabled = true.obs;

  StreamSubscription<bool>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = repository.streamPremiumEnabled().listen((value) {
      premiumEnabled.value = value;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}