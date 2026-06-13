import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsService {
  NotificationsService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _localNotifications.initialize(initSettings);

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_mostrarNotificacionForeground);
      FirebaseMessaging.instance.onTokenRefresh.listen((_) {
        registrarTokenActual();
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notificaciones no inicializadas: $e');
      }
      return false;
    }
  }

  static Future<String?> obtenerTokenFcm() async {
    try {
      return FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  static Future<void> registrarTokenActual() async {
    if (kIsWeb) return;

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final token = await obtenerTokenFcm();
    if (token == null || token.isEmpty) return;

    await supabase.from('usuario_dispositivos').upsert({
      'usuario_id': userId,
      'fcm_token': token,
      'plataforma': defaultTargetPlatform.name,
      'activo': true,
      'ultimo_uso': DateTime.now().toIso8601String(),
    }, onConflict: 'usuario_id,fcm_token');
  }

  static Future<void> _mostrarNotificacionForeground(
    RemoteMessage message,
  ) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'oposiwork_general',
      'Notificaciones generales',
      channelDescription: 'Convocatorias, estudio y avisos de Oposiwork',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['route'] as String?,
    );
  }
}
