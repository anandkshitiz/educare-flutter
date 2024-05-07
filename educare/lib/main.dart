import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'firebase_options.dart';

final _logger = Logger();

void main() {
  runApp(
    const MaterialApp(
      home: WebViewApp(),
    ),
  );
}

class WebViewApp extends StatefulWidget {
  const WebViewApp({super.key});

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    _initializeFlutterFire();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse('https://educare.cbstech.in/login.php'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 5.0,
      ),
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }

  void _initializeFlutterFire() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      _logger.i('Permission granted: ${settings.authorizationStatus}');
      messaging.onTokenRefresh.listen((fcmToken) {
        _logger.i("FirebaseMessaging token: $fcmToken");
      }).onError((err) {
        _logger.e("unable to get the firebase device token", error: err);
      });
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await messaging.getToken();
        _logger.i("FirebaseMessaging token: $token");
        _configureFirebaseNotification();
      }
    } catch (e) {
      _logger.e("unable to initialize firebase", error: e);
    }
  }

  void _configureFirebaseNotification() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.i('Got a message whilst in the foreground!');
      if (message.notification != null) {
        _logger.i("onMessage: $message");

        navigateAsPerNotification(message.data);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.i('A new onMessageOpenedApp event was published!');
      if (message.notification != null) {
        _logger.i("onMessage: $message");
        // navigateAsPerNotification(message.data);
      }
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}

void navigateAsPerNotification(Map<String, dynamic> message) {
  var action = message['action'];
  var id = message['id'];
  //
  if (action != null && action.toString().isNotEmpty) {
    // Navigate to the create post view
    if (id != null && id.toString().isNotEmpty) {
      _logger.i("Action -> $action and id -> $id");
      if (action.toString().toLowerCase().contains("product")) {
      } else if (action.toString().toLowerCase().contains("package")) {}
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _logger.i("_firebaseMessagingBackgroundHandler called");
  await Firebase.initializeApp();
  _logger.i('Handling a background message ${message.messageId}');
  if (message.notification != null) {
    _logger.i("onMessage: $message");
    navigateAsPerNotification(message.data);
  }
}
