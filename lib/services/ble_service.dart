import 'package:get/get.dart';
import 'package:bfrm_app_flutter/controllers/ble_controller.dart';

class BleService extends GetxService {
  final BleController bleController = Get.put(BleController());

  Future<BleService> init() async {
    await bleController.initNotifications();
    await bleController.startBackgroundScan();
    return this;
  }

  Future<void> triggerScan() async {
    await bleController.startScan();
  }
}
