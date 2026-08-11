import "package:firebase_messaging/firebase_messaging.dart";
import "package:go_router/go_router.dart";

/// Wraps Firebase Cloud Messaging setup: requests permission, registers the
/// device token with the backend, and deep-links into the right screen when
/// a notification is tapped (see DESIGN_FLOW.md — "Notification tap" flow).
class PushService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init(GoRouter router) async {
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    if (token != null) {
      // TODO: POST /notifications/register-device with this token
    }

    FirebaseMessaging.onMessage.listen((message) {
      // TODO: show an in-app banner/snackbar for foreground notifications
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleDeepLink(router, message.data);
    });
  }

  static void _handleDeepLink(GoRouter router, Map<String, dynamic> data) {
    final type = data["type"];
    final id = data["id"];
    switch (type) {
      case "order":
        router.push("/order/$id");
      case "product":
        router.push("/product/$id");
      case "promo":
        router.push("/coupons");
      default:
        router.push("/notifications");
    }
  }
}
