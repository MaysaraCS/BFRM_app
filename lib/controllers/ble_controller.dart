import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BleController extends GetxController {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  var scannedBeaconIds = <String>[].obs;
  var isScanning = false.obs;
  var lastNotificationTime = <String, DateTime>{};

  // New observable to show/hide notification banner on the UI
  var showNotificationBanner = false.obs;

  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
    );
  }

  void onNotificationTap(NotificationResponse response) {
    // Navigate to coupon page on notification tap
    Get.toNamed('/customer-coupons');
    showNotificationBanner.value = false;  // Hide banner when notification tapped
  }

  Future<void> showBeaconNotification(String beaconId) async {
    final now = DateTime.now();
    if (lastNotificationTime.containsKey(beaconId)) {
      final lastTime = lastNotificationTime[beaconId]!;
      if (now.difference(lastTime).inMinutes < 5) {
        return; // Do not repeat notification if less than 5 mins
      }
    }
    lastNotificationTime[beaconId] = now;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'beacon_channel',
      'Beacon Notifications',
      channelDescription: 'Notifications for nearby beacons',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'New Coupon Available!',
      'Tap to review available coupons',
      notificationDetails,
    );

    // Show notification banner on the home page UI
    showNotificationBanner.value = true;
  }

  Future<void> startScan() async {
    scannedBeaconIds.clear();
    if (!(await _requestPermissions())) return;
    isScanning.value = true;

    try {
      FlutterBluePlus.startScan();

      FlutterBluePlus.scanResults.listen((results) {
        List<String> currentIds = [];
        for (ScanResult r in results) {
          String beaconId = r.device.remoteId.toString();
          currentIds.add(beaconId);

          if (!scannedBeaconIds.contains(beaconId)) {
            scannedBeaconIds.add(beaconId);
            showBeaconNotification(beaconId);
          }
        }

        scannedBeaconIds.retainWhere((id) => currentIds.contains(id));
      });
    } catch (e) {
      print("Error scanning: $e");
    }
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> startBackgroundScan() async {
    await startScan();

    ever(isScanning, (scanning) {
      if (!scanning) {
        Future.delayed(Duration(seconds: 5), () {
          startScan();
        });
      }
    });
  }

  // Method to reset the banner visibility from UI
  void resetNotificationBanner() {
    showNotificationBanner.value = false;
  }

  @override
  void onInit() {
    super.onInit();
    initNotifications();
  }
}
